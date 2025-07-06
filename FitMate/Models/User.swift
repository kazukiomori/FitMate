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
    @Published var targetDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @Published var isOnboardingComplete: Bool = false
    
    // パーソナルトレーナー関連
    @Published var personalTrainer: PersonalTrainer?
    @Published var hasCompletedTrainerSetup: Bool = false
    
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
    
    func calculateWeeklyWeightLoss() -> Double {
        let weightDifference = currentWeight - targetWeight
        let daysDifference = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 84
        let weeksDifference = max(Double(daysDifference) / 7.0, 1.0) // 最低1週間
        
        return min(weightDifference / weeksDifference, 1.0) // 最大週1kg制限
    }
    
    func isGoalRealistic() -> Bool {
        return calculateWeeklyWeightLoss() <= 1.0
    }
    
    func setPersonalTrainer(_ trainer: PersonalTrainer) {
        personalTrainer = trainer
        hasCompletedTrainerSetup = true
    }
}
