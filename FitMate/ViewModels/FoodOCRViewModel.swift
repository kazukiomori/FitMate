//
//  FoodOCRViewModel.swift
//  FitMate
//

import SwiftUI
import UIKit

@MainActor
final class FoodOCRViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var recognizedText: String = ""
    @Published var calorieValue: Int?
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    
    private let ocrService = VisionTextRecognitionService()
    private let calorieService = CalorieExtractionService()
    
    func analyze(image: UIImage) {
        Task {
            isProcessing = true
            errorMessage = nil
            recognizedText = ""
            calorieValue = nil
            capturedImage = image
            
            do {
                let text = try await ocrService.recognizeText(in: image)
                recognizedText = text
                calorieValue = calorieService.extractCalories(from: text)
            } catch {
                errorMessage = "テキスト認識に失敗しました: \(error.localizedDescription)"
            }
            
            isProcessing = false
        }
    }
}

