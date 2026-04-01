//
//  ProfileModalView.swift
//  CoGo
//
//  Created by 이돈혁 on 4/1/26.
//

import SwiftUI

struct ProfileModalView: View {
    var body: some View {
        VStack {
            Image("user_01")
            Text("이름")
                .font(Font.title.bold())
                .frame(maxWidth: 100, maxHeight: 100, alignment: .init(horizontal: .center, vertical: .center))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            Text("닉네임")
                .font(Font.title.bold())
                .frame(maxWidth: 100, maxHeight: 100, alignment: .init(horizontal: .center, vertical: .center))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
        }
    }
}
