//
//  Camera.swift
//  FitMate
//
import Foundation
import AVFoundation
import UIKit

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    
    private var onCapture: ((UIImage?) -> Void)?
    
    override init() {
        super.init()
    }
    
    func configure() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
        session.startRunning()
    }
    
    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    func capturePhoto(onCapture: @escaping (UIImage?) -> Void) {
        self.onCapture = onCapture
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            onCapture?(nil)
            onCapture = nil
            return
        }
        
        onCapture?(image)  // ★ フル画像そのまま返す
        onCapture = nil
    }
}

