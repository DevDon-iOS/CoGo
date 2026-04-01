//
//  ContentView.swift
//  CoGo
//
//  Created by 이돈혁 on 3/27/26.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    let cameraManager = CameraManager()
    /// 시트를 띄울지 말지 저장하는 상태값
    /// 값이 바뀌어야 하기 때문에 let이 아닌 var
    /// 기본상태는 false, 버튼을 누르면 true, 시트가 닫히면 다시 false
    @State private var isProfileModalPresented = false
    @State private var isMazeButtonTapped = false
    /// 빨간 점의 현위치를 미로 크기 대비 비율로 저장
    /// mazeSize는 미로 기준판 크기
    @State private var playerXRatio: CGFloat = 155.0 / 300.0
    @State private var playerYRatio: CGFloat = 291.0 / 300.0
    /// 도착지점 상대값
    @State private var goalXRatio: CGFloat = 155.0 / 300.0
    @State private var goalYRatio: CGFloat = 9.0 / 300.0
    /// 미로 기준판 크기
    private let mazeSize: CGFloat = 300.0
    /// 반복 입력용 타이머
    /// 평소엔 nil, 버튼을 길게 누르면 타이머 생성, 손을 떼면 타이머 종료
    @State private var repeatTimer: Timer?
    /// 빨간 점의 크기. 미로이미지 영역 경계 계산을 위함
    private let playerDotSize: CGFloat = 10.0

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
                // AI 사용한 부분
                CameraPreviewView(session: cameraManager.session)
                    .ignoresSafeArea()
                    .blur(radius: isMazeButtonTapped ? 6 : 0)
                
                VStack {
                    Spacer()
                    
                    if !isMazeButtonTapped {
                        Button {
                            isMazeButtonTapped = true
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
        /// 실제로 시트를 연결하는 줄
        .sheet(isPresented: $isProfileModalPresented) {
            ProfileModalView()
                .presentationDetents([.fraction(0.7)])
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
    ContentView()
}
