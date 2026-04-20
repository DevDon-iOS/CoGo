//
//  NearbyDeviceManager.swift
//  CoGo
//
//  Created by 이돈혁 on 4/15/26.
//

import Foundation
import Combine
import MultipeerConnectivity
import UIKit

/// 홈뷰에서 표시할 주변 기기 한 개를 표현하는 모델
struct NearbyPeer: Identifiable, Equatable {
    /// MultipeerConnectivity가 제공하는 고유한 피어 식별자
    let id: MCPeerID
    /// 화면에 보여줄 상대 기기의 표시 이름
    let displayName: String
    /// advertise 단계에서 함께 전달받은 부가 정보
    let discoveryInfo: [String: String]
    /// 마지막으로 이 기기를 발견한 시각
    let lastSeenAt: Date
}

/// SwiftUI와 MultipeerConnectivity delegate를 함께 쓰기 위한 매니저 클래스
final class NearbyDeviceManager: NSObject, ObservableObject {
    /// 홈뷰가 구독할 주변 기기 목록
    @Published private(set) var nearbyPeers: [NearbyPeer] = []
    /// 홈뷰 상단에 보여줄 현재 탐색 상태 문구
    @Published private(set) var authorizationState: String = "주변 기기 탐색 준비 중"

    /// 같은 앱끼리만 찾도록 고정된 Bonjour 서비스 타입
    private static let serviceType = "cogo-nearby"

    /// 현재 내 기기를 나타내는 피어 아이디
    private let myPeerID: MCPeerID
    /// 내 기기를 주변에 advertise하는 객체
    private let advertiser: MCNearbyServiceAdvertiser
    /// 주변에서 같은 서비스를 advertise하는 기기를 찾는 객체
    private let browser: MCNearbyServiceBrowser

    /// 앱이 매니저를 만들 때 advertise와 탐색 객체를 함께 초기화
    override init() {
        /// 현재 아이폰 이름을 피어 표시 이름으로 사용
        let displayName = UIDevice.current.name
        /// MultipeerConnectivity용 피어 아이디 생성
        let peerID = MCPeerID(displayName: displayName)
        /// 브라우저가 바로 표시할 수 있도록 간단한 정보를 advertise에 포함
        let discoveryInfo = ["displayName": displayName]

        /// 위에서 만든 peerID를 내 기기 식별값 프로퍼티에 저장
        self.myPeerID = peerID
        /// 내 기기를 주변에 advertise할 객체 생성
        self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: discoveryInfo, serviceType: Self.serviceType)
        /// 주변에서 같은 serviceType을 쓰는 기기를 찾을 객체 생성
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)

        /// NSObject를 상속받고 있으므로 부모 초기화를 먼저 완료
        super.init()

        /// 초대나 advertise 에러를 받을 delegate 지정
        advertiser.delegate = self
        /// 탐색 결과와 탐색 에러를 받을 delegate 지정
        browser.delegate = self
    }

    /// 매니저가 해제될 때 네트워크 탐색 정리
    deinit {
        stop()
    }

    /// 홈뷰에서 주변 탐색을 다시 시작할 때 호출하는 메서드
    func start() {
        authorizationState = "주변 CoGo 기기 탐색 중"
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    /// 앱이 사라지거나 매니저가 내려갈 때 탐색을 멈추는 메서드
    func stop() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
    }

    /// 새 기기를 추가하거나 기존 기기 정보를 갱신하는 메서드
    private func upsertPeer(_ peerID: MCPeerID, discoveryInfo: [String: String]?) {
        /// advertise 정보가 있으면 그 값을, 없으면 피어 기본 이름 사용
        let displayName = discoveryInfo?["displayName"] ?? peerID.displayName
        /// 현재 시각 기준으로 모델 생성
        let peer = NearbyPeer(id: peerID, displayName: displayName, discoveryInfo: discoveryInfo ?? [:], lastSeenAt: Date())

        /// 이미 목록에 있는 기기면 최신 정보로 덮어쓰기
        if let index = nearbyPeers.firstIndex(where: { $0.id == peerID }) {
            nearbyPeers[index] = peer
        } else {
            /// 새 기기면 배열에 추가 후 이름순 정렬
            nearbyPeers.append(peer)
            nearbyPeers.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        }

        /// 목록 개수에 맞춰 상태 문구 갱신
        authorizationState = nearbyPeers.isEmpty ? "주변 CoGo 기기를 찾는 중" : "주변 CoGo 기기 \(nearbyPeers.count)대 발견"
    }

    /// 탐색 범위에서 사라진 기기를 목록에서 제거하는 메서드
    private func removePeer(_ peerID: MCPeerID) {
        nearbyPeers.removeAll { $0.id == peerID }
        authorizationState = nearbyPeers.isEmpty ? "주변 CoGo 기기를 찾는 중" : "주변 CoGo 기기 \(nearbyPeers.count)대 발견"
    }
}

/// 탐색 결과를 처리하기 위한 브라우저 delegate 구현
extension NearbyDeviceManager: MCNearbyServiceBrowserDelegate {
    /// 새로운 주변 기기를 찾았을 때 호출
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        /// 내 기기 자신은 목록에 넣지 않도록 제외
        guard peerID != myPeerID else { return }

        /// SwiftUI 상태 변경은 메인 스레드에서 수행
        DispatchQueue.main.async {
            self.upsertPeer(peerID, discoveryInfo: info)
        }
    }

    /// 기존에 보이던 기기가 탐색 범위에서 사라졌을 때 호출
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.removePeer(peerID)
        }
    }

    /// 탐색 시작 자체가 실패했을 때 호출
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: any Error) {
        DispatchQueue.main.async {
            self.authorizationState = "주변 탐색 실패: \(error.localizedDescription)"
        }
    }
}

/// advertise 관련 이벤트를 처리하기 위한 advertiser delegate 구현
extension NearbyDeviceManager: MCNearbyServiceAdvertiserDelegate {
    /// 다른 기기에서 세션 초대를 보냈을 때 호출
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        /// 현재 요구사항은 탐색과 표시만이므로 세션 초대는 받지 않음
        invitationHandler(false, nil)
    }

    /// advertise 시작 자체가 실패했을 때 호출
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: any Error) {
        DispatchQueue.main.async {
            self.authorizationState = "advertise 시작 실패: \(error.localizedDescription)"
        }
    }
}
