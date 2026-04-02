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
        }
    }
}
