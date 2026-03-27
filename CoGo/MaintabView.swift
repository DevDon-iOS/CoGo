//
//  MaintabView.swift
//  CoGo
//
//  Created by 이돈혁 on 3/27/26.
//

import SwiftUI

struct MaintabView: View {
    var body: some View {
        TabView() {
            Tab("Home", systemImage: "house") {
                ContentView()
            }
            
            Tab("Collection", systemImage: "square.stack"){
                CollectionView()
            }
        }
    }
}
