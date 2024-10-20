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
    
    init(content: String, color: UInt32, uid: Int?, uname: String, mlevel: Int, mcolor: UInt32, mname: String, timestamp: Int, scale: CGFloat) {
        self.danmuMSG = DanmuMSG(content: content, color: color, uid: uid, uname: uname, mlevel: mlevel, mcolor: mcolor, mname: mname, timestamp: timestamp)
        self.scale = scale
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

struct EntryView: View {
    var entryMSG: EntryMSG
    
    var scale: CGFloat = 1.0
    
    init(entryMSG: EntryMSG) {
        self.entryMSG = entryMSG
    }
    
    init(uid: Int?, uname: String, mlevel: Int, mcolor: UInt32, mname: String, timestamp: Int) {
        entryMSG = EntryMSG(uid: uid, uname: uname
                            , mlevel: mlevel, mcolor: mcolor, mname: mname, timestamp: timestamp)
    }
    
    var body: some View {
        DanmuView(content: "进入了直播间", color: 0, uid: entryMSG.uid, uname: entryMSG.uname, mlevel: entryMSG.mlevel, mcolor: entryMSG.mcolor, mname: entryMSG.mname, timestamp: entryMSG.timestamp, scale: scale)
    }
}

#Preview {
    VStack {
        EntryView(uid: 1, uname: "Ccslykx", mlevel: 12, mcolor: 1234567, mname: "Ccslykx", timestamp: 1700000000)

        DanmuView(content: "我是一条弹幕", color: 7654321, uid: 1, uname: "Ccslykx", mlevel: 12, mcolor: 1234567, mname: "Ccslykx", timestamp: 1700000000, scale: 1.0)        
    }
}
