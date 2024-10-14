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
