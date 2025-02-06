//
//  AgreementView.swift
//  BilibiliDMB
//
//  Created by Ccslykx on 2025/2/6.
//

import SwiftUI

struct AgreementView: View {
    @AppStorage("agreed") private var agreed: Bool = false
    @State private var show_confirm: Bool = false
    var body: some View {
        ScrollView {
            Text("用户须知")
                .font(.title)
                .bold()
                .padding(.top, 40)
            Text("""
                 您好，非常感谢您下载本软件，请您阅读并接受以下内容：
                 1. 本软件旨在为主播提供一个即时直播弹幕的看板，仅限个人用于查看自己直播间弹幕使用
                 2. 请勿滥用，因使用不当造成的任何影响由使用者自行承担，开发者不对因使用本工具而产生的任何版权纠纷或法律责任承担责任
                 3.  因B站限制，匿名状态无法正常获取弹幕，请您在同意后，使用B站客户端扫码登录，您的登录信息会储存在设备本地，在下次打开软件时会自动登录
                 4. 受网络状况等影响，请以官方直播间弹幕为准
                 """)
            .padding(.horizontal, 20)
            
            
            HStack {
                Spacer()
                
                Button("拒绝", role: .cancel) {
                    agreed = false
                    UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("同意", role: .destructive) {
                    show_confirm = true
                }
                .buttonStyle(.bordered)
                .alert("您同意用户须知吗？", isPresented: $show_confirm) {
                    Button("再确认一下", role: .cancel) { agreed = false }
                    Button("同意", role: .destructive) { agreed = true }
                }
                
                Spacer()
            }
            .padding(.vertical, 20)
        }
    }
}

#Preview {
    AgreementView()
}
