//
//  ProfileStore.swift
//  CoGo
//
//  Created by 이돈혁 on 4/2/26.
//

import Foundation
import Combine

/// 사용자 프로필을 메모리와 UserDefaults에 함께 보관하는 저장소
final class ProfileStore: ObservableObject {
    /// UserDefaults에 프로필 데이터를 저장할 때 사용할 키
    private let storageKey = "saved_profile"
    /// 화면에서 구독할 현재 프로필 값
    @Published private(set) var profile: Profile

    /// 앱이 시작될 때 저장된 프로필을 먼저 읽어옴
    init() {
        /// 저장된 값이 없으면 빈 프로필로 시작
        self.profile = Self.loadProfile(forKey: storageKey)
    }

    /// 이름, 닉네임, 사진을 한 번에 저장하는 메서드
    func saveProfile(name: String, nickname: String, photoData: Data?) {
        /// 공백만 입력한 경우를 막기 위해 앞뒤 공백 제거
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        /// 닉네임도 같은 방식으로 정리
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        /// 최신 입력값으로 새 프로필 생성
        let updatedProfile = Profile(id: profile.id, name: trimmedName, nickname: trimmedNickname, photoData: photoData)

        profile = updatedProfile
        persist(updatedProfile)
    }

    /// 현재 저장된 프로필을 초기 상태로 되돌리는 메서드
    func resetProfile() {
        profile = .empty
        persist(.empty)
    }

    /// 프로필을 UserDefaults에 저장
    private func persist(_ profile: Profile) {
        /// Codable 데이터를 JSON으로 바꿔 저장
        guard let encoded = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }

    /// UserDefaults에서 프로필을 읽어오는 정적 메서드
    private static func loadProfile(forKey key: String) -> Profile {
        /// 저장된 Data가 없으면 빈 프로필 반환
        guard let savedData = UserDefaults.standard.data(forKey: key) else {
            return .empty
        }
        /// 디코딩에 실패해도 앱이 깨지지 않도록 빈 프로필 반환
        guard let decoded = try? JSONDecoder().decode(Profile.self, from: savedData) else {
            return .empty
        }
        return decoded
    }
}
