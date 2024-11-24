//
//  DanmuView.swift
//  BilibiliDMB
//
//  Created by Ccslykx on 2024/10/14.
//

import SwiftUI

struct DanmuView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var danmuMSG: DanmuMSG
    
    var scale: CGFloat = 1.0
    var fontname: String = ""
    var is_display_time: Bool = true
    var is_display_medal: Bool = true
    
    let fontsize: CGFloat = 20.0
    
    init(danmuMSG: DanmuMSG, scale: CGFloat = 1.0, fontname: String = "",
         is_display_time: Bool = true, is_display_medal: Bool = true) {
        self.danmuMSG = danmuMSG
        self.scale = scale
        self.fontname = fontname
        self.is_display_time = is_display_time
        self.is_display_medal = is_display_medal
    }
    
    init(content: String, color: UInt32, uid: Int?, uname: String,
         mlevel: Int, mcolor: UInt32, mname: String, timestamp: Int,
         scale: CGFloat = 1.0,  fontname: String = "",
         is_display_time: Bool = true, is_display_medal: Bool = true) {
        self.danmuMSG = DanmuMSG(content: content, color: color, uid: uid, uname: uname, mlevel: mlevel, mcolor: mcolor, mname: mname, timestamp: timestamp)
        self.scale = scale
        self.fontname = fontname
        self.is_display_time = is_display_time
        self.is_display_medal = is_display_medal
    }
    
    private func adjustColor(color: UInt32) -> UInt32 {
        if (color == 0 && colorScheme == .dark) {
            return 16777215
        } else if (color == 16777215 && colorScheme == .light) {
            return 0
        }
        return color
    }
    
    var body: some View {
        HStack (alignment: .center) {
            // 时间
            if (is_display_time) {
                Text(String(danmuMSG.timestamp.timestampToDate()))
                    .foregroundStyle(Color(dec: adjustColor(color: danmuMSG.color)))
                    .font(.custom(fontname, size: fontsize * scale))
                    .frame(alignment: .center)
            }
            
            // 粉丝牌
            if (!danmuMSG.mname.isEmpty && is_display_medal) {
                MedalView(level: danmuMSG.mlevel, color: danmuMSG.mcolor, name: danmuMSG.mname, scale: scale)
                    .frame(alignment: .center).padding(2.5)
            }
            
            // 用户名 和 弹幕信息
            Text("\(danmuMSG.uname): \(danmuMSG.content)")
                .foregroundStyle(Color(dec: adjustColor(color: danmuMSG.color)))
                .font(.custom(fontname, size: (fontsize) * scale))
                .frame(alignment: .center)
        }
    }
}

struct EntryView: View {
    var entryMSG: EntryMSG
    
    var scale: CGFloat = 1.0
    var fontname: String = ""
    var is_display_time: Bool = true
    var is_display_medal: Bool = true
    
    init(entryMSG: EntryMSG, scale: CGFloat = 1.0, fontname: String = "", is_display_time: Bool = true, is_display_medal: Bool = true) {
        self.entryMSG = entryMSG
        self.scale = scale
        self.fontname = fontname
        self.is_display_time = is_display_time
        self.is_display_medal = is_display_medal
    }
    
    init(uid: Int?, uname: String, mlevel: Int, mcolor: UInt32, mname: String, timestamp: Int, scale: CGFloat = 1.0, fontname: String = "", is_display_time: Bool = true, is_display_medal: Bool = true) {
        self.entryMSG = EntryMSG(uid: uid, uname: uname
                            , mlevel: mlevel, mcolor: 0, mname: mname, timestamp: timestamp)
        self.scale = scale
        self.fontname = fontname
        self.is_display_time = is_display_time
        self.is_display_medal = is_display_medal
    }
    
    var body: some View {
        DanmuView(content: "进入了直播间", color: 0, uid: entryMSG.uid, uname: entryMSG.uname, mlevel: entryMSG.mlevel, mcolor: entryMSG.mcolor, mname: entryMSG.mname, timestamp: entryMSG.timestamp, scale: scale, fontname: fontname, is_display_time: is_display_time, is_display_medal: is_display_medal)
    }
}

struct SysMsgView: View {
    var msg: String
    var timestamp: Int
    var scale: CGFloat
    
    init(msg: String, timestamp: Int = Int(Date.now.timeIntervalSince1970), scale: CGFloat = 1.0) {
        self.msg = msg
        self.timestamp = timestamp
        self.scale = scale
    }
    
    var body: some View {
        DanmuView(content: msg, color: 0, uid: 0, uname: "系统消息", mlevel: 0, mcolor: 0, mname: "SYSTEM", timestamp: timestamp, scale: scale)
    }
}

#Preview {
    VStack {
        var now = Int(Date.now.timeIntervalSince1970)
        EntryView(uid: 1, uname: "Ccslykx", mlevel: 12, mcolor: 1234567, mname: "Ccslykx", timestamp: now)

        DanmuView(content: "我是一条弹幕", color: 7654321, uid: 1, uname: "Ccslykx", mlevel: 12, mcolor: 1234567, mname: "Ccslykx", timestamp: now, scale: 0.2)
        DanmuView(content: "我是一条弹幕", color: 7654321, uid: 1, uname: "ABCDEFG", mlevel: 12, mcolor: 1234567, mname: "ABC", timestamp: now, scale: 0.5)
        SysMsgView(msg: "我是系统提示！")
    }
}
