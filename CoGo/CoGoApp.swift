//
//  CoGoApp.swift
//  CoGo
//
//  Created by 이돈혁 on 3/27/26.
//

import SwiftUI

@main
struct CoGoApp: App {
    /// 앱 전역에서 함께 사용할 사용자 프로필 저장소
    @StateObject private var profileStore = ProfileStore()

    var body: some Scene {
        WindowGroup {
            MaintabView()
                .environmentObject(profileStore)
//                .toolbar(id: "browserToolbar") {
//                        
//                }
        }
    }
}
