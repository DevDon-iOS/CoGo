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
    let profiles: [BubbleProfile] = [
        BubbleProfile(id: 0, imageName: "user_01", name: "남기하", nickname: "Kei"),
        BubbleProfile(id: 1, imageName: "user_02", name: "최봉권", nickname: "BK"),
        BubbleProfile(id: 2, imageName: "user_03", name: "오효준", nickname: "Asher"),
        BubbleProfile(id: 3, imageName: "user_04", name: "류세환", nickname: "Shayne"),
        BubbleProfile(id: 4, imageName: "user_05", name: "김현일", nickname: "링쿠")
    ]
    
    // 드래그 상태값(드래그 이동의 핵심)
    /// @State는 SwiftUI 뷰 내부에서 값이 바뀌고 그 값이 바뀌면 화면도 다시 그려져야 할 때 사용
    /// accumulatedOffset은 드래그가 끝난 뒤 최종 누적 위치
    @State private var accumulatedOffset: CGSize = .zero
    /// dragOffset은 지금 손가락으로 드래그 하고있는 실시간 이동량
    @State private var dragOffset: CGSize = .zero
    /// 어떤 프로필을 선택했는지 체크
    @State private var selectedProfile: BubbleProfile?
    
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
                profile: profiles[index % profiles.count],
                row: index / columnCount,
                column: index % columnCount
            )
        }
    }
    
    /// 전체 버블 군집의 가로 길이를 계산하는 함수
    /// 반환값은 CGFloat
    /// CGFloat란 화면상의 좌표, 너비, 높이 등 그래픽 요소의 수치를 다룰 때 사용하는 실수형 데이터 타입
    private func totalWidth() -> CGFloat {
        /// 버블 너비 합산 + 버블 사이 간격 합산
        CGFloat(columnCount) * bubbleSize + CGFloat(columnCount - 1) * horizontalSpacing
    }
    
    private func totalHeight() -> CGFloat {
        CGFloat(rowCount) * bubbleSize + CGFloat(rowCount - 1) * verticalSpacing
    }
    
    /// 화면 내 버블이 있어야 할 좌표를 계산해 CGPoint로 반환
    /// CGPoint는 특정한 점의 위치를 나타내는 구조체
    /// CGFloat 2개가 모여 하나의 점을 만들어냄(x좌표, y좌표)
    private func bubblePosition(for item: BubbleItem, in geometry: GeometryProxy) -> CGPoint {
        /// 전체 버블 군집 시작점을 화면 중심 기준으로 맞춤
        /// 화면 가로/세로 중앙 - 전체 폭/높이의 절반
        let startX = geometry.size.width / 2 - totalWidth() / 2
        let startY = geometry.size.height / 2 - totalHeight() / 2
        
        /// 현재 버블의 가로 위치를 계산
        let x = startX
        + CGFloat(item.column) * (bubbleSize + horizontalSpacing)
        + bubbleSize / 2
        /// 홀수 줄이면 반 칸 오른쪽으로 밀어 대각선 배열 만들기
        + (item.row.isMultiple(of: 2) ? 0: (bubbleSize + horizontalSpacing) / 2)
        
        let y = startY
        + CGFloat(item.row) * (bubbleSize + verticalSpacing)
        + bubbleSize / 2
        
        /// 결국 버블 하나의 위치를 점 하나로 반환
        return CGPoint(x: x, y: y)
    }
    
    var body: some View {

// MARK: - 타입추론 에러 해결을 위해 body 내 계산을 상단의 별도 함수로 이동
        
//        /// 전체 화면의 크기를 읽기 위해 사용
        GeometryReader { geometry in
//            /// 전체 버블 묶음 크기를 계산
//            let totalWidth = CGFloat(columnCount) * bubbleSize + CGFloat(columnCount - 1) * horizontalSpacing
//            let totalHeight = CGFloat(rowCount) * bubbleSize + CGFloat(rowCount - 1) * verticalSpacing
//            /// 전체 버블 묶음의 시작점을 중앙 기준으로 맞추는 계산
//            let startX = geometry.size.width / 2 - totalWidth / 2
//            let startY = geometry.size.height / 2 - totalHeight / 2
//            
            ZStack {
                
                /// bubbleItems 배열을 하나씩 돌면서 버블을 생성
                ForEach(bubbleItems) { item in
                    // MARK: - 타입추론 에러 해결을 위해 body 내 계산을 상단의 별도 함수로 이동
                    
//                    /// 현재 버블의 가로위치 계산 시작점
//                    let x = startX
//                        /// 가로로 몇 칸 이동할지 계산하는 부분
//                        + CGFloat(item.column) * (bubbleSize + horizontalSpacing)
//                        /// 버블의 중심 좌표 보정
//                        + bubbleSize / 2
//                        + (item.row.isMultiple(of: 2) ? 0 : (bubbleSize + horizontalSpacing) / 2)
//
//                    let y = startY
//                        + CGFloat(item.row) * (bubbleSize + verticalSpacing)
//                        + bubbleSize / 2
                    let position = bubblePosition(for: item, in: geometry)
                    
                    ProfileCellView(imageName: item.profile.imageName)
                        .frame(width: bubbleSize, height: bubbleSize)
                        .position(position)
                        .onTapGesture {
                            selectedProfile = item.profile
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
        .sheet(item: $selectedProfile) { profile in
            ProfileModalView(
                imageName: profile.imageName,
                name: profile.name,
                nickName: profile.nickname
                )
                .presentationDetents([.fraction(0.7)])
        }
    }
}

/// 버블 안 사람의 정보
struct BubbleProfile: Identifiable {
    let id: Int
    let imageName: String
    let name: String
    let nickname: String
}

/// 버블 하나를 표현하는 간단한 데이터 모델
struct BubbleItem: Identifiable {
    let id: Int
    let profile: BubbleProfile
    let row: Int
    let column: Int
}

// MARK: - preview

#Preview {
    CollectionView()
}
