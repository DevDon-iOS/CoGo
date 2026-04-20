//
//  CollectionView.swift
//  CoGo
//
//  Created by 이돈혁 on 3/27/26.
//

import SwiftUI

struct CollectionView: View {
    // 드래그 상태값(드래그 이동의 핵심)
    /// @State는 SwiftUI 뷰 내부에서 값이 바뀌고 그 값이 바뀌면 화면도 다시 그려져야 할 때 사용
    /// accumulatedOffset은 드래그가 끝난 뒤 최종 누적 위치
    @State private var accumulatedOffset: CGSize = .zero
    /// dragOffset은 지금 손가락으로 드래그 하고있는 실시간 이동량
    @State private var dragOffset: CGSize = .zero
    /// 안내 문구 시트를 띄울지 말지 저장하는 상태값
    @State private var isIntroSheetPresented = false
    /// 현재 확대/축소 배율 (기본값 1.0)
    @State private var scale: CGFloat = 1.0
    /// 핀치 중 실시간 배율 변화
    @State private var gestureScale: CGFloat = 1.0

    // 레이아웃 설정값
    /// 초기 상태에서 보여줄 검은 원의 지름
    private let centerCircleSize: CGFloat = 150

    var body: some View {
        GeometryReader { _ in
            ZStack {
                /// 앱의 초기 상태에서는 화면 가운데 검은 원 하나만 표시
                Circle()
                    .fill(Color.black)
                    /// spread 값을 완전히 같게 만들 수는 없어서 바깥 링을 얇게 추가해 비슷한 두께감 보정
                    .overlay {
                        Circle()
                            .stroke(Color.black.opacity(0.08), lineWidth: 8)
                            .blur(radius: 1)
                    }
                    .frame(width: centerCircleSize, height: centerCircleSize)
                    /// Figma 값 기준: x 0, y 5, blur 10, color #000000 27%
                    .shadow(color: Color.black.opacity(0.27), radius: 10, x: 0, y: 5)
                    .onTapGesture {
                        isIntroSheetPresented = true
                    }
            }
            /// 검은 원이 손가락 움직임에 따라 같이 반응
            .offset(
                x: accumulatedOffset.width + dragOffset.width,
                y: accumulatedOffset.height + dragOffset.height
            )
            .scaleEffect(scale * gestureScale)
            /// 화면 전체 어디서든 제스처가 잘 잡히도록 터치 영역 지정
            .contentShape(Rectangle())
            /// 핀치 + 드래그 동시에 가능하도록 설정
            .gesture(
                SimultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            accumulatedOffset.width += value.translation.width
                            accumulatedOffset.height += value.translation.height
                            dragOffset = .zero
                        },
                    MagnificationGesture()
                        .onChanged { value in
                            /// value는 1.0 기준
                            gestureScale = value
                        }
                        .onEnded { value in
                            let newScale = scale * value
                            /// 지나치게 커지거나 작아지지 않도록 범위 제한
                            scale = min(max(newScale, 0.7), 1.3)
                            gestureScale = 1.0
                        }
                )
            )
            /// 가능한 한 부모 뷰 크기를 꽉 채움
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .sheet(isPresented: $isIntroSheetPresented) {
            VStack(spacing: 20) {
                Text("새로운 친구와 CoGo를 플레이하고 친구의 프로필을 모아 보세요")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .presentationDetents([.fraction(0.3)])
        }
    }
}

// MARK: - preview

#Preview {
    CollectionView()
}
