//
//  DanmuView.swift
//  BilibiliDMB
//
//  Created by Ccslykx on 2024/10/14.
//

import SwiftUI

struct DanmuView: View {
    var danmuMSG: DanmuMSG
    
    var scale: CGFloat = 1.0
    var fontname: String = ""
    var fontsize: CGFloat = 24.0
    
    init(danmuMSG: DanmuMSG) {
        self.danmuMSG = danmuMSG
    }
    
    init(content: String, uid: Int?, uname: String, mlevel: Int, mcolor: UInt32, mname: String, timestamp: Int, color: UInt32, id: UUID = UUID()) {
        danmuMSG = DanmuMSG(content: content, uid: uid, uname: uname, mlevel: mlevel, mcolor: mcolor, mname: mname, timestamp: timestamp, color: color)
    }
    
    var body: some View {
        HStack (alignment: .center) {
            // 时间
            Text(String(danmuMSG.timestamp.timestampToDate()))
                .foregroundStyle(Color(dec: danmuMSG.color))
                .font(.custom(fontname, size: fontsize * scale))
            
            // 粉丝牌
            if (!danmuMSG.mname.isEmpty) {
                MedalView(level: danmuMSG.mlevel, color: danmuMSG.mcolor, name: danmuMSG.mname, scale: fontsize / 16.0)
            }
            
            // 用户名
            Text(danmuMSG.uname)
                .foregroundStyle(Color(dec: danmuMSG.color))
                .font(.custom(fontname, size: (fontsize) * scale))
            
            // 弹幕信息
            Text(danmuMSG.content)
                .foregroundStyle(Color(dec: danmuMSG.color))
                .font(.custom(fontname, size: fontsize * scale))
            }
    }
}

#Preview {
    DanmuView(content: "我是一条弹幕", uid: 1, uname: "Ccslykx", mlevel: 12, mcolor: 1234567, mname: "Ccslykx", timestamp: 1700000000, color: 7654321)
}
