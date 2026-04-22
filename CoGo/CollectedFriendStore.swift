//
//  CollectedFriendStore.swift
//  CoGo
//
//  Created by 이돈혁 on 4/2/26.
//

import Foundation
import Combine

/// 컬렉션에 반영할 친구 프로필 한 건
struct CollectedFriend: Codable, Equatable {
    /// 친구 이름
    let name: String
    /// 친구 닉네임
    let nickname: String
    /// 친구 프로필 사진 데이터
    let photoData: Data?
}

/// 미로를 함께 푼 친구를 저장하는 전역 저장소
final class CollectedFriendStore: ObservableObject {
    /// UserDefaults에 저장할 키
    private let storageKey = "collected_friend"
    /// 현재 컬렉션 첫 원에 표시할 친구
    @Published private(set) var firstCollectedFriend: CollectedFriend?

    /// 앱 시작 시 저장된 친구를 복원
    init() {
        firstCollectedFriend = Self.loadFriend(forKey: storageKey)
    }

    /// 첫 번째 컬렉션 원에 표시할 친구를 저장
    func saveFirstCollectedFriend(_ friend: CollectedFriend) {
        firstCollectedFriend = friend
        persist(friend)
    }

    /// 저장된 친구를 UserDefaults에 기록
    private func persist(_ friend: CollectedFriend) {
        guard let encoded = try? JSONEncoder().encode(friend) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }

    /// UserDefaults에서 저장된 친구를 읽어오는 메서드
    private static func loadFriend(forKey key: String) -> CollectedFriend? {
        guard let savedData = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(CollectedFriend.self, from: savedData)
    }
}
