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

    // MARK: - Calories (Mifflin-St Jeor)

    /// BMR（基礎代謝）: Mifflin-St Jeor式
    /// - 男性: 10W + 6.25H - 5A + 5
    /// - 女性: 10W + 6.25H - 5A - 161
    /// - W: kg, H: cm, A: years
    func calculateBMRMifflinStJeor() -> Int {
        let weight = currentWeight
        let heightCm = height
        let ageYears = Double(age)

        let base = (10.0 * weight) + (6.25 * heightCm) - (5.0 * ageYears)
        let sexConstant: Double = (gender == .male) ? 5.0 : -161.0
        return Int((base + sexConstant).rounded())
    }

    /// TDEE（総消費カロリー）: BMR × 活動係数
    /// - 少なめ: 1.25 / 普通: 1.50 / 活発: 1.75
    func calculateTDEEMifflinStJeor() -> Int {
        let bmr = Double(calculateBMRMifflinStJeor())
        return Int((bmr * activityFactor).rounded())
    }

    /// 活動係数（TDEE用）
    var activityFactor: Double {
        switch activityLevel {
        case .low: return 1.25
        case .moderate: return 1.50
        case .high: return 1.75
        }
    }
    
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
