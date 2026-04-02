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
            
        }
    }
}
