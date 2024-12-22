//
//  MainView.swift
//  BilibiliDMB
//
//  Created by Ccslykx on 2024/10/25.
//

import SwiftUI

struct MainView: View {
    @StateObject var bilicore: BilibiliCore = BilibiliCore()
    
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("bili_core_liveroomid") private var liveRoomID: String = "23165114"
    @AppStorage("bili_danmu_scale") private var scale: Double = 1.0
    @AppStorage("bili_danmu_fontname") private var fontname: String = ""
    @AppStorage("bili_danmu_displayTime") private var is_display_time: Bool = true
    @AppStorage("bili_danmu_displayMedal") private var is_display_medal: Bool = true
     
    var body: some View {
        #if os(iOS)
        TabView {
            DisplayView(bilicore: bilicore)
                    .tabItem {
                        Image(systemName: "list.star")
                        Text("弹幕")
                    }

            SettingView(bilicore: bilicore)
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("设置")
                    }
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        #elseif os(macOS)
            NavigationSplitView(sidebar: {
                SettingView(bilicore: bilicore)
                Spacer()
                    .navigationSplitViewColumnWidth(min: 300, ideal: 300, max: 600)
            }, detail: {
                DisplayView(bilicore: bilicore)
            })
            .background()
        #endif
    }
}

struct SettingView: View {
    @State var bilicore: BilibiliCore
    @State private var show_logout_alert: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("bili_core_liveroomid") private var liveRoomID: String = ""
    @AppStorage("bili_danmu_scale") private var scale: Double = 1.0
    @AppStorage("bili_danmu_fontname") private var fontname: String = ""
    @AppStorage("bili_danmu_displayTime") private var is_display_time: Bool = true
    @AppStorage("bili_danmu_displayMedal") private var is_display_medal: Bool = true
    
    var body: some View {
        VStack {
            #if os(macOS)
            Text("设置").font(.title)
            #endif
            
            Spacer(minLength: 60) /// TODO: Change to Logo
            
            VStack {
                Text(bilicore.qrcode_status)
                    .frame(minWidth: 80, minHeight: 30)
                    .foregroundStyle( { () -> Color in
                        if (bilicore.bili_status == .CONNECTED) {
                            return Color.green
                        } else if (bilicore.bili_status == .QRCODE_TIMEOUT) {
                            return Color.red
                        } else {
                            return Color.primary
                        }
                    }() )
                
                HStack {
                    Image(systemName: "house.circle") // 一个图标
                        .imageScale(.large)
                    TextField("直播间ID", text: $liveRoomID) // 输入直播间ID的文本框
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100, height: 34, alignment: .leading)
                        .disabled(bilicore.isConnected)
                    
                    if (bilicore.bili_status == .CONNECTED) {
                        Button("断开") {
                            bilicore.disconnect()
                        }.buttonStyle(.bordered)
                    } else {
                        Button(action: { bilicore.connect(roomid: liveRoomID) }, label: {
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
                                Text("连接")
                            }
                        })
                        .buttonStyle(.bordered)
                        .disabled(bilicore.bili_status.rawValue < BiliStatus.LOGGEDIN.rawValue)
                    }
                }
            }
            
            if (bilicore.bili_status == .NOT_LOGGEDIN) {
                Button("点我获取二维码登录") { bilicore.login() }
                    .buttonStyle(.bordered)
                    .padding(20)
            } else if (bilicore.bili_status.rawValue < BiliStatus.LOGGEDIN.rawValue ) {
                Button(action: { bilicore.login() }, label: { Image(generateQRCode(from: bilicore.qrcode_url, size: 300)!, scale: 1.0, label: Text("Login QR Code"))
                })
                .buttonStyle(.plain)
            } else {
                Button("注销登录") { show_logout_alert = true }
                    .foregroundColor(.red)
                    .buttonStyle(.bordered)
                    .padding(20)
                    .alert("警告", isPresented: $show_logout_alert) {
                        Button("确认", role: .destructive) { bilicore.logout() }
                        Button("取消", role: .cancel) {}
                    } message: {
                        Text("请确认是否要注销登录？这会删除本地保存的Cookies")
                    }
            }
                        
            Spacer()
            
            if (bilicore.bili_status != .NOT_SCANNED &&
                bilicore.bili_status != .WAIT_SACN_CONFIRM &&
                bilicore.bili_status != .QRCODE_TIMEOUT) {
                VStack {
                    HStack {
                        Text("缩放: \(scale, specifier: "%.1f")")
                            .frame(minWidth: 120, alignment: .leading)
                        Slider(value: $scale, in: 0.1...4, step: 0.1)
                    }
                    
                    Toggle(isOn: $is_display_time) {
                        Text("显示时间")
                    }
                    
                    Toggle(isOn: $is_display_medal) {
                        Text("显示粉丝牌")
                    }
                    
                    DanmuView(content: "我是一条测试弹幕", color: 0, uid: 0, uname: "用户名", mlevel: 0, mcolor: 0, mname: "粉丝牌", timestamp: Int(Date.now.timeIntervalSince1970), scale: scale, fontname: fontname, is_display_time: is_display_time, is_display_medal: is_display_medal)
                }
                .padding(.horizontal, 60)
            }

            Spacer()
        }
    }
}

struct DisplayView: View {
    @State var bilicore: BilibiliCore
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("bili_danmu_scale") private var scale: Double = 1.0
    @AppStorage("bili_danmu_fontname") private var fontname: String = ""
    @AppStorage("bili_danmu_displayTime") private var is_display_time: Bool = true
    @AppStorage("bili_danmu_displayMedal") private var is_display_medal: Bool = true
    
    @State private var isUserScrolling: Bool = false
    
    var body: some View {
        if (!bilicore.isConnected) {
            Label("先去设置界面连接到直播间吧～", systemImage: "info.bubble")
                .font(.title)
                .padding(40)
        } else {
            VStack {
                if (bilicore.roomInfo.uname != "") {
                    HStack {
                        /// 头像
                        if (!bilicore.roomInfo.face.isEmpty) {
                            AsyncImage(url: URL(string: bilicore.roomInfo.face)!) { image in
                                image
                                    .resizable(resizingMode: .stretch)
                                    .scaledToFit()
                                    .frame(width: 64.0 * scale, height: 64.0 * scale)
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
                
                ScrollViewReader { proxy in
                    List {
                        ForEach(bilicore.bilibiliMSGs.indices, id: \.self) { i in
                            if bilicore.bilibiliMSGs[i] is DanmuMSG {
                                DanmuView(danmuMSG: (bilicore.bilibiliMSGs[i] as? DanmuMSG)!, scale: scale, fontname: fontname, is_display_time: is_display_time, is_display_medal: is_display_medal).id(i)
                            } else if bilicore.bilibiliMSGs[i] is GiftMSG {
                                GiftView(giftMSG: (bilicore.bilibiliMSGs[i] as? GiftMSG)!, scale: scale, fontname: fontname, is_display_time: is_display_time, is_display_medal: is_display_medal).id(i)
                            }
                        }
                    }
                    .padding(2)
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    .scrollContentBackground(.hidden)
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
            .padding(10)
            .navigationTitle(bilicore.isConnected && !bilicore.roomInfo.uname.isEmpty ? "欢迎光临 \(bilicore.roomInfo.uname) 的直播间" : "") /// TODO: use uname
            .toolbarTitleDisplayMode(.inline)
            
        }
    }
}

#Preview {
    MainView()
}
