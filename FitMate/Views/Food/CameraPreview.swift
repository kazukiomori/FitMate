//
//  CameraPreview.swift
//  FitMate
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // 特に更新なし
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        videoPreviewLayer.videoGravity = .resizeAspectFill
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        videoPreviewLayer.videoGravity = .resizeAspectFill
    }
}


