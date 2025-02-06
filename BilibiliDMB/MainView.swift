//
//  MainView.swift
//  BilibiliDMB
//
//  Created by Ccslykx on 2024/10/25.
//

import SwiftUI

struct MainView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("agreed") private var agreed: Bool = false
    
    var body: some View {
        if (!agreed) {
            AgreementView()
        } else {
#if os(iOS)
            TabView {
                DisplayView()
                    .tabItem {
                        Image(systemName: "list.star")
                        Text("弹幕板")
                    }
                
                SettingView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("设置")
                    }
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
#elseif os(macOS)
            NavigationSplitView(sidebar: {
                SettingView()
                Spacer()
                    .navigationSplitViewColumnWidth(min: 300, ideal: 300, max: 600)
            }, detail: {
                DisplayView()
            })
            .background()
#endif
        }
    }
}

struct SettingView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("bili_danmu_scale") private var scale: Double = 1.0
    @AppStorage("bili_danmu_fontname") private var fontname: String = ""
    @AppStorage("bili_danmu_displayTime") private var is_display_time: Bool = true
    @AppStorage("bili_danmu_displayMedal") private var is_display_medal: Bool = true
    
    @AppStorage("agreed") private var agreed: Bool = false
    
    var body: some View {
        VStack {
            #if os(macOS)
            Text("设置").font(.title)
            #endif
            
            HStack {
                Image(.logo)
                    .resizable()
                    .frame(maxWidth: 96, maxHeight: 96)
                
                Text("B站弹幕板")
                    .font(.custom("", size: 48))
                    .bold()
                    .frame(maxHeight: 128)
                    .padding(.leading, 32)
            }
            .padding(10)
            
            List {
                HStack {
                    Text("缩放: \(scale, specifier: "%.1f")")
                        .frame(minWidth: 120, alignment: .leading)
                    Slider(value: $scale, in: 0.5...2, step: 0.1)
                }
                
                Toggle(isOn: $is_display_time) {
                    Text("显示时间")
                }
                
                Toggle(isOn: $is_display_medal) {
                    Text("显示粉丝牌")
                }
                Button("重新确认用户须知", role: .destructive) {
                    agreed = false
                }
            }
            .padding(.horizontal, 60)
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            
            DanmuView(content: "我是一条测试弹幕", color: 0, uid: 0, uname: "用户名", mlevel: 0, mcolor: 0, mname: "粉丝牌", timestamp: Int(Date.now.timeIntervalSince1970), scale: scale, fontname: fontname, is_display_time: is_display_time, is_display_medal: is_display_medal)
            
            Spacer()
        }
    }
}

struct DisplayView: View {
    @StateObject private var screenAwakeManager = ScreenAwakeManager()
    @StateObject private var bilicore: BilibiliCore = BilibiliCore()
    
    @State private var show_logout_alert: Bool = false
    @State private var isUserScrolling: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    @AppStorage("bili_core_liveroomid") private var liveRoomID: String = ""
    
    @AppStorage("bili_danmu_scale") private var scale: Double = 1.0
    @AppStorage("bili_danmu_fontname") private var fontname: String = ""
    @AppStorage("bili_danmu_displayTime") private var is_display_time: Bool = true
    @AppStorage("bili_danmu_displayMedal") private var is_display_medal: Bool = true
    
    private let edgePadding = 16.0
    private let qrcodeSize = 300.0
    
    var body: some View {
        VStack {
            HStack {
                if (bilicore.bili_status == .CONNECTED && bilicore.roomInfo.uname != "") {
                    HStack {
                        /// 头像
                        if (!bilicore.roomInfo.face.isEmpty) {
                            AsyncImage(url: URL(string: bilicore.roomInfo.face)!) { image in
                                image
                                    .resizable(resizingMode: .stretch)
                                    .frame(width: 64.0, height: 64.0)
                                    .scaledToFit()
                                    .padding(.leading, edgePadding)
                            } placeholder: {
                                Color.clear
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            HStack {
                                /// 主播用户名
                                Text(bilicore.roomInfo.uname)
                                    .font(.title2)
                                /// 一级分区/二级分区
                                Text("\(bilicore.roomInfo.parent_area_name)/\(bilicore.roomInfo.area_name)")
                                    .foregroundStyle(.gray)
                                    .font(.title2)
                            }
                            /// 直播间标题
                            Text(bilicore.roomInfo.title)
                                .font(.title)
                        }
                        
                        Spacer()
                        
                        //                        Text("在线人数：\(bilicore.roomInfo.online)")
                    }
                }
                
                if (BiliStatus.LOGGEDIN.rawValue <= bilicore.bili_status.rawValue &&
                    bilicore.bili_status.rawValue < BiliStatus.CONNECTED.rawValue) {
                    Image(systemName: "house.circle") // 一个图标
                        .imageScale(.large)
                    TextField("直播间ID", text: $liveRoomID) // 输入直播间ID的文本框
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100, height: 34, alignment: .leading)
                        .disabled(bilicore.isConnected)
                    Button(action: { bilicore.connect(roomid: liveRoomID) }, label: {
                        /// 状态：正在连接
                        if (bilicore.bili_status == .CONNECTING) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(.trailing, 4)
                                .frame(maxWidth: 10, maxHeight: 10)
#if os(macOS)
                                .scaleEffect(0.4)
#endif
                            Text("连接中")
                        } else {
                            /// 状态：未连接
                            Text("连接")
                        }
                    })
                    .buttonStyle(.bordered)
                    .disabled(bilicore.bili_status.rawValue < BiliStatus.LOGGEDIN.rawValue)
                }
                /// 断开连接按钮
                if (bilicore.bili_status == .CONNECTED) {
                    Button("断开") {
                        bilicore.disconnect()
                    }
                    .buttonStyle(.bordered)
                    .padding(.trailing, edgePadding)
                    .foregroundStyle(.red)
                }
                
                /// 注销登录按钮
                if (bilicore.bili_status == .LOGGEDIN || bilicore.bili_status == .DISCONNECTED) {
                    Button("注销登录") { show_logout_alert = true }
                        .foregroundColor(.red)
                        .buttonStyle(.bordered)
                        .alert("警告", isPresented: $show_logout_alert) {
                            Button("确认", role: .destructive) { bilicore.logout() }
                            Button("取消", role: .cancel) {}
                        } message: {
                            Text("请确认是否要注销登录？这会删除本地保存的Cookies")
                        }
                }
            }
            .onAppear() {
                /// 在未登录的状态下，尝试登录
                if (bilicore.bili_status == .NOT_LOGGEDIN) {
                    bilicore.login()
                }
            }
            
            /// 登录二维码
            if (bilicore.bili_status.rawValue < BiliStatus.LOGGEDIN.rawValue) {
                Text("提示：因B站限制，匿名状态无法正常获取弹幕，请使用B站客户端扫码登录")
                    .frame(minWidth: 80, maxWidth: qrcodeSize, minHeight: 30)

                Button(action: { bilicore.login() }, label: {
                    if (!bilicore.qrcode_url.isEmpty) {
                        Image(generateQRCode(from: bilicore.qrcode_url, size: qrcodeSize)!, scale: 1.0, label: Text("Login QR Code"))
                    }
                })
                .frame(width: qrcodeSize, height: qrcodeSize)
                .buttonStyle(.plain)
                .onAppear() {
                    bilicore.login()
                }
                
                Text("状态：\(bilicore.qrcode_status.isEmpty ? "..." : bilicore.qrcode_status)")
                    .frame(minWidth: 80, maxWidth: qrcodeSize, minHeight: 30)
                    .foregroundStyle( { () -> Color in
                        if (bilicore.bili_status == .CONNECTED) {
                            return Color.green
                        } else if (bilicore.bili_status == .QRCODE_TIMEOUT) {
                            return Color.red
                        } else {
                            return Color.primary
                        }
                    }() )
            }
            
            /// 弹幕区
            if (bilicore.bili_status == .CONNECTED) {
                VStack {
                    ScrollViewReader { proxy in
                        List {
                            ForEach(bilicore.bilibiliMSGs.indices, id: \.self) { i in
                                if bilicore.bilibiliMSGs[i] is DanmuMSG {
                                    DanmuView(danmuMSG: (bilicore.bilibiliMSGs[i] as? DanmuMSG)!, scale: scale, fontname: fontname, is_display_time: is_display_time, is_display_medal: is_display_medal).id(i)
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                } else if bilicore.bilibiliMSGs[i] is GiftMSG {
                                    GiftView(giftMSG: (bilicore.bilibiliMSGs[i] as? GiftMSG)!, scale: scale, fontname: fontname, is_display_time: is_display_time, is_display_medal: is_display_medal).id(i)
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                        .gesture(
                            DragGesture()
                                .onChanged { _ in isUserScrolling = true } /// IDK why onEnded not work
                        )
                        .gesture(
                            TapGesture(count: 2)
                                .onEnded {
                                    _ in isUserScrolling = false
                                    withAnimation(.easeInOut) {
                                        proxy.scrollTo(bilicore.bilibiliMSGs.indices.last)
                                    }
                                }
                        )
                        .onChange(of: bilicore.bilibiliMSGs, {
                            if (!isUserScrolling) {
                                withAnimation(.easeInOut) {
                                    proxy.scrollTo(bilicore.bilibiliMSGs.indices.last)
                                }
                            }
                        })
                    }
                    
                    Spacer()
                    
                    if (!bilicore.entryMSGs.isEmpty) {
                        EntryView(entryMSG: bilicore.entryMSGs.last ?? EntryMSG(uid: 0, uname: "", mlevel: 0, mcolor: colorScheme == .dark ? 16777215 : 0, mname: "", timestamp: 0), scale: scale, fontname: fontname, is_display_time: is_display_time, is_display_medal: is_display_medal)
                    }
                }
                .onAppear() {
                    screenAwakeManager.keepScreenAwake(bilicore.isConnected)
                }
                .onDisappear() {
                    screenAwakeManager.keepScreenAwake(false)
                }
            }
        }
    }
}

#Preview {
    SettingView()
}
