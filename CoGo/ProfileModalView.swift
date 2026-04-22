//
//  ProfileModalView.swift
//  CoGo
//
//  Created by 이돈혁 on 4/1/26.
//

import SwiftUI
import PhotosUI

struct ProfileModalView: View {
    /// 읽기 전용으로 보여줄 상대 프로필
    private let displayProfile: Profile?
    /// 앱 전역에 저장된 사용자 프로필
    @EnvironmentObject private var profileStore: ProfileStore
    /// 현재 시트를 닫기 위한 환경값
    @Environment(\.dismiss) private var dismiss
    /// 선택한 포토 피커 항목을 임시로 저장
    @State private var selectedPhotoItem: PhotosPickerItem?
    /// 이름 입력 필드 상태값
    @State private var name: String = ""
    /// 닉네임 입력 필드 상태값
    @State private var nickname: String = ""
    /// 선택한 사진 데이터를 메모리에 보관
    @State private var photoData: Data?

    /// 내 프로필을 편집하는 기본 초기화
    init() {
        self.displayProfile = nil
    }

    /// 상대 프로필을 읽기 전용으로 보여주는 초기화
    init(displayProfile: Profile) {
        self.displayProfile = displayProfile
    }

    /// 저장 버튼을 눌렀을 때 활성화 가능한지 판단
    private var isSaveButtonEnabled: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 16) {
            if displayProfile == nil {
                /// 프로필 사진을 선택하거나 현재 사진을 보여주는 영역
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    profileImageSection
                }

                /// 이름 입력 필드
                TextField("이름을 입력하세요", text: $name)
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

                /// 닉네임 입력 필드
                TextField("닉네임을 입력하세요", text: $nickname)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

                /// 저장 버튼
                Button {
                    profileStore.saveProfile(name: name, nickname: nickname, photoData: photoData)
                    dismiss()
                } label: {
                    Text("내 정보 저장")
                        .foregroundColor(.white)
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isSaveButtonEnabled ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isSaveButtonEnabled)

                /// 입력값을 모두 비우는 초기화 버튼
                Button {
                    profileStore.resetProfile()
                    syncForm(with: .empty)
                } label: {
                    Text("초기화")
                        .foregroundStyle(.red)
                }
            } else {
                /// 상대 프로필은 읽기 전용으로 표시
                profileImageSection

                Text(name)
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

                Text(nickname)
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 24)
        /// 시트가 처음 열릴 때 저장된 프로필을 입력창에 반영
        .onAppear {
            if let displayProfile {
                syncForm(with: displayProfile)
            } else {
                syncForm(with: profileStore.profile)
            }
        }
        /// 사용자가 새 사진을 고르면 Data로 읽어옴
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                photoData = try? await newItem?.loadTransferable(type: Data.self)
            }
        }
    }
}

private extension ProfileModalView {
    /// 사진 영역 공통 UI
    var profileImageSection: some View {
        ZStack {
            /// 저장된 사진 데이터가 있으면 실제 이미지 표시
            if let uiImage = profileImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                /// 아직 사진이 없으면 기본 플레이스홀더 표시
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .overlay {
                        Image(systemName: displayProfile == nil ? "person.crop.circle.fill.badge.plus" : "person.crop.circle")
                            .font(.system(size: 44))
                            .foregroundStyle(.gray)
                    }
            }
        }
        .frame(width: 160, height: 160)
        .clipShape(Circle())
    }

    /// 현재 photoData를 실제 UIImage로 바꿔주는 계산 프로퍼티
    var profileImage: UIImage? {
        guard let photoData else { return nil }
        return UIImage(data: photoData)
    }

    /// 저장소의 프로필 값을 입력 폼 상태값에 복사
    func syncForm(with profile: Profile) {
        name = profile.name
        nickname = profile.nickname
        photoData = profile.photoData
    }
}
