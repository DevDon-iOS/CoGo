//
//  CollectionView.swift
//  CoGo
//
//  Created by 이돈혁 on 3/27/26.
//

// TODO: 중앙 강조 스케일링 추가 필요
// TODO: 버블 그림자 추가 필요

import SwiftUI

struct CollectionView: View {
    // 임시 코드
    let profiles = ["user_01", "user_02", "user_03", "user_04", "user_05"]
    
    // 드래그 상태값(드래그 이동의 핵심)
    /// @State는 SwiftUI 뷰 내부에서 값이 바뀌고 그 값이 바뀌면 화면도 다시 그려져야 할 때 사용
    /// accumulatedOffset은 드래그가 끝난 뒤 최종 누적 위치
    @State private var accumulatedOffset: CGSize = .zero
    /// dragOffset은 지금 손가락으로 드래그 하고있는 실시간 이동량
    @State private var dragOffset: CGSize = .zero
    /// 기본상태는 isProfileModalPresented = false, 버블 터치시 true로 바뀌며 모달이 호출됨
    @State private var isProfileModalPresented = false
    
    // 레이아웃 설정값
    /// 버블의 크기
    private let bubbleSize: CGFloat = 44
    /// 버블 간 간격
    private let horizontalSpacing: CGFloat = 24
    private let verticalSpacing: CGFloat = 24
    /// 버블을 몇 줄 만들 것인지
    private let rowCount: Int = 10
    private let columnCount: Int = 10
    /// 계산 프로퍼티
    /// 필요할 때마다 게산해 [BubbleItem] 배열을 생성
    private var bubbleItems: [BubbleItem] {
        /// 0부터 99까지 반복해 버블 100개를 만드는 부분
        /// index는 버블 번호
        (0..<(rowCount * columnCount)).map { index in
            BubbleItem(
                id: index,
                imageName: profiles[index % profiles.count],
                row: index / columnCount,
                column: index % columnCount
            )
        }
    }
    
    var body: some View {
        /// 전체 화면의 크기를 읽기 위해 사용
        GeometryReader { geometry in
            /// 전체 버블 묶음 크기를 계산
            let totalWidth = CGFloat(columnCount) * bubbleSize + CGFloat(columnCount - 1) * horizontalSpacing
            let totalHeight = CGFloat(rowCount) * bubbleSize + CGFloat(rowCount - 1) * verticalSpacing
            /// 전체 버블 묶음의 시작점을 중앙 기준으로 맞추는 계산
            let startX = geometry.size.width / 2 - totalWidth / 2
            let startY = geometry.size.height / 2 - totalHeight / 2
            
            ZStack {
                /// 투명한 배경
                Color.clear
                
                /// bubbleItems 배열을 하나씩 돌면서 버블을 생성
                ForEach(bubbleItems) { item in
                    ProfileCellView(imageName: item.imageName)
                        .frame(width: bubbleSize, height: bubbleSize)
                        /// 버블 좌표 계산
                        .position(
                            /// x좌표
                            /// startX: 전체 버블 묶음 시작 x좌표
                            x: startX
                                /// 몇 번째 칸인지에 따라 가로로 이동(기본 격자 위치 계산)
                                + CGFloat(item.column) * (bubbleSize + horizontalSpacing)
                                /// 격자모양을 유지하기 위해 반지름만큼 x좌표를 이동시킴
                                + bubbleSize / 2
                                /// 짝수 줄이면 그대로, 홀수 줄이면 반 칸 밀어줌
                                + (item.row.isMultiple(of: 2) ? 0 : (bubbleSize + horizontalSpacing) / 2),
                            y: startY
                                + CGFloat(item.row) * (bubbleSize + verticalSpacing)
                                + bubbleSize / 2
                        )
                        .onTapGesture {
                            isProfileModalPresented = true
                        }
                }
            }
            /// 전체 버블 묶음을 움직임
            .offset(
                x: accumulatedOffset.width + dragOffset.width,
                y: accumulatedOffset.height + dragOffset.height
            )
            /// 터치 영역 지정
            .contentShape(Rectangle())
            /// 손가락 드래그를 받음
            .gesture(
                DragGesture()
                    /// 손가락을 움직이는 동안 계속 호출됨
                    /// 드래그 시작점 기준으로 얼마나 움직였는지 계산 후 그 값을 dragOffset에 넣음
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    /// 드래그 종료
                    /// 손가락을 떼는 순간 호출됨
                    .onEnded { value in
                        /// 지금까지 이동한 양을 누적값에 더함
                        accumulatedOffset.width += value.translation.width
                        accumulatedOffset.height += value.translation.height
                        /// 실시간 드래그 값은 초기화(이미 이동한 값은 누적값으로 저장됐기 때문)
                        dragOffset = .zero
                    }
            )
            /// 가능한 한 부모 뷰 크기를 꽉 채움
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            /// 버블 군집을 드래그하다가 화면 밖으로 나간 부분을 자름
            .clipped()
        }
        .sheet(isPresented: $isProfileModalPresented) {
            ProfileModalView()
                .presentationDetents([.fraction(0.7)])
        }
    }
}

/// 버블 하나를 표현하는 간단한 데이터 모델
struct BubbleItem: Identifiable {
    let id: Int
    let imageName: String
    let row: Int
    let column: Int
}

// MARK: - preview

#Preview {
    CollectionView()
}
