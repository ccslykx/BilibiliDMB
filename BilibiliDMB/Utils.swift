//
//  Utils.swift
//  BilibiliDMB
//
//  Created by Ccslykx on 2024/10/14.
//

import SwiftUI
import CoreImage

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
    case DANMU = "DANMU"
    case GIFT = "GIFT"
    case ENTRY = "ENTRY"
}

func LOG(_ message: String, _ level: LogLevel = LogLevel.INFO) {
    print("\(Date.now.formatted(date: .abbreviated, time: .standard)) [\(level)] \(message)")
}

func LOG(_ d: DanmuMSG) {
    if (d.mlevel == 0) {
        print("[\(LogLevel.DANMU)] \(d.timestamp.timestampToDate(format: "HH:mm:ss")) \(d.uname): \(d.content)")
    } else {
        print("[\(LogLevel.DANMU)] \(d.timestamp.timestampToDate(format: "HH:mm:ss")) [\(d.mname) <\(d.mlevel)>] \(d.uname): \(d.content)")
    }
}

func LOG(_ g: GiftMSG, _ level: LogLevel = LogLevel.INFO) {
    if (g.mlevel == 0) {
        print("[\(LogLevel.GIFT)] \(g.timestamp.timestampToDate(format: "HH:mm:ss")) \(g.uname) 送出了 \(g.giftnum) 个 \(g.giftname)")
    } else {
        print("[\(LogLevel.GIFT)] \(g.timestamp.timestampToDate(format: "HH:mm:ss")) [\(g.mname) <\(g.mlevel)>] \(g.uname) 送出了 \(g.giftnum) 个 \(g.giftname)")
    }
}

func LOG(_ e: EntryMSG, _ level: LogLevel = LogLevel.INFO) {
    if (e.mlevel == 0) {
        print("[\(LogLevel.ENTRY)] \(e.timestamp.timestampToDate(format: "HH:mm:ss")) \(e.uname) 进入了直播间")
    } else {
        print("[\(LogLevel.ENTRY)] \(e.timestamp.timestampToDate(format: "HH:mm:ss")) [\(e.mname) <\(e.mlevel)>] \(e.uname) 进入了直播间")
    }
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

func generateQRCode(from string: String, size: CGFloat) -> CGImage? {
    // Convert the input string to data
    guard let data = string.data(using: .utf8) else { return nil }
    
    // Create the QR code filter
    let filter = CIFilter(name: "CIQRCodeGenerator")
    filter?.setValue(data, forKey: "inputMessage")
    filter?.setValue("H", forKey: "inputCorrectionLevel") // Higher correction level for better readability
    
    // Get the output CIImage
    guard let ciImage = filter?.outputImage else { return nil }
    
    // Calculate the scale needed to achieve the desired sharpness
    let scaleX = size / ciImage.extent.size.width
    let scaleY = size / ciImage.extent.size.height
    let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
    
    // Apply scaling transform to make the QR code sharp
    let scaledImage = ciImage.transformed(by: transform)
    
    // Convert to CGImage
    let context = CIContext()
    if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
        return cgImage
    }
    return nil
}

// https://www.jianshu.com/p/04e76474ec6d
struct FixedSizeArray<T: Equatable> : Equatable, RandomAccessCollection {
    private var maxSize: Int
    private var array: [T] = []
    var count = 0
    
    init (maxSize: Int) {
        self.maxSize = maxSize
        self.array = [T]()
    }
    
    var startIndex: Int { array.startIndex }
    var endIndex: Int { array.endIndex }
    
    mutating func append(newElement: T) {
        let d = count - maxSize
        if (d > 0 && maxSize > 0) {
            array.removeFirst(d)
            count -= d
        }
        array.append(newElement)
        count += 1
    }
    
    mutating func setMaxSize(maxSize: Int) {
        self.maxSize = maxSize
    }
    
    static func == (l: FixedSizeArray<T>, r: FixedSizeArray<T>) -> Bool {
        if (l.array == r.array) {
            return true
        } else {
            return false
        }
    }
    
    subscript(index: Int) -> T {
        assert(index >= 0)
        assert(index < count)
        return array[index]
    }
}

class ScreenAwakeManager: ObservableObject {
    func keepScreenAwake(_ shouldKeepAwake: Bool) {
        UIApplication.shared.isIdleTimerDisabled = shouldKeepAwake
    }
}
