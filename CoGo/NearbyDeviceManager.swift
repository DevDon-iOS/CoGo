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
    /// 기기의 기본 표시 이름
    let displayName: String
    /// 사용자가 등록한 닉네임
    let nickname: String
    /// 주변 탐색 단계에서 전달받은 작은 프로필 사진 데이터
    let photoData: Data?
    /// 마지막으로 이 기기를 발견한 시각
    let lastSeenAt: Date
}

/// 상대에게 전달할 초대 문구용 최소 정보
private struct GameInviteContext: Codable {
    /// 초대한 사람의 닉네임
    let hostNickname: String
}

/// 상대가 보낸 CoGo 초대 정보를 홈뷰 alert에 넘기기 위한 모델
struct PendingGameInvite: Identifiable {
    /// alert 구분용 고유 id
    let id = UUID()
    /// 초대한 상대 기기 id
    let peerID: MCPeerID
    /// alert 문구에 보여줄 호스트 닉네임
    let hostNickname: String
    /// 사용자가 예/아니오를 눌렀을 때 호출할 invitation handler
    let invitationHandler: (Bool, MCSession?) -> Void
}

/// CoGo 미로에서 각 기기가 맡는 조작 역할
enum CoGoPlayerRole {
    /// 초대를 보낸 사람은 좌우 조작 담당
    case host
    /// 초대를 받은 사람은 상하 조작 담당
    case guest
}

/// SwiftUI와 MultipeerConnectivity delegate를 함께 쓰기 위한 매니저 클래스
final class NearbyDeviceManager: NSObject, ObservableObject {
    /// 홈뷰가 구독할 주변 기기 목록
    @Published private(set) var nearbyPeers: [NearbyPeer] = []
    /// 홈뷰 상단에 보여줄 현재 탐색 상태 문구
    @Published private(set) var authorizationState: String = "주변 기기 탐색 준비 중"
    /// 상대 기기에서 받은 CoGo 초대
    @Published var pendingInvite: PendingGameInvite?
    /// 두 기기 연결이 끝나 미로를 보여줘야 하는지 여부
    @Published private(set) var isGameReady = false
    /// 현재 기기가 맡은 미로 조작 역할
    @Published private(set) var playerRole: CoGoPlayerRole?

    /// 같은 앱끼리만 찾도록 고정된 Bonjour 서비스 타입
    private static let serviceType = "cogo-nearby"

    /// 현재 내 기기를 나타내는 피어 아이디
    private let myPeerID: MCPeerID
    /// 내 기기를 주변에 advertise하는 객체
    private var advertiser: MCNearbyServiceAdvertiser
    /// 주변에서 같은 서비스를 advertise하는 기기를 찾는 객체
    private let browser: MCNearbyServiceBrowser
    /// 실제 1:1 연결을 맺기 위한 세션 객체
    private let session: MCSession
    /// 현재 앱에 저장된 내 프로필 정보
    private var localProfile: Profile = .empty
    /// 탐색과 advertise가 실행 중인지 기록
    private var isRunning = false

    /// 앱이 매니저를 만들 때 세션과 탐색 객체를 함께 초기화
    override init() {
        /// 현재 아이폰 이름을 피어 표시 이름으로 사용
        let displayName = UIDevice.current.name
        /// MultipeerConnectivity용 피어 아이디 생성
        let peerID = MCPeerID(displayName: displayName)
        /// 초기에는 빈 프로필 기준 advertise 정보 생성
        let advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: Self.makeDiscoveryInfo(displayName: displayName, profile: .empty),
            serviceType: Self.serviceType
        )

        self.myPeerID = peerID
        self.advertiser = advertiser
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)

        super.init()

        /// 초대나 advertise 에러를 받을 delegate 지정
        self.advertiser.delegate = self
        /// 탐색 결과와 탐색 에러를 받을 delegate 지정
        self.browser.delegate = self
        /// 실제 세션 연결 상태 변화를 받을 delegate 지정
        self.session.delegate = self
    }

    /// 매니저가 해제될 때 네트워크 탐색 정리
    deinit {
        stop()
    }

    /// 앱에 저장된 최신 프로필을 매니저에 반영
    func updateLocalProfile(_ profile: Profile) {
        localProfile = profile
        rebuildAdvertiser()
    }

    /// 홈뷰에서 주변 탐색을 다시 시작할 때 호출하는 메서드
    func start() {
        guard !isRunning else { return }
        isRunning = true
        isGameReady = false
        playerRole = nil
        authorizationState = "주변 CoGo 기기 탐색 중"
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    /// 앱이 사라지거나 매니저가 내려갈 때 탐색을 멈추는 메서드
    func stop() {
        isRunning = false
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
        playerRole = nil
    }

    /// 홈뷰에서 상대 기기를 눌렀을 때 CoGo 초대를 보내는 메서드
    func invite(_ peer: NearbyPeer) {
        /// 초대한 사람 alert에 표시할 닉네임은 내 프로필 닉네임 우선
        let hostNickname = localProfile.nickname.isEmpty ? myPeerID.displayName : localProfile.nickname
        /// 상대 alert에서 보여줄 문구를 context로 전달
        let context = try? JSONEncoder().encode(GameInviteContext(hostNickname: hostNickname))

        authorizationState = "\(peer.nickname)에게 CoGo 초대를 보내는 중"
        playerRole = .host
        browser.invitePeer(peer.id, to: session, withContext: context, timeout: 15)
    }

    /// 상대가 보낸 CoGo 초대를 수락하는 메서드
    func acceptPendingInvite() {
        guard let pendingInvite else { return }
        authorizationState = "\(pendingInvite.hostNickname)와 연결 중"
        playerRole = .guest
        pendingInvite.invitationHandler(true, session)
        self.pendingInvite = nil
    }

    /// 상대가 보낸 CoGo 초대를 거절하는 메서드
    func declinePendingInvite() {
        guard let pendingInvite else { return }
        pendingInvite.invitationHandler(false, nil)
        self.pendingInvite = nil
        playerRole = nil
        authorizationState = "주변 CoGo 기기 탐색 중"
    }

    /// 세션 연결이 끝난 뒤 미로 화면을 시작 상태로 전환
    func consumeGameReady() {
        isGameReady = false
    }
}

private extension NearbyDeviceManager {
    /// 내 프로필 정보로 advertise용 문자열 딕셔너리를 생성
    static func makeDiscoveryInfo(displayName: String, profile: Profile) -> [String: String] {
        /// 닉네임이 비어 있으면 기기 이름으로 대체
        let nickname = profile.nickname.isEmpty ? displayName : profile.nickname

        var info: [String: String] = [
            "displayName": displayName,
            "nickname": nickname
        ]

        /// discoveryInfo 크기 제한 때문에 아주 작은 썸네일만 실어 봄
        if let encodedThumbnail = encodedThumbnailString(from: profile.photoData) {
            info["thumbnail"] = encodedThumbnail
        }

        return info
    }

    /// 아주 작은 프로필 사진을 Base64 문자열로 압축
    static func encodedThumbnailString(from photoData: Data?) -> String? {
        guard let photoData, let image = UIImage(data: photoData) else {
            return nil
        }

        let targetSize = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard let compressedData = resizedImage.jpegData(compressionQuality: 0.12) else {
            return nil
        }

        let encodedString = compressedData.base64EncodedString()

        /// discoveryInfo 제한을 넘기면 사진 없이 advertise
        return encodedString.count <= 350 ? encodedString : nil
    }

    /// advertise에서 받은 thumbnail 문자열을 실제 Data로 복원
    static func decodedThumbnailData(from encodedString: String?) -> Data? {
        guard let encodedString else { return nil }
        return Data(base64Encoded: encodedString)
    }

    /// 현재 프로필 기준으로 advertiser를 다시 만드는 메서드
    func rebuildAdvertiser() {
        /// 아직 시작 전이면 객체만 갈아끼우고, 실행 중이면 멈췄다가 다시 시작
        let wasRunning = isRunning

        advertiser.stopAdvertisingPeer()

        let newAdvertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: Self.makeDiscoveryInfo(displayName: myPeerID.displayName, profile: localProfile),
            serviceType: Self.serviceType
        )

        advertiser = newAdvertiser
        advertiser.delegate = self

        if wasRunning {
            advertiser.startAdvertisingPeer()
        }
    }

    /// 새 기기를 추가하거나 기존 기기 정보를 갱신하는 메서드
    func upsertPeer(_ peerID: MCPeerID, discoveryInfo: [String: String]?) {
        let displayName = discoveryInfo?["displayName"] ?? peerID.displayName
        let nickname = discoveryInfo?["nickname"] ?? displayName
        let photoData = Self.decodedThumbnailData(from: discoveryInfo?["thumbnail"])

        let peer = NearbyPeer(
            id: peerID,
            displayName: displayName,
            nickname: nickname,
            photoData: photoData,
            lastSeenAt: Date()
        )

        if let index = nearbyPeers.firstIndex(where: { $0.id == peerID }) {
            nearbyPeers[index] = peer
        } else {
            nearbyPeers.append(peer)
            nearbyPeers.sort { $0.nickname.localizedCaseInsensitiveCompare($1.nickname) == .orderedAscending }
        }

        authorizationState = nearbyPeers.isEmpty ? "주변 CoGo 기기를 찾는 중" : "주변 CoGo 기기 \(nearbyPeers.count)대 발견"
    }

    /// 탐색 범위에서 사라진 기기를 목록에서 제거하는 메서드
    func removePeer(_ peerID: MCPeerID) {
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
        let hostNickname: String

        if
            let context,
            let inviteContext = try? JSONDecoder().decode(GameInviteContext.self, from: context)
        {
            hostNickname = inviteContext.hostNickname
        } else {
            hostNickname = peerID.displayName
        }

        DispatchQueue.main.async {
            self.pendingInvite = PendingGameInvite(
                peerID: peerID,
                hostNickname: hostNickname,
                invitationHandler: invitationHandler
            )
        }
    }

    /// advertise 시작 자체가 실패했을 때 호출
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: any Error) {
        DispatchQueue.main.async {
            self.authorizationState = "advertise 시작 실패: \(error.localizedDescription)"
        }
    }
}

/// 실제 연결 상태 변화를 처리하기 위한 session delegate 구현
extension NearbyDeviceManager: MCSessionDelegate {
    /// 세션에 연결된 피어 상태가 바뀔 때 호출
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.authorizationState = "\(peerID.displayName)와 CoGo 연결 완료"
                self.isGameReady = true
            case .connecting:
                self.authorizationState = "\(peerID.displayName)와 연결 중"
            case .notConnected:
                self.playerRole = nil
                self.authorizationState = "주변 CoGo 기기 탐색 중"
            @unknown default:
                self.authorizationState = "연결 상태를 확인하는 중"
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {}
}
