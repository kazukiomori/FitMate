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
    
    func calculateDailyCalories(maintenanceCalories: Int) -> Int {
        // (現在体重 - 目標体重) * 7700kcal を総赤字として、期限までの日数で割り、
        // その1日赤字分を「維持カロリー（実測/推定）」から差し引いて目標摂取カロリーを出す
        let maintenance = Double(maintenanceCalories)

        let weightToLoseKg = max(currentWeight - targetWeight, 0)
        guard weightToLoseKg > 0 else {
            return Int(maintenance.rounded())
        }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: targetDate)
        let daysRemaining = max(calendar.dateComponents([.day], from: start, to: end).day ?? 0, 1)

        let totalDeficitKcal = weightToLoseKg * 7700.0
        let dailyDeficitKcal = totalDeficitKcal / Double(daysRemaining)

        let targetIntake = max(maintenance - dailyDeficitKcal, 0)
        return Int(targetIntake.rounded())
    }
    
    func calculateWeeklyWeightLoss() -> Double {
        let weightToLoseKg = max(currentWeight - targetWeight, 0)
        guard weightToLoseKg > 0 else {
            return 0
        }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: targetDate)
        let daysRemaining = max(calendar.dateComponents([.day], from: start, to: end).day ?? 0, 1)

        return weightToLoseKg * 7.0 / Double(daysRemaining)
    }
    
    func isGoalRealistic() -> Bool {
        return calculateWeeklyWeightLoss() <= 1.0
    }
    
    func setPersonalTrainer(_ trainer: PersonalTrainer) {
        personalTrainer = trainer
        hasCompletedTrainerSetup = true
    }
}
