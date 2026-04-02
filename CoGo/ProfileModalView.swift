//
//  ProfileModalView.swift
//  CoGo
//
//  Created by 이돈혁 on 4/1/26.
//

import SwiftUI

struct ProfileModalView: View {
    
    let imageName: String
    let name: String
    let nickName: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(imageName)
                .resizable()
                /// 비율을 유지하며 최대한 맞춤
                /// 가로 이미지 -> 가로 기준 맞춤
                /// 세로 이미지 -> 세로 기준 맞춤
                .scaledToFit()
                /// 이미지 최대 크기 제한
                .frame(maxWidth: 350, maxHeight: 350)
                /// 이미지 모서리를 둥글게
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Text(name)
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            Text(nickName)
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
        }
        .padding(.horizontal, 24)
    }
}
