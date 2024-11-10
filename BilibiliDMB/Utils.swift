//
//  Utils.swift
//  BilibiliDMB
//
//  Created by Ccslykx on 2024/10/14.
//

import SwiftUI

extension Color {
    init(dec: UInt32, alpha: Double = 1) {
        let RGB = (
            R: Double((dec >> 16) & 0xff) / 255,
            G: Double((dec >> 08) & 0xff) / 255,
            B: Double((dec >> 00) & 0xff) / 255
        )
        self.init(
            .sRGB,
            red: RGB.R,
            green: RGB.G,
            blue: RGB.B,
            opacity: alpha
        )
    }
}

extension Int {
    func timestampToDate(format: String = "HH:mm:ss") -> String {  /// yyyy年MM月dd日 HH:mm:ss
        let df = DateFormatter()
        df.dateFormat = format
        let date = Date(timeIntervalSince1970: TimeInterval(self))
        return df.string(from: date)
    }
}

enum LogLevel: String {
    case INFO = "INFO"
    case WARNING = "WARNING"
    case ERROR = "ERROR"
}

func LOG(_ message: String, _ level: LogLevel = LogLevel.INFO) {
    print("\(Date.now.formatted(date: .abbreviated, time: .standard)) [\(level)] \(message)")
}

extension Data {
    func _4BytesToInt() -> Int {
        var value: UInt32 = 0
        let data = NSData(bytes: [UInt8](self), length: self.count)
        data.getBytes(&value, length: self.count) /// 把data以字节方式拷贝给value？
        value = UInt32(bigEndian: value)
        return Int(value)
    }
    
    func _2BytesToInt() -> Int {
        var value: UInt16 = 0
        let data = NSData(bytes: [UInt8](self), length: self.count)
        data.getBytes(&value, length: self.count) /// 把data以字节方式拷贝给value？
        value = UInt16(bigEndian: value)
        return Int(value)
    }
}
