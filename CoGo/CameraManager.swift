//
//  CameraManager.swift
//  CoGo
//
//  Created by 이돈혁 on 3/31/26.
//

// swift는 이미 존재. 파일 읽기 / 쓰기, 비동기 처리 등등 꼭 필요한 놈들이지만 swift 자체에는 빠져있는 놈들
import Foundation
import AVFoundation
// 반응형 프로그래밍 프레임워크
import Combine

// ObservableObject를 쓰려면 class만 가능함. ObservableObject라는건 '객체 안의 값이 바뀌면 화면을 다시 그리라고 알려주는 프로토콜'
class CameraManager {
    let session: AVCaptureSession
    
    // 세션에서 카메라 인풋을 만드는 함수
    func makeCameraInput(for position: AVCaptureDevice.Position) throws -> AVCaptureDeviceInput {
        // 만약(guard let) 디바이스에서 후면카메라를 찾았아면, let input 부분으로 넘어가고, 만약 카메라를 찾지 못하면 else {} 내부와 같이 에러처리
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            throw NSError(domain: "CameraManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "카메라를 찾을 수 없습니다"])
        }
        
        let input = try AVCaptureDeviceInput(device: device)
        return input
    }
    
    // 세션을 시작하는 함수(카메라를 실제로 켜는 역할)
    func startRunning() {
        session.startRunning()
    }
    
    // 카메라 인풋을 세션에 붙이는 함수
    func configureSession() {
        session.beginConfiguration()
        do {
            let input = try makeCameraInput(for: .back)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("카메라 인풋 생성 실패: \(error)")
        }
        session.commitConfiguration()
    }
    
    init() {
        session = AVCaptureSession()
        configureSession()
        startRunning()
    }
}
