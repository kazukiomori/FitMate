import SwiftUI
import AVFoundation
import UIKit

struct LiveCameraOCRView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraModel = CameraModel()
    @ObservedObject var viewModel: FoodOCRViewModel   // 外から注入
    
    var body: some View {
        ZStack {
            // カメラプレビュー
            CameraPreview(session: cameraModel.session)
                .ignoresSafeArea()
                .onAppear {
                    cameraModel.configure()
                }
                .onDisappear {
                    cameraModel.stopSession()
                }
            
            // 黄色のガイド枠（目安として残す）
            GeometryReader { geo in
                let guideRect = CGRect(
                    x: geo.size.width * 0.1,
                    y: geo.size.height * 0.3,
                    width: geo.size.width * 0.8,
                    height: geo.size.height * 0.2
                )
                Path { path in
                    path.addRect(guideRect)
                }
                .stroke(Color.yellow, lineWidth: 3)
            }
            .allowsHitTesting(false)
            
            VStack {
                Spacer()
                
                // 撮影した画像のプレビュー
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                }
                
                // 認識テキスト & カロリー表示
                VStack(alignment: .leading) {
                    if viewModel.isProcessing {
                        HStack {
                            ProgressView()
                            Text("解析中...")
                                .foregroundColor(.yellow)
                                .bold()
                        }
                        .padding(.bottom, 8)
                    } else {
                        if !viewModel.recognizedText.isEmpty {
                            Text("認識テキスト:")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            ScrollView {
                                Text(viewModel.recognizedText)
                                    .padding(.bottom, 4)
                            }
                            .frame(maxHeight: 100)
                            
                            if let kcal = viewModel.calorieValue {
                                Text("抽出カロリー: \(kcal) kcal")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                    .padding(.bottom, 8)
                            }
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.bottom, 8)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // 撮影＋解析ボタン
                Button(action: {
                    guard !viewModel.isProcessing else { return }
                    cameraModel.capturePhoto { image in
                        guard let image = image else { return }
                        viewModel.analyze(image: image)
                    }
                }) {
                    Text("解析する")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isProcessing ? Color.gray : Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(viewModel.isProcessing)
                .padding(.bottom, 8)
                
                // 閉じるボタン（任意）
                Button("閉じる") {
                    dismiss()
                }
                .foregroundColor(.white)
                .padding(.bottom, 20)
            }
        }
    }
}

