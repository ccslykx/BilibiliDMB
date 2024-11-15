//
//  BasicStructs.swift
//  BilibiliDMB
//
//  Created by Ccslykx on 2024/10/14.
//

import Foundation

struct DanmuMSG: Identifiable, Equatable, Hashable {
    let content: String     /// 弹幕内容
    let color: UInt32       /// 弹幕颜色

    let uid: Int?           /// uid
    let uname: String       /// 用户名

    let mlevel: Int         /// 粉丝牌等级
    let mcolor: UInt32      /// 粉丝牌颜色
    let mname: String       /// 粉丝牌名称

    let timestamp: Int      /// 时间戳
    let id: UUID = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (l: DanmuMSG, r: DanmuMSG) -> Bool {
        return l.id == r.id
    }
}

struct GiftMSG: Identifiable, Equatable, Hashable {
    let giftname: String    /// 礼物名称
    let giftnum: Int        /// 礼物数量
    let giftprice: Int      /// 礼物价值
    
    let uid: Int?           /// uid
    let uname: String       /// 用户名
    
    let mlevel: Int         /// 粉丝牌等级
    let mcolor: UInt32      /// 粉丝牌颜色
    let mname: String       /// 粉丝牌名称
    
    let timestamp: Int      /// 时间戳
    let id: UUID = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (l: GiftMSG, r: GiftMSG) -> Bool {
        return l.id == r.id
    }
}

struct EntryMSG: Identifiable, Equatable, Hashable {
    let uid: Int?           /// uid
    let uname: String       /// 用户名
    
    let mlevel: Int         /// 粉丝牌等级
    let mcolor: UInt32      /// 粉丝牌颜色
    let mname: String       /// 粉丝牌名称
    
    let timestamp: Int      /// 时间戳
    let id: UUID = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (l: EntryMSG, r: EntryMSG) -> Bool {
        return l.id == r.id
    }
}
