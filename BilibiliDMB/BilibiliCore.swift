//
//  BilibiliCore.swift
//  BilibiliDMB
//
//  Created by Ccslykx on 2024/10/20.
//

import Foundation
import Starscream
import SwiftyJSON
import SWCompression
import SwiftBrotli
import CryptoKit
import Security

enum BiliStatus: Int {
    case NOT_LOGGEDIN = 0
    case NOT_SCANNED = 1
    case WAIT_SACN_CONFIRM = 2
    case QRCODE_TIMEOUT = 3
    case LOGGEDIN = 4
    case DISCONNECTED = 5
    case CONNECTING = 6
    case CONNECTED = 7
}

class BilibiliCore: ObservableObject {
    @Published var bili_status: BiliStatus = .NOT_LOGGEDIN
    @Published var qrcode_url: String = ""      /// 二维码对应的链接
    @Published var qrcode_status: String = ""   /// 二维码的扫描状态
    @Published var isConnected: Bool = false       /// 当前是否连接
    
    @Published var bilibiliMSGs: [BilibiliMSG] = []
    @Published var entryMSGs: [EntryMSG] = []
    
    @Published var roomInfo: RoomInfo = RoomInfo()
    
    private var m_qrcode_key: String = ""
    private var m_cookie: HTTPCookie! = nil
    private var m_uid: String = "0"              /// 登录用户的uid
    private let m_identifier = "com.ccslykx.BilibiliDMB"
    
    /* Variables */
    private var m_roomid: String = ""           /// 直播间ID
    private var m_realRoomid: String = ""       /// B站的内部ID
    
    private var m_url: URL? = nil               /// 弹幕请求地址
    private var m_token: String = ""            /// token，由API获取
    private var m_currentHostlistIndex: Int = 0 /// 对于API返回的Host列表，当前使用Host的索引
    private var m_hostlist: [JSON] = []         /// API返回的Host列表
    private var m_socket: WebSocket? = nil      /// 用于接收弹幕的socket
    
    private var m_apiGetInfoByRoom = ""         /// 用于获取`m_realRoomid`
    private var m_apiGetDanmuInfo = ""          /// 用于获取`m_token`
    
    private var m_heartbeatTimer: Timer! = nil          /// HeartBeat Timer
    private var m_initRoomInfoTimer: Timer! = nil       /// wait initRoomInfo()
    private var m_loginTimer: Timer! = nil              /// wait scan QR code and login
    
    private var m_loginDate: Date? = nil                /// 用于计算登录二维码是否超时
    
    private enum MessageType: String {
        case DANMU = "DANMU_MSG"
        case GIFT = "SEND_GIFT"
        case COMBO = "COMBO_SEND"
        case ENTRY = "INTERACT_WORD"
        /// TODO: ...
    }
    
    /* Functions */
    func login() {
        /// 先检测是否有保存Cookies
        let key = SymmetricKey(data: SHA256.hash(data: m_identifier.data(using: .utf8)!).withUnsafeBytes { ptr in Data(ptr)} )
        if (loadCookieFromFile(key: key)) {
            qrcode_status = "登录成功"
            bili_status = .LOGGEDIN
            /// TODO: 检测Cookie是否过期
            return
        }
        
        let task = URLSession.shared.dataTask(with: URL(string: "https://passport.bilibili.com/x/passport-login/web/qrcode/generate")!) { data, response, error in
            if (error != nil || data == nil) {
                LOG("申请二维发生错误：\(String(describing: error))")
                return
            }
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                LOG("申请二维码时，服务器响应错误：\(String(describing: response))", .ERROR)
                return
            }
            
            let json = try? JSON(data: data!)
            let url = json!["data"]["url"].stringValue
            let qrcode_key = json!["data"]["qrcode_key"].stringValue
            self.qrcode_url = url
            self.m_qrcode_key = qrcode_key
            self.bili_status = .NOT_SCANNED
        }
        task.resume()

        if (self.m_loginTimer == nil) {
            self.m_loginTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) {_ in
                self.getLoginStatus()
            }
            self.m_loginTimer.tolerance = 0.1
        }
        self.m_loginDate = Date()
        self.m_loginTimer.fire()
    }
    
    func logout() {
        qrcode_url = ""
        qrcode_status = ""
        isConnected = false
        
        m_qrcode_key = ""
        m_cookie = nil
        m_uid = "0"
        m_token = ""
        
        if (m_heartbeatTimer != nil) {
            m_heartbeatTimer!.invalidate()
            m_heartbeatTimer = nil
        }
        if (m_initRoomInfoTimer != nil) {
            m_initRoomInfoTimer!.invalidate()
            m_initRoomInfoTimer = nil
        }
        if (m_loginTimer != nil) {
            m_loginTimer!.invalidate()
            m_loginTimer = nil
        }

        m_loginDate = nil
        
        self.bili_status = .NOT_LOGGEDIN
        
        deleteCookieFile()
    }
    
    /// 执行`login`函数后，检测用户扫码登录状态
    private func getLoginStatus() {
        if (self.m_loginTimer != nil && m_loginDate != nil) {
            let interval = Date().timeIntervalSince(self.m_loginDate!)

            if (interval < 2) {
                return
            }
            if (interval > 180) {
                self.m_loginTimer.invalidate()
                let warn: String = "扫码登录超时，请刷新二维码"
                LOG(warn, .WARNING)
                self.qrcode_status = warn
                self.bili_status = .QRCODE_TIMEOUT
                return
            }
        }
        
        var urlComponents = URLComponents(url: URL(string: "https://passport.bilibili.com/x/passport-login/web/qrcode/poll")!, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [
            URLQueryItem(name: "qrcode_key", value: self.m_qrcode_key)
        ]
        guard let urlWithParams = urlComponents?.url else {
            LOG("参数初始化错误 in processLogin()", .ERROR)
            return
        }
        
        let task = URLSession.shared.dataTask(with: urlWithParams) { data, response, error in
            if (error != nil || data == nil) {
                LOG("检测扫码登录状态发生错误：\(String(describing: error))")
                return
            }
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                LOG("检测扫码登录状态时，服务器响应错误：\(String(describing: response))", .ERROR)
                return
            }
            
            let json = try? JSON(data: data!)
            
            let data = json?["data"]
            let code = data?["code"]
            let message = data?["message"]
            if (message != nil) {
                self.qrcode_status = message?.stringValue ?? ""
            }

            switch code?.intValue {
            /*
             /// 0     登录成功
             /// 86038 二维码已失效
             /// 86090 已扫码未确认
             /// 86101 未扫码
             */
            case 0: /// 登录成功
//                let refresh_token: String = (data?["refresh_token"])!.stringValue
                
                if let url: URL = URL(string: (data?["url"])!.stringValue) {
                    self.saveCookie(url: url)
                }
                
                if (self.m_loginTimer != nil) {
                    self.m_loginTimer.invalidate()
                }
                self.qrcode_status = "登录成功"
                self.bili_status = .LOGGEDIN
                break
                
            case 86038:
                self.bili_status = .QRCODE_TIMEOUT
                break
                
            case 86090:
                self.bili_status = .WAIT_SACN_CONFIRM
                break
                
            case 86101:
                self.bili_status = .NOT_SCANNED
                break
            
            default:
                break
            }
        }
        task.resume()
    }
    
    private func saveCookie(url: URL) {
        var cookies = [String : String]()
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if let queryItems = components.queryItems {
                let cookie = HTTPCookie()
                for item in queryItems {
                    cookies[item.name] = item.value
                    cookie.setValue(item.value, forKey: item.name)
                    if (item.name == "DedeUserID") {
                        self.m_uid = item.value ?? "0"
                    }
                }
                self.m_cookie = cookie
            }
        }
        
        if (!saveCookieToFile(cookies)) {
            LOG("Failed save cookies to file", .WARNING)
        }
    }
    
    private func saveCookieToFile(_ cookies: [String : String]) -> Bool {
        if (cookies.isEmpty) {
            LOG("Not cookie found, please login first!", .WARNING)
            return false
        }
        
        let key = SymmetricKey(data: SHA256.hash(data: m_identifier.data(using: .utf8)!).withUnsafeBytes { ptr in Data(ptr)} )
        
        /// Init file path
        let appDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("BilibiliDMB")
        let cookiesFilePath = appDir.appendingPathComponent("BilibiliDMB.Core")
        do {
            try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            LOG("Failed to create directory: \(error.localizedDescription)")
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: cookies)
            let sealedBox = try AES.GCM.seal(jsonData, using: key)
            try sealedBox.combined?.write(to: cookiesFilePath)
            LOG("Cookies saved to file at \(cookiesFilePath)")
            return true
        } catch {
            LOG("Failed to save cookies: \(error.localizedDescription)")
            return false
        }
    }
    
    private func loadCookieFromFile(key: SymmetricKey) -> Bool {
        let appDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let cookiesFilePath = appDir.appendingPathComponent("BilibiliDMB/BilibiliDMB.Core")
        do {
            /// Read the encrypted data from file
            let encryptedData = try Data(contentsOf: cookiesFilePath)
            
            /// Decrypt the data
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            
            /// Convert decrypted data back to JSON
            guard let json = try JSONSerialization.jsonObject(with: decryptedData) as? [String : String] else {
                LOG("Failed to convert cookies from file to JSON", .ERROR)
                return false
            }
            
            let cookie = HTTPCookie()
            for key in json.keys {
                cookie.setValue(json[key], forKey: key)
                if (key == "DedeUserID") {
                    m_uid = json[key] ?? "0"
                }
            }
            m_cookie = cookie
            if (m_uid == "0") {
                LOG("Warning: Can not find uid in cookies", .WARNING)
            }
            LOG("Loaded cookies from file")

            return true
        } catch {
            LOG("Failed to load cookies: \(error.localizedDescription)")
            return false
        }
    }
    
    private func deleteCookieFile() {
        let appDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let cookiesFilePath = appDir.appendingPathComponent("BilibiliDMB/BilibiliDMB.Core")
        do {
            if (FileManager.default.fileExists(atPath: cookiesFilePath.path)) {
                try (FileManager.default.removeItem(at: cookiesFilePath))
                LOG("删除Cookies成功")
            } else {
                LOG("Cookies文件: \(cookiesFilePath.absoluteString) 不存在", .WARNING)
            }
        } catch {
            LOG("删除Cookies失败：\(error.localizedDescription)")
        }
    }
    
    private func initRoomInfo() {
        if (m_roomid.isEmpty) {
            LOG("房间号为空", .ERROR)
            return;
        }
        
        /// Get real room id
        let session = URLSession.shared
        
        m_apiGetInfoByRoom = "https://api.live.bilibili.com/xlive/web-room/v1/index/getInfoByRoom?room_id=" + m_roomid
        
        let task1 = session.dataTask(with: URL(string: m_apiGetInfoByRoom)!) { [self] data, response, error in
                    
            if (error != nil || data == nil) {
                LOG("调用API GetInfoByRoom 时发生错误：\( String(describing: error))", .ERROR)
                return
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                LOG("服务器响应错误：\(String(describing: response))", .ERROR)
                return
            }
            
            let json = try? JSON(data: data!)
            
            /// assign `roomInfo`
            let room_info = json!["data"]["room_info"]
            let anchor_info = json!["data"]["anchor_info"]
            roomInfo.uid = room_info["uid"].stringValue
            roomInfo.room_id = room_info["room_id"].stringValue
            roomInfo.title = room_info["title"].stringValue
            roomInfo.area_name = room_info["area_name"].stringValue
            roomInfo.parent_area_name = room_info["parent_area_name"].stringValue
            roomInfo.live_start_time = room_info["live_start_time"].uIntValue
            roomInfo.online = room_info["online"].uIntValue
            roomInfo.cover = room_info["cover"].stringValue
            
            roomInfo.uname = anchor_info["base_info"]["uname"].stringValue
            roomInfo.face = anchor_info["base_info"]["face"].stringValue
            
            /// Get `room_id` and GetDanmuInfo
            
            if (!roomInfo.room_id.isEmpty) {
                m_realRoomid = roomInfo.room_id
                m_apiGetDanmuInfo = "https://api.live.bilibili.com/xlive/web-room/v1/index/getDanmuInfo?id=" + m_realRoomid
                
                let task2 = session.dataTask(with: URL(string: m_apiGetDanmuInfo)!) { [self] data, response, error in
                            
                    if (error != nil || data == nil) {
                        LOG("调用API GetDanmuInfo 时发生错误：\( String(describing: error))", .ERROR)
                        return
                    }
                    
                    guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                        LOG("服务器响应错误：\(String(describing: response))", .ERROR)
                        return
                    }
                    
                    let json = try? JSON(data: data!)
                    let result = json!["data"]["token"]
                    let token: String = result.stringValue
                    if (!token.isEmpty) {
                        m_token = token
                    } else {
                        LOG("解析API GetDanmuInfo JSON数据错误：\(String(describing: result.error))", .ERROR)
                    }
                    
                    if let host_list = json!["data"]["host_list"].array {
                        if (!host_list.isEmpty) {
                            m_hostlist = host_list
                        } else {
                            LOG("解析API GetDanmuInfo 时， host_list 为空：\(String(describing: host_list))", .ERROR)
                        }
                    }
                    
                }
                task2.resume()
            }
        }
        task1.resume()
    }
    
    private func getWebSocketUrlFromHostlist(index: Int) -> URL? {
        if (index < 0 || m_hostlist.count - 1 < index) {
            LOG("Index error at getWebSocketUrlFromHostlist(\(index))", .ERROR)
            return nil
        }
        let host = m_hostlist[index]
        let url: URL = URL(string: "wss://\(host["host"]):\(host["wss_port"])/sub")!
        
        return url
    }
    
    private func _connect() -> Bool {
        while (m_url == nil)
        {
            if (m_currentHostlistIndex > m_hostlist.count - 1) {
                LOG("所有Host连接失败，直播间ID：\(m_roomid)", .WARNING)
                return false
            }
            m_url = getWebSocketUrlFromHostlist(index: m_currentHostlistIndex)
            if (m_url != nil) {
                break
            }
            m_currentHostlistIndex += 1
        }
//        LOG("m_url: \(String(describing: m_url))")
        var request = URLRequest(url: m_url ?? URL(string: "wss://broadcastlv.chat.bilibili.com:443/sub")!)
        if let m_cookie = m_cookie {
            let cookieHeader = "\(m_cookie.name)=\(m_cookie.value)"
            request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }
        m_socket = WebSocket(request: request)
        m_socket?.delegate = self
        m_socket?.connect()
        /// TODO: 检测是否连接成功
        return true
    }
    
    func connect(roomid: String) {
        self.bili_status = .CONNECTING
        self.bilibiliMSGs.removeAll()
        self.entryMSGs.removeAll()
        
        m_roomid = roomid
        LOG("初始化房间信息...")
        initRoomInfo()
        m_currentHostlistIndex = 0
        
        var initialized: Bool = false
        var repeatCount: Int = 0
        let repeatInterval: Double = 1.0
        m_initRoomInfoTimer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: true) {_ in
            repeatCount += 1
            if ((Double(repeatCount) * repeatInterval) > 30.0) {
                LOG("连接超时，请检查网络", .ERROR)
                self.m_initRoomInfoTimer?.invalidate()
                return
            }
            
            if (initialized) {
                /// Check `m_hostlist.count`
                if (self.m_hostlist.count == 0) {
                    LOG("m_hostlist 为空，请检查 initRoomInfo() 是否成功", .ERROR)
                    self.m_initRoomInfoTimer?.invalidate()
                    return
                }
                if (!self._connect()) {
                    LOG("连接失败，请检查网络配置", .ERROR)
                    self.m_initRoomInfoTimer?.invalidate()
                    return
                }
                return
            }
            if (!self.m_hostlist.isEmpty && !self.m_token.isEmpty && !self.m_realRoomid.isEmpty)
            {
                initialized = true
                LOG("初始化完成")
            }
        }
        m_initRoomInfoTimer!.fire()
    }
    
    func disconnect() {
        if (!isConnected) {
            return
        }
        m_socket!.disconnect()
        isConnected = false
        self.bili_status = .DISCONNECTED
        if (m_heartbeatTimer != nil)
        {
            m_heartbeatTimer?.invalidate()
        }
        /// TODO: Add systemMSG
    }
    
    private func packet(_ type: Int) -> Data {
        /// 该函数修改自https://github.com/komeiji-koishi-ww/bilibili_danmakuhime_swiftUI/
        
        ///数据包
        var bodyDatas = Data()
        
        switch type {
        case 7: ///认证包
            let str = "{\"uid\": \(m_uid),\"roomid\": \(self.m_realRoomid),\"protover\": 2,\"platform\": \"web\",\"type\": 2,\"clientver\": \"1.14.3\",\"key\": \"\(self.m_token)\"}"
            bodyDatas = str.data(using: String.Encoding.utf8)!
            
        default: ///心跳包
            bodyDatas = "{}".data(using: String.Encoding.utf8)!
        }
        
        ///header总长度,  body长度+header长度
        var len: UInt32 = CFSwapInt32HostToBig(UInt32(bodyDatas.count + 16))
        let lengthData = Data(bytes: &len, count: 4)
        
        ///header长度, 固定16
        var headerLen: UInt16 = CFSwapInt16HostToBig(UInt16(16))
        let headerLenghData = Data(bytes: &headerLen, count: 2)
        
        ///协议版本
        var versionLen: UInt16 = CFSwapInt16HostToBig(UInt16(1))
        let versionLenData = Data(bytes: &versionLen, count: 2)
        
        ///操作码
        var optionCode: UInt32 = CFSwapInt32HostToBig(UInt32(type))
        let optionCodeData = Data(bytes: &optionCode, count: 4)
        
        ///数据包头部长度（固定为 1）
        var bodyHeaderLength: UInt32 = CFSwapInt32HostToBig(UInt32(1))
        let bodyHeaderLengthData = Data(bytes: &bodyHeaderLength, count: 4)
        
        ///按顺序添加到数据包中
        var packData = Data()
        packData.append(lengthData)
        packData.append(headerLenghData)
        packData.append(versionLenData)
        packData.append(optionCodeData)
        packData.append(bodyHeaderLengthData)
        packData.append(bodyDatas)
        
        return packData
    }
    
    private func unpack(data: Data) {
        let header = data.subdata(in: Range(NSRange(location: 0, length: 16))!)
        //let packetLen = header.subdata(in: Range(NSRange(location: 0, length: 4))!)
        //let headerLen = header.subdata(in: Range(NSRange(location: 4, length: 2))!)
        let protocolVer = header.subdata(in: Range(NSRange(location: 6, length: 2))!)
        //let operation = header.subdata(in: Range(NSRange(location: 8, length: 4))!)
        //let sequenceID = header.subdata(in: Range(NSRange(location: 12, length: 4))!)
        let body = data.subdata(in: Range(NSRange(location: 16, length: data.count-16))!)
        
        switch protocolVer._2BytesToInt() {
        case 0: // JSON
//            if let json = try? JSON(data: body) {
//                LOG("[Protocol Version 0] \(String(describing: json.rawString()))")
//            } else {
//                LOG("[Protocol Version 0] \(String(describing: body))")
//            }
            break
            
        case 1: // 人气值
//            if let json = try? JSON(data: body) {
//                LOG("[Protocol Version 1] \(String(describing: json.rawString()))")
//            } else {
//                LOG("[Protocol Version 1] \(String(describing: body))")
//            }
            break
            
        case 2: // zlib JSON
//            LOG("[Protocol Version 2] [Operation]  \(operation._4BytesToInt())")
            
            guard let unarchived = try? ZlibArchive.unarchive(archive: body) else {
                LOG("Failed Unzip Data", .WARNING)
                break
            }
            unpackUnarchived(data: unarchived)
            
            
        case 3: // brotli JSON
//            LOG("[Protocol Version] 3")
            let unarchived = Brotli().decompress(data)
            processMsg(JSON(unarchived))
            break
            
        default:
//            LOG("[Protocol Version (\(protocolVer._2BytesToInt()))] \(data)")
            break
        }
        
    }
    
    private func unpackUnarchived(data: Data) {
        let bodyLen = data.subdata(in: Range(NSRange(location: 0, length: 4))!)._4BytesToInt()
        
        if bodyLen > 16 {
            let currentMsg = data.subdata(in: Range(NSRange(location: 16, length: bodyLen - 16))!)
            processMsg(JSON(currentMsg))
            if data.count > bodyLen {
                let res = data.subdata(in: Range(NSRange(location: bodyLen, length: data.count - bodyLen))!)
                unpackUnarchived(data: res)
            }
        }
    }
    
    private func processMsg(_ json: JSON) {
//        LOG("PROCESS_MSG " + json.debugDescription)
        
        let cmd = json["cmd"].stringValue
        switch cmd {
        case MessageType.DANMU.rawValue:
            let info = json["info"]
            let medal_info = info.arrayValue[3].arrayValue
            let ml = medal_info.isEmpty ? 0 : medal_info[0].intValue
            let mc = medal_info.isEmpty ? 16777215 : medal_info[4].uInt32Value
            let mn = medal_info.isEmpty ? "" : medal_info[1].stringValue
            let danmuMSG = DanmuMSG(content: info.arrayValue[1].stringValue,
                                    color: info.arrayValue[0].arrayValue[3].uInt32Value,
                                    uid: info.arrayValue[2].arrayValue[0].intValue,
                                    uname: info.arrayValue[2].arrayValue[1].stringValue,
                                    mlevel: ml,
                                    mcolor: mc,
                                    mname: mn,
                                    timestamp: info.arrayValue[9]["ts"].intValue)
            bilibiliMSGs.append(danmuMSG)
            LOG(danmuMSG)
            break
            
        case MessageType.GIFT.rawValue:
            let data = json["data"]
            let giftMSG = GiftMSG(giftname: data["giftName"].stringValue,
                                  giftnum: data["num"].intValue,
                                  giftprice: data["price"].intValue,
                                  uid: data["uid"].intValue,
                                  uname: data["uname"].stringValue,
                                  mlevel: data["medal_info"]["medal_level"].intValue,
                                  mcolor: data["medal_info"]["medal_color"].uInt32Value,
                                  mname: data["medal_info"]["medal_name"].stringValue,
                                  timestamp: data["timestamp"].intValue)
            bilibiliMSGs.append(giftMSG)
            LOG(giftMSG)
            break
            
        case MessageType.COMBO.rawValue:
//            LOG("COMBO")
            break
            
        case MessageType.ENTRY.rawValue:
            let data = json["data"]
            let entryMSG = EntryMSG(uid: data["uid"].intValue,
                                    uname: data["uname"].stringValue,
                                    mlevel: data["fans_medal"]["medal_level"].intValue,
                                    mcolor: data["fans_medal"]["medal_color"].uInt32Value,
                                    mname: data["fans_medal"]["medal_name"].stringValue,
                                    timestamp: data["timestamp"].intValue)
            entryMSGs.append(entryMSG)
            LOG(entryMSG)
            break
            
        default:
//            LOG("UNKNOWN CMD: " + json.debugDescription, .WARNING)
            break
        }
    }
    
    @objc func sendHeartbeat() {
            self.m_socket!.write(data: self.packet(2))
//            LOG("Send heartbeat")
    }
}

extension BilibiliCore: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        
        switch event {
        case .connected:
//            LOG("Connected: \(header)")
            m_socket?.write(data: self.packet(7))
            m_heartbeatTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(sendHeartbeat), userInfo: nil, repeats: true)
            m_heartbeatTimer?.fire()
            
            self.isConnected = true
            self.bili_status = .CONNECTED
            LOG("连接成功")
            if (m_initRoomInfoTimer != nil) {
                self.m_initRoomInfoTimer?.invalidate()
            }
            break
            
        case .disconnected(let reason, let code):
            LOG("Disconnected: \(reason) with code: \(code)")
            self.disconnect()
            break
            
        case .text(let text):
            LOG("收到文本信息：\(text)")
            break
            
        case .binary(let data):
            unpack(data: data)
            break
            
        case .pong(_):
//            LOG("PONG")
            break
            
        case .ping(_):
//            LOG("PING")
            break
            
        case .error(let error):
            LOG("ERROR: \(String(describing: error))", .ERROR)
            self.disconnect()
            break
            
        case .viabilityChanged(_):
//            LOG("ViabilityChanged")
            break
            
        case .reconnectSuggested(_):
            LOG("ReconnectSuggested")
            self.connect(roomid: self.m_roomid)
            break
            
        case .cancelled:
            LOG("Cancelled")
            self.disconnect()
            break
            
        case .peerClosed:
            LOG("PeerClosed")
            self.disconnect()
            break
        }
    }
}
