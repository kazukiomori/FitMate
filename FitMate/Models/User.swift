//
//  User.swift
//  FitMate
//

import SwiftUI
import UIKit

enum IntimacyStatus: Int {
    case firstMeeting = 1
    case acquaintance
    case personalTrainer
    case trustedPartner
    case closeFriend
    case specialBuddy
    case specialSupporter
    case happyToSeeYou
    case almostLover
    case closestPartner

    var title: String {
        switch self {
        case .firstMeeting: return "はじめまして"
        case .acquaintance: return "顔なじみ"
        case .personalTrainer: return "専属トレーナー"
        case .trustedPartner: return "信頼できる相手"
        case .closeFriend: return "気軽に話せる仲"
        case .specialBuddy: return "大切な相棒"
        case .specialSupporter: return "特別に応援したい人"
        case .happyToSeeYou: return "会えると嬉しい人"
        case .almostLover: return "ほっとけない存在"
        case .closestPartner: return "いちばん近い存在"
        }
    }
}

class User: ObservableObject {
    private enum StorageKeys {
        static let personalTrainer = "storedPersonalTrainer"
        static let intimacyProgress = "storedIntimacyProgress"
    }

    private enum IntimacyReward {
        static let appLaunch = 3
        static let weightRecord = 8
        static let foodRecord = 6
        static let consecutiveLogin = 5
        static let streak7Days = 30
        static let streak14Days = 60
        static let streak30Days = 150
    }

    private struct PersistedTrainer: Codable {
        let name: String
        let preferences: PersistedTrainerPreferences
        let imagesData: [Data]
        let assetNamespace: String?
        let createdAt: Date
    }

    private struct PersistedTrainerPreferences: Codable {
        let gender: String
        let age: String
        let style: String
        let personality: String
        let specialization: String
    }

    private struct PersistedIntimacyProgress: Codable {
        let totalExp: Int
        let loginStreak: Int
        let lastAppLaunchRewardDate: Date?
        let lastFoodRewardDate: Date?
        let foodRewardCountForDay: Int
        let lastWeightRewardDate: Date?
    }

    private static let intimacyLevelThresholds: [Int] = [0, 30, 80, 150, 240, 350, 480, 630, 800, 1000]

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
    @Published private(set) var intimacyExp: Int = 0
    @Published private(set) var loginStreak: Int = 0

    private var lastAppLaunchRewardDate: Date?
    private var lastFoodRewardDate: Date?
    private var foodRewardCountForDay: Int = 0
    private var lastWeightRewardDate: Date?

    init() {
        restorePersonalTrainerIfNeeded()
        restoreIntimacyProgressIfNeeded()
    }

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
        resetIntimacyProgress()
        persistPersonalTrainer(trainer)
    }

    func clearPersonalTrainer() {
        personalTrainer = nil
        hasCompletedTrainerSetup = false
        UserDefaults.standard.removeObject(forKey: StorageKeys.personalTrainer)
        resetIntimacyProgress()
    }

    var intimacyLevel: Int {
        let thresholds = Self.intimacyLevelThresholds
        let levelIndex = thresholds.lastIndex(where: { intimacyExp >= $0 }) ?? 0
        return min(levelIndex + 1, 10)
    }

    var intimacyStatus: IntimacyStatus {
        IntimacyStatus(rawValue: intimacyLevel) ?? .firstMeeting
    }

    var intimacyTitle: String {
        intimacyStatus.title
    }

    var intimacyProgressToNextLevel: Double {
        let thresholds = Self.intimacyLevelThresholds
        guard intimacyLevel < 10 else { return 1 }

        let currentThreshold = thresholds[intimacyLevel - 1]
        let nextThreshold = thresholds[intimacyLevel]
        let gainedInLevel = intimacyExp - currentThreshold
        let requiredInLevel = nextThreshold - currentThreshold

        guard requiredInLevel > 0 else { return 1 }
        return min(max(Double(gainedInLevel) / Double(requiredInLevel), 0), 1)
    }

    var intimacyExpForNextLevel: Int? {
        let thresholds = Self.intimacyLevelThresholds
        guard intimacyLevel < 10 else { return nil }
        return thresholds[intimacyLevel]
    }

    @discardableResult
    func registerAppLaunch(on date: Date = Date()) -> Int {
        let today = startOfDay(for: date)
        guard !isSameDay(lastAppLaunchRewardDate, today) else { return 0 }

        let wasConsecutive = isConsecutiveLogin(comparedTo: today)
        lastAppLaunchRewardDate = today
        loginStreak = wasConsecutive ? loginStreak + 1 : 1

        var awardedPoints = 0
        awardedPoints += addIntimacyExp(IntimacyReward.appLaunch)

        if wasConsecutive {
            awardedPoints += addIntimacyExp(IntimacyReward.consecutiveLogin)
        }

        switch loginStreak {
        case 7:
            awardedPoints += addIntimacyExp(IntimacyReward.streak7Days)
        case 14:
            awardedPoints += addIntimacyExp(IntimacyReward.streak14Days)
        case 30:
            awardedPoints += addIntimacyExp(IntimacyReward.streak30Days)
        default:
            break
        }

        persistIntimacyProgress()
        return awardedPoints
    }

    @discardableResult
    func registerWeightRecord(on date: Date = Date()) -> Int {
        let today = startOfDay(for: date)
        guard !isSameDay(lastWeightRewardDate, today) else { return 0 }

        lastWeightRewardDate = today
        let awardedPoints = addIntimacyExp(IntimacyReward.weightRecord)
        persistIntimacyProgress()
        return awardedPoints
    }

    @discardableResult
    func registerFoodRecord(on date: Date = Date()) -> Int {
        let today = startOfDay(for: date)

        if !isSameDay(lastFoodRewardDate, today) {
            lastFoodRewardDate = today
            foodRewardCountForDay = 0
        }

        guard foodRewardCountForDay < 3 else { return 0 }

        foodRewardCountForDay += 1
        lastFoodRewardDate = today
        let awardedPoints = addIntimacyExp(IntimacyReward.foodRecord)
        persistIntimacyProgress()
        return awardedPoints
    }

    func resetIntimacyProgress() {
        intimacyExp = 0
        loginStreak = 0
        lastAppLaunchRewardDate = nil
        lastFoodRewardDate = nil
        foodRewardCountForDay = 0
        lastWeightRewardDate = nil
        persistIntimacyProgress()
    }

    private func persistPersonalTrainer(_ trainer: PersonalTrainer) {
        let persistedTrainer = PersistedTrainer(
            name: trainer.name,
            preferences: PersistedTrainerPreferences(
                gender: trainer.preferences.gender.rawValue,
                age: trainer.preferences.age.rawValue,
                style: trainer.preferences.style.rawValue,
                personality: trainer.preferences.personality.rawValue,
                specialization: trainer.preferences.specialization.rawValue
            ),
            imagesData: trainer.images.compactMap { image in
                image.jpegData(compressionQuality: 0.92) ?? image.pngData()
            },
            assetNamespace: trainer.assetNamespace,
            createdAt: trainer.createdAt
        )

        guard let data = try? JSONEncoder().encode(persistedTrainer) else { return }
        UserDefaults.standard.set(data, forKey: StorageKeys.personalTrainer)
    }

    private func persistIntimacyProgress() {
        let persistedProgress = PersistedIntimacyProgress(
            totalExp: intimacyExp,
            loginStreak: loginStreak,
            lastAppLaunchRewardDate: lastAppLaunchRewardDate,
            lastFoodRewardDate: lastFoodRewardDate,
            foodRewardCountForDay: foodRewardCountForDay,
            lastWeightRewardDate: lastWeightRewardDate
        )

        guard let data = try? JSONEncoder().encode(persistedProgress) else { return }
        UserDefaults.standard.set(data, forKey: StorageKeys.intimacyProgress)
    }

    private func restorePersonalTrainerIfNeeded() {
        guard let data = UserDefaults.standard.data(forKey: StorageKeys.personalTrainer),
              let persistedTrainer = try? JSONDecoder().decode(PersistedTrainer.self, from: data),
              let preferences = restoredPreferences(from: persistedTrainer.preferences) else {
            return
        }

        let restoredImages = persistedTrainer.imagesData.compactMap(UIImage.init(data:))

        personalTrainer = PersonalTrainer(
            name: persistedTrainer.name,
            preferences: preferences,
            images: restoredImages,
            assetNamespace: persistedTrainer.assetNamespace,
            createdAt: persistedTrainer.createdAt
        )
        hasCompletedTrainerSetup = true
    }

    private func restoreIntimacyProgressIfNeeded() {
        guard let data = UserDefaults.standard.data(forKey: StorageKeys.intimacyProgress),
              let persistedProgress = try? JSONDecoder().decode(PersistedIntimacyProgress.self, from: data) else {
            return
        }

        intimacyExp = max(0, persistedProgress.totalExp)
        loginStreak = max(0, persistedProgress.loginStreak)
        lastAppLaunchRewardDate = persistedProgress.lastAppLaunchRewardDate
        lastFoodRewardDate = persistedProgress.lastFoodRewardDate
        foodRewardCountForDay = max(0, persistedProgress.foodRewardCountForDay)
        lastWeightRewardDate = persistedProgress.lastWeightRewardDate
    }

    private func restoredPreferences(from persisted: PersistedTrainerPreferences) -> TrainerPreferences? {
        guard let gender = TrainerGender(rawValue: persisted.gender),
              let age = TrainerAge(rawValue: persisted.age),
              let style = TrainerStyle(rawValue: persisted.style),
              let personality = TrainerPersonality(rawValue: persisted.personality),
              let specialization = TrainerSpecialization(rawValue: persisted.specialization) else {
            return nil
        }

        return TrainerPreferences(
            gender: gender,
            age: age,
            style: style,
            personality: personality,
            specialization: specialization
        )
    }

    private func addIntimacyExp(_ points: Int) -> Int {
        guard points > 0 else { return 0 }
        intimacyExp += points
        return points
    }

    private func isSameDay(_ lhs: Date?, _ rhs: Date) -> Bool {
        guard let lhs else { return false }
        return Calendar.current.isDate(lhs, inSameDayAs: rhs)
    }

    private func isConsecutiveLogin(comparedTo today: Date) -> Bool {
        guard let lastAppLaunchRewardDate else { return false }
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) else {
            return false
        }
        return Calendar.current.isDate(lastAppLaunchRewardDate, inSameDayAs: yesterday)
    }

    private func startOfDay(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
}
