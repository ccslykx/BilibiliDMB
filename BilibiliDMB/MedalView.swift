//
//  MedalView.swift
//  BilibiliDMB
//
//  Created by Ccslykx on 2024/10/14.
//

import SwiftUI

struct MedalView: View {
    let level: Int                      /// 粉丝等级
    let color: UInt32                   /// 粉丝牌颜色
    let name: String                    /// 粉丝版名称
    
    var scale: CGFloat = 1.0            /// 缩放倍数
    let roundSize: CGFloat = 4.0        /// 圆角度数
    
    var fontname: String = ""           /// 文本字体
    let fontsize: CGFloat = 10.0        /// 文本字体大小
    
    var body: some View {
        RoundedRectangle(cornerSize: CGSize(width: roundSize * scale, height: roundSize * scale))
            .fill(Color(dec: color))
            .frame(minWidth: fontsize, maxWidth: fontsize * scale * 6.75 + scale * 6, minHeight: fontsize, maxHeight: fontsize * scale * 1.5 + scale * 4, alignment: .center)
            .overlay {
                HStack(alignment: .center) {
                    Spacer(minLength: 2 * scale)
                    
                    RoundedRectangle(cornerSize: CGSize(width: roundSize * scale, height: roundSize * scale))
                        .fill(.clear)
                        .frame(minWidth: fontsize, maxWidth: fontsize * scale * 4, minHeight: fontsize, maxHeight: fontsize * scale * 1.5, alignment: .center)
                        .padding(4 * scale)
                        .overlay(alignment: .center) {
                            Text(name)
                                .foregroundStyle(.white)
                                .font(.custom(fontname, size: (fontsize + 2) * scale))
                                .scaledToFill()
                        }
                    
                    Spacer(minLength: scale > 1 ? scale : 1)
                    
                    RoundedRectangle(cornerSize: CGSize(width: roundSize * scale, height: roundSize * scale))
                        .fill(.white)
                        .frame(width: fontsize * scale * 1.5, height: (fontsize + 2) * scale, alignment: .center)
                        .padding(4 * scale)
                        .overlay(alignment: .center) {
                            Text(String(level))
                                .foregroundStyle(Color(dec: color))
                                .font(.custom(fontname, size: fontsize * scale))
                                .scaledToFill()
                        }
                    
                    Spacer(minLength: 2 * scale)
                }
            }
    }
}

#Preview {
    MedalView(level: 10, color: 167777, name: "Medal", scale: 4)
}
