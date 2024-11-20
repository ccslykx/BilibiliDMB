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
    
    private var m_scale = 1.0
     
    var body: some View {
        
        NavigationSplitView(sidebar: {
            
            Text("设置").font(.title)
            
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
                .navigationSplitViewColumnWidth(min: 300, ideal: 300, max: 600)
        }, detail: {
            
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
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                    .onChange(of: bilicore.bilibiliMSGs, {
                        withAnimation(.easeInOut) {
                            proxy.scrollTo(bilicore.bilibiliMSGs.indices.last)
                        }
                    })
                }
                
                Spacer()
                
                if (!bilicore.entryMSGs.isEmpty) {
                    EntryView(entryMSG: bilicore.entryMSGs.last ?? EntryMSG(uid: 0, uname: "", mlevel: 0, mcolor: colorScheme == .dark ? 16777215 : 0, mname: "", timestamp: 0))
                }
            }
            .padding(10)
            .navigationTitle(bilicore.isConnected ? "欢迎光临 \(liveRoomID) 的直播间" : "") /// TODO: use uname
            .toolbarTitleDisplayMode(.inline)
            
        })
        .background()
    }
}

#Preview {
    MainView()
}
