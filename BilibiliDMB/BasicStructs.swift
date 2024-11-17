//
//  BasicStructs.swift
//  BilibiliDMB
//
//  Created by Ccslykx on 2024/10/14.
//

import Foundation

class BilibiliMSG: Identifiable, Equatable, Hashable {
    let id: UUID = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (l: BilibiliMSG, r: BilibiliMSG) -> Bool {
        return l.id == r.id
    }
}

class DanmuMSG: BilibiliMSG {
    let content: String     /// 弹幕内容
    let color: UInt32       /// 弹幕颜色

    let uid: Int?           /// uid
    let uname: String       /// 用户名

    let mlevel: Int         /// 粉丝牌等级
    let mcolor: UInt32      /// 粉丝牌颜色
    let mname: String       /// 粉丝牌名称

    let timestamp: Int      /// 时间戳
    
    init(content: String, color: UInt32, uid: Int?, uname: String, mlevel: Int, mcolor: UInt32, mname: String, timestamp: Int) {
        self.content = content
        self.color = color
        self.uid = uid
        self.uname = uname
        self.mlevel = mlevel
        self.mcolor = mcolor
        self.mname = mname
        self.timestamp = timestamp
    }
}

class GiftMSG: BilibiliMSG {
    let giftname: String    /// 礼物名称
    let giftnum: Int        /// 礼物数量
    let giftprice: Int      /// 礼物价值
    
    let uid: Int?           /// uid
    let uname: String       /// 用户名
    
    let mlevel: Int         /// 粉丝牌等级
    let mcolor: UInt32      /// 粉丝牌颜色
    let mname: String       /// 粉丝牌名称
    
    let timestamp: Int      /// 时间戳

    init(giftname: String, giftnum: Int, giftprice: Int, uid: Int?, uname: String, mlevel: Int, mcolor: UInt32, mname: String, timestamp: Int) {
        self.giftname = giftname
        self.giftnum = giftnum
        self.giftprice = giftprice
        self.uid = uid
        self.uname = uname
        self.mlevel = mlevel
        self.mcolor = mcolor
        self.mname = mname
        self.timestamp = timestamp
    }
}

class EntryMSG: BilibiliMSG {
    let uid: Int?           /// uid
    let uname: String       /// 用户名
    
    let mlevel: Int         /// 粉丝牌等级
    let mcolor: UInt32      /// 粉丝牌颜色
    let mname: String       /// 粉丝牌名称
    
    let timestamp: Int      /// 时间戳
    
    init(uid: Int?, uname: String, mlevel: Int, mcolor: UInt32, mname: String, timestamp: Int) {
        self.uid = uid
        self.uname = uname
        self.mlevel = mlevel
        self.mcolor = mcolor
        self.mname = mname
        self.timestamp = timestamp
    }
}
