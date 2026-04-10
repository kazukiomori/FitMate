import SwiftUI
import AVFoundation
import UIKit

struct LiveCameraOCRView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraModel = CameraModel()
    @ObservedObject var viewModel: FoodOCRViewModel   // 外から注入

    private let ocrService = VisionTextRecognitionService()
    private let calorieService = CalorieExtractionService()
    private let guideRegionOfInterest = CGRect(x: 0.16, y: 0.40, width: 0.68, height: 0.19)

    @State private var isAnalyzingFrame = false
    @State private var lastAnalysisDate: Date = .distantPast
    
    var body: some View {
        ZStack {
            CameraPreview(session: cameraModel.session)
                .ignoresSafeArea()
                .onAppear {
                    cameraModel.onFrame = { cgImage in
                        handleIncomingFrame(cgImage)
                    }
                    cameraModel.configure()
                }
                .onDisappear {
                    cameraModel.onFrame = nil
                    cameraModel.stopSession()
                }
            
            VStack {
                HStack {
                    Spacer()

                    Button("閉じる") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
                .padding(.horizontal)
                .padding(.top, 12)

                Spacer()

                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 260, height: 160)
                        .overlay(
                            Text("カロリー表示を枠内に合わせてください")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.35))
                                .clipShape(Capsule())
                                .offset(y: 118)
                        )

                    if viewModel.isProcessing {
                        HStack {
                            ProgressView()
                            Text("解析中...")
                                .foregroundColor(.white)
                                .bold()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Capsule())
                    } else {
                        Text("枠に合わせると自動で解析します")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.35))
                            .clipShape(Capsule())

                        if let kcal = viewModel.calorieValue {
                            Text("\(kcal) kcal を検出しました")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.orange.opacity(0.85))
                                .clipShape(Capsule())
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.white)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.7))
                                .clipShape(Capsule())
                        }
                    }
                }
                Spacer()

                Color.clear.frame(height: 20)
            }
        }
    }

    private func handleIncomingFrame(_ cgImage: CGImage) {
        Task {
            let shouldAnalyze = await MainActor.run { () -> Bool in
                let now = Date()
                guard !isAnalyzingFrame,
                      !viewModel.isProcessing,
                      viewModel.calorieValue == nil,
                      now.timeIntervalSince(lastAnalysisDate) > 0.7 else { return false }

                isAnalyzingFrame = true
                lastAnalysisDate = now
                viewModel.isProcessing = true
                viewModel.errorMessage = nil
                return true
            }

            guard shouldAnalyze else { return }

            defer {
                Task { @MainActor in
                    self.isAnalyzingFrame = false
                    self.viewModel.isProcessing = false
                }
            }

            do {
                let text = try await ocrService.recognizeText(in: cgImage, regionOfInterest: guideRegionOfInterest)
                let detectedCalories = calorieService.extractCalories(from: text)

                await MainActor.run {
                    viewModel.recognizedText = text
                    if let detectedCalories {
                        viewModel.calorieValue = detectedCalories
                    }
                }
            } catch {
                await MainActor.run {
                    if viewModel.calorieValue == nil {
                        viewModel.recognizedText = ""
                    }
                }
            }
        }
    }
}

