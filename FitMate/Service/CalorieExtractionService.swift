//
//  CalorieExtractionService.swift
//  FitMate
//

import Foundation

final class CalorieExtractionService {
    func extractCalories(from text: String) -> Int? {
        let pattern = #"(\d+)\s*(kcal|カロリー)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern,
                                                   options: [.caseInsensitive]) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range),
           match.numberOfRanges >= 2,
           let numberRange = Range(match.range(at: 1), in: text) {
            let numberString = String(text[numberRange])
            return Int(numberString)
        }
        return nil
    }
}

