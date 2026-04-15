//
//  BumpModalView.swift
//  CoGo
//
//  Created by 이돈혁 on 4/2/26.
//

import SwiftUI

struct BumpModalView: View {
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Bump!")
                .font(.largeTitle.bold())
            
            Text("네임드랍으로 연락처를 공유하세요")
                .font(.title3)
                .multilineTextAlignment(.center)
            
            Button {
                onConfirm()
                
            } label: {
                Text("네임드랍 했다고 치는 버튼")
                    .foregroundColor(.white)
                    .font(Font.body.bold())
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.top, 28)
            }
        }
    }
}
