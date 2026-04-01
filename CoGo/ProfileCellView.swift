//
//  ProfileCellView.swift
//  CoGo
//
//  Created by 이돈혁 on 3/30/26.
//

import SwiftUI

struct ProfileCellView: View {
    let imageName: String
    
    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: 60, height: 60)
            .clipShape(Circle())
    }
}

// MARK: - preview

#Preview {
    ProfileCellView(imageName: "user_01")
}
