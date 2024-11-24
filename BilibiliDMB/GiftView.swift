//
//  GiftView.swift
//  BilibiliDMB
//
//  Created by Ccslykx on 2024/10/14.
//

import SwiftUI

struct GiftView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var giftMSG: GiftMSG
    
    var scale: CGFloat = 1.0
    var fontname: String = ""
    var is_display_time: Bool = true
    var is_display_medal: Bool = true
    
    let fontsize: CGFloat = 20.0
    
    init(giftMSG: GiftMSG, scale: CGFloat = 1.0, fontname: String = "",
         is_display_time: Bool = true, is_display_medal: Bool = true) {
        self.giftMSG = giftMSG
        self.scale = scale
        self.fontname = fontname
        self.is_display_time = is_display_time
        self.is_display_medal = is_display_medal
    }
    
    init(giftname: String, giftnum: Int, giftprice: Int, uid: Int?, uname: String, mlevel: Int, mcolor: UInt32, mname: String, timestamp: Int, scale: CGFloat = 1.0, fontname: String = "",
         is_display_time: Bool = true, is_display_medal: Bool = true) {
        self.giftMSG = GiftMSG(giftname: giftname, giftnum: giftnum, giftprice: giftprice, uid: uid, uname: uname, mlevel: mlevel, mcolor: mcolor, mname: mname, timestamp: timestamp)
        self.scale = scale
        self.fontname = fontname
        self.is_display_time = is_display_time
        self.is_display_medal = is_display_medal
    }
    
    var body: some View {
        HStack (alignment: .center) {
            // 时间
            if (is_display_time) {
                Text(String(giftMSG.timestamp.timestampToDate()))
                    .foregroundStyle(Color(dec: colorScheme == .dark ? 16777215 : 0))
                    .font(.custom(fontname, size: fontsize * scale))
            }
            // 粉丝牌
            if (!giftMSG.mname.isEmpty && is_display_medal) {
                MedalView(level: giftMSG.mlevel, color: giftMSG.mcolor, name: giftMSG.mname, scale: scale)
            }
            
            // 礼物信息
            Text("\(giftMSG.uname) 送出了 \(giftMSG.giftname) * \(giftMSG.giftnum)")
                .foregroundStyle(Color(dec: colorScheme == .dark ? 16777215 : 0))
                .font(.custom(fontname, size: fontsize * scale))
        }
    }
}

#Preview {
    GiftView(giftname: "小花花", giftnum: 1, giftprice: 1, uid: 1, uname: "Ccslykx", mlevel: 12, mcolor: 1234567, mname: "Ccslykx", timestamp: 1700000000, scale: 1)
}
