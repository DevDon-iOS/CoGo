//
//  Profile.swift
//  CoGo
//
//  Created by 이돈혁 on 3/30/26.
//

import Foundation

struct Profile: Codable, Identifiable, Equatable {
    /// 사용자 프로필을 한 건만 저장하기 위한 고정 id
    let id: String
    /// 사용자가 직접 입력하는 이름
    var name: String
    /// 사용자가 직접 입력하는 닉네임
    var nickname: String
    /// 사용자가 직접 선택한 프로필 사진의 바이너리 데이터
    var photoData: Data?
    /// 아무것도 입력하지 않은 기본 프로필 상태
    static let empty = Profile(id: "my-profile", name: "", nickname: "", photoData: nil)
}
