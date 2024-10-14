//
//  MedalView.swift
//  BilibiliDMB
//
//  Created by Ccslykx on 2024/10/14.
//

import SwiftUI

struct MedalView: View {
    var m_level: Int        /// 粉丝等级
    var m_color: UInt32     /// 粉丝牌颜色
    var m_name: String      /// 粉丝版名称
    
    var m_scale: CGFloat = 1.0          /// 缩放倍数
    var m_roundSize: CGFloat = 4.0      /// 圆角度数
    
    var m_font: String = ""             /// 文本字体
    var m_fontsize: CGFloat = 16.0      /// 文本字体大小
    
    var body: some View {
        RoundedRectangle(cornerSize: CGSize(width: m_roundSize * m_scale, height: m_roundSize * m_scale))
            .fill(Color(dec: m_color))
            .frame(width: 100 * m_scale, height: 24 * m_scale, alignment: .center)
            .overlay {
                HStack(alignment: .center) {
                    Spacer(minLength: 2)
                    
                    RoundedRectangle(cornerSize: CGSize(width: m_roundSize * m_scale, height: m_roundSize * m_scale))
                        .fill(.clear)
                        .frame(width: 66 * m_scale, height: 18 * m_scale, alignment: .center)
                        .padding(4 * m_scale)
                        .overlay {
                            Text(m_name)
                                .foregroundStyle(.white)
                                .font(.custom(m_font, size: m_fontsize * m_scale))
                                .scaledToFill()
                        }
                    
                    Spacer(minLength: 2)
                    
                    RoundedRectangle(cornerSize: CGSize(width: m_roundSize * m_scale, height: m_roundSize * m_scale))
                        .fill(.white)
                        .frame(width: 20 * m_scale, height: 18 * m_scale, alignment: .center)
                        .padding(4 * m_scale)
                        .overlay {
                            Text(String(m_level))
                                .foregroundStyle(Color(dec: m_color))
                                .font(.custom(m_font, size: m_fontsize * m_scale))
                                .scaledToFill()
                        }
                    
                    Spacer(minLength: 2)
                }
            }
    }
}

#Preview {
    MedalView(m_level: 10, m_color: 167777, m_name: "Medal", m_scale: 2)
}
