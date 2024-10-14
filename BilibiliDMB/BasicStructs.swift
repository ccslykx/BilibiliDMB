//
//  BasicStructs.swift
//  BilibiliDMB
//
//  Created by Ccslykx on 2024/10/14.
//

import Foundation

struct DanmuMSG: Identifiable {
    let content: String     /// 弹幕内容
    let uid: Int?           /// uid
    let uname: String       /// 用户名
    let mlevel: Int         /// 粉丝牌等级
    let mcolor: UInt32      /// 粉丝牌颜色
    let mname: String       /// 粉丝牌名称
    let timestamp: Int      /// 时间戳
    let color: UInt32       /// 弹幕颜色
    let id: UUID = UUID()
}

