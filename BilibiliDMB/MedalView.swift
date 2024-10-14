//
//  MedalView.swift
//  BilibiliDMB
//
//  Created by Ccslykx on 2024/10/14.
//

import SwiftUI

struct MedalView: View {
    var level: Int                      /// 粉丝等级
    var color: UInt32                   /// 粉丝牌颜色
    var name: String                    /// 粉丝版名称
    
    var scale: CGFloat = 1.0            /// 缩放倍数
    var roundSize: CGFloat = 4.0        /// 圆角度数
    
    var fontname: String = ""           /// 文本字体
    var fontsize: CGFloat = 16.0        /// 文本字体大小
    
    var body: some View {
        RoundedRectangle(cornerSize: CGSize(width: roundSize * scale, height: roundSize * scale))
            .fill(Color(dec: color))
            .frame(width: 100 * scale, height: 24 * scale, alignment: .center)
            .overlay {
                HStack(alignment: .center) {
                    Spacer(minLength: 2)
                    
                    RoundedRectangle(cornerSize: CGSize(width: roundSize * scale, height: roundSize * scale))
                        .fill(.clear)
                        .frame(width: 66 * scale, height: 18 * scale, alignment: .center)
                        .padding(4 * scale)
                        .overlay {
                            Text(name)
                                .foregroundStyle(.white)
                                .font(.custom(fontname, size: fontsize * scale))
                                .scaledToFill()
                        }
                    
                    Spacer(minLength: 2)
                    
                    RoundedRectangle(cornerSize: CGSize(width: roundSize * scale, height: roundSize * scale))
                        .fill(.white)
                        .frame(width: 20 * scale, height: 18 * scale, alignment: .center)
                        .padding(4 * scale)
                        .overlay {
                            Text(String(level))
                                .foregroundStyle(Color(dec: color))
                                .font(.custom(fontname, size: fontsize * scale))
                                .scaledToFill()
                        }
                    
                    Spacer(minLength: 2)
                }
            }
    }
}

#Preview {
    MedalView(level: 10, color: 167777, name: "Medal", scale: 2)
}
