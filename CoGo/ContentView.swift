//
//  HomeView.swift
//  CoGo
//
//  Created by 이돈혁 on 3/27/26.
//

import SwiftUI
import AVFoundation

struct HomeView: View {
    /// 앱 전역에서 저장하는 사용자 프로필 정보
    @EnvironmentObject private var profileStore: ProfileStore
    let cameraManager = CameraManager()
    /// 주변 CoGo 기기 목록을 홈뷰에서 구독하기 위한 상태 객체
    @StateObject private var nearbyDeviceManager = NearbyDeviceManager()
    /// 시트를 띄울지 말지 저장하는 상태값
    /// 값이 바뀌어야 하기 때문에 let이 아닌 var
    /// 기본상태는 false, 버튼을 누르면 true, 시트가 닫히면 다시 false
    @State private var isProfileModalPresented = false
    @State private var isMazeButtonTapped = false
    @State private var isBumpModalPresented = false
    /// 빨간 점의 현위치를 미로 크기 대비 비율로 저장
    /// mazeSize는 미로 기준판 크기
    @State private var playerXRatio: CGFloat = 155.0 / 300.0
    @State private var playerYRatio: CGFloat = 291.0 / 300.0
    /// 도착지점 상대값
    @State private var goalXRatio: CGFloat = 142.0 / 300.0
    @State private var goalYRatio: CGFloat = 9.0 / 300.0
    /// 미로 기준판 크기
    private let mazeSize: CGFloat = 300.0
    /// 반복 입력용 타이머
    /// 평소엔 nil, 버튼을 길게 누르면 타이머 생성, 손을 떼면 타이머 종료
    @State private var repeatTimer: Timer?
    /// 빨간 점의 크기. 미로이미지 영역 경계 계산을 위함
    private let playerDotSize: CGFloat = 10.0
    /// 도착 판정 오차범위
    private let goalTolerance: CGFloat = 0.02

    /// 카메라 화면 위에 겹쳐 보여줄 주변 기기 패널
    private var nearbyPeerSection: some View {
        /// 제목, 상태 문구, 목록을 세로로 배치
        VStack(alignment: .leading, spacing: 12) {
            Text("내 주변 CoGo")
                .font(.headline)
                .foregroundStyle(.white)

            /// 탐색 상태를 실시간으로 보여주는 문구
            Text(nearbyDeviceManager.authorizationState)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))

            /// 아직 발견한 기기가 없으면 안내 문구 표시
            if nearbyDeviceManager.nearbyPeers.isEmpty {
                Text("같은 네트워크 권한을 허용한 CoGo 사용자가 근처에 있으면 여기에 나타납니다.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            } else {
                /// 여러 기기를 한 줄로 넘겨 보도록 가로 스크롤 사용
                ScrollView(.horizontal, showsIndicators: false) {
                    /// 각 기기 카드를 가로로 나열
                    HStack(spacing: 12) {
                        /// 발견한 기기 배열을 하나씩 순회
                        ForEach(nearbyDeviceManager.nearbyPeers) { peer in
                            /// 기기 카드 안의 원형 아이콘과 텍스트를 세로로 배치
                            VStack(alignment: .leading, spacing: 8) {
                                /// 프로필 이미지가 없으므로 기기 표시용 원형 배지 사용
                                Circle()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        /// 기기 이름 첫 글자를 이니셜처럼 표시
                                        Text(String(peer.displayName.prefix(1)).uppercased())
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                    }

                                /// 발견한 기기의 이름 표시
                                Text(peer.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)

                                /// 마지막 발견 시각을 상대 시간 형식으로 표시
                                Text(peer.lastSeenAt, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                            /// 카드 폭과 배경 스타일
                            .frame(width: 132, alignment: .leading)
                            .padding(12)
                            .background(Color.black.opacity(0.32))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                }
            }
        }
        /// 패널 전체 여백과 배경 스타일 지정
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.38))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    /// 빨간 점을 dx, dy만큼 움직이되 미로 밖으로 나가지 못하게 막는 함수
    private func movePlayer(dx: CGFloat, dy: CGFloat) {
        /// 경계 제한
        let minRatio = (playerDotSize / 2) / mazeSize
        let maxRatio = 1 - minRatio
        
        /// 입력으로 인해 이동한 뒤의 위치
        let nextX = playerXRatio + dx
        let nextY = playerYRatio + dy
        
        /// 제한 로직(최소보다 작아질 수 없고, 최대보다 커질 수 없음)
        playerXRatio = min(max(nextX, minRatio), maxRatio)
        playerYRatio = min(max(nextY, minRatio), maxRatio)
        /// 사용자가 버튼을 눌러 움직일 때마다 도착 검사
        checkGoalReached()
    }
    
    /// 플레이어가 도착점에 도달했는지 검사하는 함수
    /// abs는 절댓값. 플레이어가 목표보다 왼쪽이든 오른쪽이든 차이의 크기만 확인하면 되기 때문
    private func checkGoalReached() {
        let isGoalXMatched = abs(playerXRatio - goalXRatio) <= goalTolerance
        let isGoalYMatched = abs(playerYRatio - goalYRatio) <= goalTolerance
        
        /// x도 맞고 y도 맞아야 성공처리
        if isGoalXMatched && isGoalYMatched {
            /// 길게 누르는 도중 도착했으면 타이머가 켜져있을 수 있으니 도착 즉시 반복입력 중단
            stopRepeatingMove()
            isBumpModalPresented = true
        }
    }
    /// 버튼을 길게 누르고있을 때 반복이동을 시작하는 함수
    /// 기존 타이머를 끔(새 타이머 시작 전 기존 타이머를 정리)
    private func startRepeatingMove(dx: CGFloat, dy: CGFloat, step: CGFloat) {
        stopRepeatingMove()
        repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            movePlayer(dx: dx * step, dy: dy * step)
        }
    }
    
    /// 반복입력 종료 함수
    /// 타이머 멈춤, 상태 초기화
    private func stopRepeatingMove() {
        repeatTimer?.invalidate()
        repeatTimer = nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - AI 사용한 부분
                
                CameraPreviewView(session: cameraManager.session)
                    .ignoresSafeArea()
                    .blur(radius: isMazeButtonTapped ? 6 : 0)
                
                VStack {
                    Spacer()
                    
                    if !isMazeButtonTapped {
                        Button {
                            isMazeButtonTapped = true
                            isBumpModalPresented = false
                            playerXRatio = 155.0/300.0
                            playerYRatio = 291.0/300.0
                            
                        } label: {
                            Text("랜덤 미로 생성")
                                .font(Font.body.bold())
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                                .padding(.top, 28)
                        }
                        .padding(24)
                    }
                }
                /// 홈뷰 상단 안전 영역 안에 주변 기기 패널 배치
                .safeAreaInset(edge: .top) {
                    nearbyPeerSection
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            isProfileModalPresented = true
                        } label: {
                            Image(systemName: "person.crop.circle")
                        }
                    }
                }
                
                /// 미로 생성 버튼이 눌리면 버튼이 보이지 않도
                if isMazeButtonTapped {
                    Color.black.opacity(0.18)
                        .ignoresSafeArea()
                        /// 배경을 탭하면 미로가 닫히고 타이머가 종료됨
                        .onTapGesture {
                            stopRepeatingMove()
                            isMazeButtonTapped = false
                            isBumpModalPresented = false
                        }
                    
                    /// playerX, playerY는 실제 화면 좌표
                    /// step은 화살표 한번 누를때 이동하는 비율
                    let playerX = mazeSize * playerXRatio
                    let playerY = mazeSize * playerYRatio
                    /// 목표점 좌표 계산
                    let goalX = mazeSize * goalXRatio
                    let goalY = mazeSize * goalYRatio
                    let playerDotSize: CGFloat = 10
                    let step: CGFloat = 0.01
                    
                    VStack {
                        ZStack {
                            Image("Maze_example")
                                .resizable()
                                .scaledToFit()
                                /// 프레임 크기를 mazeSize로 고정
                                .frame(width: mazeSize, height: mazeSize)
                            
                            Circle()
                                .fill(.blue)
                                .frame(width: playerDotSize, height: playerDotSize)
                                .position(x: goalX, y: goalY)
                            
                            Circle()
                                .fill(.red)
                                .frame(width: playerDotSize, height: playerDotSize)
                                .position(x: playerX, y: playerY)
                        }
                        .frame(width: mazeSize, height: mazeSize)
                        .padding(.bottom, 40)
                        
                        HStack(spacing: 24) {
                            Button {
                                movePlayer(dx: -step, dy: 0)
                            } label: {
                                Image(systemName: "arrow.left.circle.fill")
                                    .font(.system(size: 36))
                            }
                            .onLongPressGesture(minimumDuration: 0.2, pressing: { isPressing in
                                if isPressing {
                                    startRepeatingMove(dx: -1, dy: 0, step: step)
                                } else {
                                    stopRepeatingMove()
                                }
                            }, perform: {})
                            
                            Button {
                                movePlayer(dx: step, dy: 0)
                            } label: {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 36))
                            }
                            .onLongPressGesture(minimumDuration: 0.2, pressing: { isPressing in
                                if isPressing {
                                    startRepeatingMove(dx: 1, dy: 0, step: step)
                                } else {
                                    stopRepeatingMove()
                                }
                            }, perform: {})
                            
                            Button {
                                movePlayer(dx: 0, dy: -step)
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 36))
                            }
                            .onLongPressGesture(minimumDuration: 0.2, pressing: { isPressing in
                                if isPressing {
                                    startRepeatingMove(dx: 0, dy: -1, step: step)
                                } else {
                                    stopRepeatingMove()
                                }
                            }, perform: {})
                            
                            Button {
                                movePlayer(dx: 0, dy: step)
                            } label: {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 36))
                            }
                            .onLongPressGesture(minimumDuration: 0.2, pressing: { isPressing in
                                if isPressing {
                                    startRepeatingMove(dx: 0, dy: 1, step: step)
                                } else {
                                    stopRepeatingMove()
                                }
                            }, perform: {})
                        }
                    }
                    .padding(24)
                    .onDisappear {
                        stopRepeatingMove()
                    }
                    
                }
            }
        }
        /// 홈뷰가 나타나면 주변 기기 탐색 시작
        .onAppear {
            nearbyDeviceManager.start()
        }
        /// 홈뷰가 사라지면 불필요한 탐색 중단
        .onDisappear {
            nearbyDeviceManager.stop()
        }
        /// 실제로 시트를 연결하는 줄
        .sheet(isPresented: $isProfileModalPresented) {
            ProfileModalView()
                .environmentObject(profileStore)
            .presentationDetents([.fraction(0.7)])
        }
        .sheet(isPresented: $isBumpModalPresented) {
            BumpModalView {
                isBumpModalPresented = false
                isMazeButtonTapped = false
            }
            .presentationDetents([.fraction(0.35)])
            /// 잡고 드래그할 수 있는 인디케이터
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - AI 사용한 부분

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.previewLayer.session = session
    }
}

final class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Camera preview layer cast failed")
        }
        return layer
    }
}

// MARK: - preview

#Preview {
    HomeView()
}
