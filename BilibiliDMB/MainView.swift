//
//  MainView.swift
//  BilibiliDMB
//
//  Created by Ccslykx on 2024/10/25.
//

import SwiftUI

struct MainView: View {
    @State var liveRoomID: String = "23165114"//"23165114"
    @StateObject var bilicore = BilibiliCore()
    @Environment(\.colorScheme) var colorScheme
    
    #if os(iOS)
    @State private var selectedTab = 0
    #endif
     
    var body: some View {
        #if os(iOS)
        TabView(selection: $selectedTab) {
                SettingView(liveRoomID: liveRoomID, bilicore: bilicore)
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("设置")
                    }
                    .tag(0)
                DisplayView(bilicore: bilicore)
                    .tabItem {
                        Image(systemName: "list.star")
                        Text("弹幕")
                    }
                    .tag(1)
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        #elseif os(macOS)
            NavigationSplitView(sidebar: {
                SettingView(liveRoomID: liveRoomID, bilicore: bilicore)
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
    @State var liveRoomID: String = "23165114"//"23165114"
    @StateObject var bilicore: BilibiliCore
    
    var body: some View {
        VStack {
            #if os(macOS)
            Text("设置").font(.title)
            #endif
            
            HStack {
                Image(systemName: "house.circle") // 一个图标
                    .imageScale(.large)
                TextField("直播间ID", text: $liveRoomID) // 输入直播间ID的文本框
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100, height: 34, alignment: .leading)
                
                if (bilicore.isConnected) {
                    Button("断开") {
                        bilicore.disconnect()
                    }.buttonStyle(.bordered)
                } else {
                    Button("连接") {
                        bilicore.connect(roomid: liveRoomID)
                    }
                    .buttonStyle(.bordered)
                    .disabled(bilicore.qrcode_status != "登录成功")
                }
            }
            
            Button(action: {
                bilicore.login()
            }, label: {
                if (self.bilicore.qrcode_url.isEmpty) {
                    Text("点我获取二维码登录")
                } else if (bilicore.qrcode_status != "登录成功"){
                    Image(generateQRCode(from: self.bilicore.qrcode_url, size: 300)!, scale: 1.0, label: Text("Login QR Code"))
                }
            })
            
            Text(bilicore.qrcode_status)
            
            Spacer()
        }
    }
}

struct DisplayView: View {
    @StateObject var bilicore: BilibiliCore
    @Environment(\.colorScheme) var colorScheme
    @State private var isUserScrolling: Bool = false
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                List {
                    ForEach(bilicore.bilibiliMSGs.indices, id: \.self) { i in
                        if bilicore.bilibiliMSGs[i] is DanmuMSG {
                            DanmuView(danmuMSG: (bilicore.bilibiliMSGs[i] as? DanmuMSG)!).id(i)
                        } else if bilicore.bilibiliMSGs[i] is GiftMSG {
                            GiftView(giftMSG: (bilicore.bilibiliMSGs[i] as? GiftMSG)!).id(i)
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
                EntryView(entryMSG: bilicore.entryMSGs.last ?? EntryMSG(uid: 0, uname: "", mlevel: 0, mcolor: colorScheme == .dark ? 16777215 : 0, mname: "", timestamp: 0))
            }
        }
        .padding(10)
        .navigationTitle(bilicore.isConnected && !bilicore.streamer_name.isEmpty ? "欢迎光临 \(bilicore.streamer_name) 的直播间" : "") /// TODO: use uname
        .toolbarTitleDisplayMode(.inline)
        
    }
}

#Preview {
    MainView()
}
