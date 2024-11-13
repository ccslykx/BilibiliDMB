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

class BilibiliCore: ObservableObject {
    @Published var qrcode_url: String = ""      /// 二维码对应的链接
    @Published var qrcode_status: String = ""   /// 二维码的扫描状态
    
    private var m_qrcode_key: String = ""
    private var m_cookie: HTTPCookie! = nil
    private var m_uid: String = ""              /// 登录用户的uid
    
    /* Variables */
    private var m_roomid: String = ""           /// 直播间ID
    private var m_realRoomid: String = ""       /// B站的内部ID
    
    private var m_url: URL? = nil               /// 弹幕请求地址
    private var m_token: String = ""            /// token，由API获取
    private var m_currentHostlistIndex: Int = 0 /// 对于API返回的Host列表，当前使用Host的索引
    private var m_hostlist: [JSON] = []         /// API返回的Host列表
    private var m_socket: WebSocket? = nil      /// 用于接收弹幕的socket
    private var m_connected: Bool = false       /// 当前是否连接
    
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
            LOG("m_qrcode_key: " + qrcode_key)
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
    
    /// 执行`login`函数后，检测用户扫码登录状态
    private func getLoginStatus() {
        if (self.m_loginTimer != nil && m_loginDate != nil) {
            let interval = Date().timeIntervalSince(self.m_loginDate!)
            LOG(String(interval))
            if (interval < 2) {
                return
            }
            if (interval > 180) {
                self.m_loginTimer.invalidate()
                let warn: String = "扫码登录超时，请刷新二维码"
                LOG(warn, .WARNING)
                self.qrcode_status = warn
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
                    LOG("url: ")
                    LOG(url.absoluteString)
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                        if let queryItems = components.queryItems {
                            let m_cookie = HTTPCookie()
                            
                            for item in queryItems {
                                m_cookie.setValue(item.value, forKey: item.name)
                                if (item.name == "DedeUserID") {
                                    self.m_uid = item.value!
                                }
                            }
                        }
                    }
                }
                
                if (self.m_loginTimer != nil) {
                    self.m_loginTimer.invalidate()
                }
                break
            
            default:
                break
            }
        }
        task.resume()
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
            let result = json!["data"]["room_info"]["room_id"]
            let realRoomid: String = result.stringValue
            if (!realRoomid.isEmpty) {
                m_realRoomid = realRoomid
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
            } else {
                LOG("解析API GetInfoByRoom JSON数据错误：\(String(describing: result.error))", .ERROR)
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
        LOG("m_url: \(String(describing: m_url))")
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
        if (!m_connected) {
            return
        }
        m_socket!.disconnect()
        m_connected = false
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
        let operation = header.subdata(in: Range(NSRange(location: 8, length: 4))!)
        //let sequenceID = header.subdata(in: Range(NSRange(location: 12, length: 4))!)
        let body = data.subdata(in: Range(NSRange(location: 16, length: data.count-16))!)
        
        switch protocolVer._2BytesToInt() {
        case 0: // JSON
            if let json = try? JSON(data: body) {
                LOG("[Protocol Version 0] \(String(describing: json.rawString()))")
            } else {
                LOG("[Protocol Version 0] \(String(describing: body))")
            }
            break
            
        case 1: // 人气值
            if let json = try? JSON(data: body) {
                LOG("[Protocol Version 1] \(String(describing: json.rawString()))")
            } else {
                LOG("[Protocol Version 1] \(String(describing: body))")
            }
            break
            
        case 2: // zlib JSON
            LOG("[Protocol Version 2] [Operation]  \(operation._4BytesToInt())")
            
            guard let unarchived = try? ZlibArchive.unarchive(archive: body) else {
                LOG("Failed Unzip Data", .WARNING)
                break
            }
            unpackUnarchived(data: unarchived)
            
            
        case 3: // brotli JSON
            LOG("[Protocol Version] 3")
            let unarchived = Brotli().decompress(data)
            processMsg(JSON(unarchived))
            break
            
        default:
            LOG("[Protocol Version (\(protocolVer._2BytesToInt()))] \(data)")
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
        LOG(json.stringValue)
        
        let cmd = json["cmd"].stringValue
        switch cmd {
        case MessageType.DANMU.rawValue:
            break
            
        case MessageType.GIFT.rawValue:
            break
            
        case MessageType.COMBO.rawValue:
            break
            
        case MessageType.ENTRY.rawValue:
            break
            
        default:
            LOG(json.stringValue, .WARNING)
            break
        }
    }
    
    @objc func sendHeartbeat() {
            self.m_socket!.write(data: self.packet(2))
            LOG("Send heartbeat")
    }
}

extension BilibiliCore: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        
        switch event {
        case .connected(let header):
            LOG("Connected: \(header)")
            m_socket?.write(data: self.packet(7))
            m_heartbeatTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(sendHeartbeat), userInfo: nil, repeats: true)
            m_heartbeatTimer?.fire()
            
            self.m_connected = true
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
            LOG("PONG")
            break
            
        case .ping(_):
            LOG("PING")
            break
            
        case .error(let error):
            LOG("ERROR: \(String(describing: error))", .ERROR)
            self.disconnect()
            break
            
        case .viabilityChanged(_):
            LOG("ViabilityChanged")
            break
            
        case .reconnectSuggested(_):
            LOG("ReconnectSuggested")
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
