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
    @State private var connected: Bool = false

    @Namespace private var dmBottomID
    @Namespace private var giftBottomID
    @Namespace private var entryBottomID
    
    private var timer = DispatchSource.makeTimerSource()
    
    // Setting
    private var capacity: Int = 5
     
    var body: some View {
        HStack {
            Image(systemName: "house.circle") // 一个图标
                .imageScale(.large)
            TextField("直播间ID", text: $liveRoomID) // 输入直播间ID的文本框
                .textFieldStyle(.roundedBorder)
                .frame(width: 150, height: 34, alignment: .leading)
            if (self.connected) {
                Button("断开") {
                    bilicore.disconnect()
                    self.connected = false
//                    timer.cancel()
                }.buttonStyle(.bordered)
            } else {
                Button("连接") {
                    bilicore.connect(roomid: liveRoomID)
                    self.connected = true
//                    UIApplication.shared.isIdleTimerDisabled = true
//                    Task.init() {
//                        timer.resume()
//                    }
                }.buttonStyle(.bordered)
            }
        }.padding(20)
    }
}
