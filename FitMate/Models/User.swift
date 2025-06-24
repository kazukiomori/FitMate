//
//  User.swift
//  FitMate
//

import SwiftUI

class User: ObservableObject {
    @Published var name: String = ""
    @Published var age: Int = 25
    @Published var currentWeight: Double = 70.0
    @Published var targetWeight: Double = 65.0
    @Published var height: Double = 170.0
    @Published var gender: Gender = .female
    @Published var activityLevel: ActivityLevel = .moderate
    @Published var isOnboardingComplete: Bool = false
    
    func calculateDailyCalories() -> Int {
        // 簡易的なBMR計算（Harris-Benedict式）
        let bmr: Double
        if gender == .male {
            bmr = 88.362 + (13.397 * currentWeight) + (4.799 * height) - (5.677 * Double(age))
        } else {
            bmr = 447.593 + (9.247 * currentWeight) + (3.098 * height) - (4.330 * Double(age))
        }
        
        let activityMultiplier: Double
        switch activityLevel {
        case .low: activityMultiplier = 1.2
        case .moderate: activityMultiplier = 1.55
        case .high: activityMultiplier = 1.9
        }
        
        // ダイエット用に500kcal減らす
        return Int(bmr * activityMultiplier - 500)
    }
}
