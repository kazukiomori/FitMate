//
//  VisionTextRecognitionService.swift
//  FitMate
//

import Foundation
import Vision
import UIKit

final class VisionTextRecognitionService {
    enum OCRServiceError: Error {
        case cgImageMissing
        case noText
    }
    
    func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRServiceError.cgImageMissing
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRServiceError.noText)
                    return
                }
                
                let strings = observations.compactMap {
                    $0.topCandidates(1).first?.string
                }
                let fullText = strings
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                continuation.resume(returning: fullText)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.revision = VNRecognizeTextRequestRevision3
            request.automaticallyDetectsLanguage = false
            request.recognitionLanguages = ["ja-JP", "en-US"]
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
