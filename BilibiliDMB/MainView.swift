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
    
    private var m_scale = 1.0
     
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "house.circle") // 一个图标
                    .imageScale(.large)
                TextField("直播间ID", text: $liveRoomID) // 输入直播间ID的文本框
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150, height: 34, alignment: .leading)
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
                
                Button("登录") {
                    bilicore.login()
                }
                Text(bilicore.qrcode_status)
                
            }.padding(20)
            if (!self.bilicore.qrcode_url.isEmpty) {
                Image(generateQRCode(from: self.bilicore.qrcode_url, size: 400)!, scale: 1.0, label: Text("Login QR Code"))
            }
            ScrollViewReader { proxy in
                List {
                    ForEach(bilicore.danmuMSGs.indices, id: \.self) { i in
                        DanmuView(danmuMSG: bilicore.danmuMSGs[i]).id(i)
                    }
                }
                .onChange(of: bilicore.danmuMSGs, {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(bilicore.danmuMSGs.indices.last)
                    }
                })
                .background(Color.clear)
                .scrollContentBackground(.hidden)
                
            }
            
            ScrollViewReader { proxy in
                List {
                    ForEach(bilicore.giftMSGs.indices, id: \.self) { i in
                        GiftView(giftMSG: bilicore.giftMSGs[i]).id(i)
                    }
                }
                .onChange(of: bilicore.giftMSGs, {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(bilicore.giftMSGs.indices.last)
                    }
                })
                .background(Color.clear)
                .scrollContentBackground(.hidden)
            }
            
            if (!bilicore.entryMSGs.isEmpty) {
                EntryView(entryMSG: bilicore.entryMSGs.last ?? EntryMSG(uid: 0, uname: "", mlevel: 0, mcolor: 0, mname: "", timestamp: 0))
            }
            
        }
    }
}
