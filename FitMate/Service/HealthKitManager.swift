//
//  HealthKitManager.swift
//  FitMate
//

import HealthKit
import SwiftUI

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var stepCount: Int = 0
    @Published var activeEnergyBurned: Double = 0
    @Published var basalEnergyBurned: Double = 0
    @Published var threeDayAverageBasalEnergyExcludingToday: Double = 0
    @Published var isAuthorized: Bool = false

    var totalEnergyBurned: Double {
        let basal = threeDayAverageBasalEnergyExcludingToday > 0 ? threeDayAverageBasalEnergyExcludingToday : basalEnergyBurned
        return activeEnergyBurned + basal
    }
    
    init() {
        checkHealthKitAuthorization()
    }
    
    // HealthKit認証チェック
    private func checkHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    self?.fetchTodayHealthData()
                } else {
                    print("HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    // 今日の健康データを取得
    func fetchTodayHealthData() {
        guard isAuthorized else { return }
        
        fetchStepCount()
        fetchActiveEnergyBurned()
        fetchBasalEnergyBurned()
        fetchThreeDayAverageBasalEnergyExcludingToday()
    }
    
    // 歩数取得
    private func fetchStepCount() {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: stepCountType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let result = result,
                   let sum = result.sumQuantity() {
                    self?.stepCount = Int(sum.doubleValue(for: HKUnit.count()))
                } else {
                    print("Failed to fetch step count: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // 消費カロリー取得
    private func fetchActiveEnergyBurned() {
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: activeEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let result = result,
                   let sum = result.sumQuantity() {
                    self?.activeEnergyBurned = sum.doubleValue(for: HKUnit.kilocalorie())
                } else {
                    print("Failed to fetch active energy: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
        
        healthStore.execute(query)
    }

    // 安静時消費カロリー（Basal Energy）取得
    private func fetchBasalEnergyBurned() {
        guard let basalEnergyType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else { return }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        let query = HKStatisticsQuery(
            quantityType: basalEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let result = result,
                   let sum = result.sumQuantity() {
                    self?.basalEnergyBurned = sum.doubleValue(for: HKUnit.kilocalorie())
                } else {
                    print("Failed to fetch basal energy: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }

        healthStore.execute(query)
    }

    /// 今日を除外した「過去3日分」の安静時消費エネルギー平均を取得（0 kcal日は除外）
    private func fetchThreeDayAverageBasalEnergyExcludingToday() {
        guard let basalType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else {
            DispatchQueue.main.async { [weak self] in self?.threeDayAverageBasalEnergyExcludingToday = 0 }
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)

        // 4日前の0時（3日分取得するため）
        guard let startDate = calendar.date(byAdding: .day, value: -4, to: todayStart) else {
            DispatchQueue.main.async { [weak self] in self?.threeDayAverageBasalEnergyExcludingToday = 0 }
            return
        }

        // 終了日は「今日の0時」＝今日を除外
        let endDate = todayStart

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        var interval = DateComponents()
        interval.day = 1

        let query = HKStatisticsCollectionQuery(
            quantityType: basalType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: todayStart,
            intervalComponents: interval
        )

        query.initialResultsHandler = { [weak self] _, results, error in
            if let error {
                DispatchQueue.main.async {
                    self?.threeDayAverageBasalEnergyExcludingToday = 0
                }
                print("Failed to fetch three-day average basal energy: \(error.localizedDescription)")
                return
            }

            var dailyTotals: [Double] = []
            results?.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                let value = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                if value > 0 {
                    dailyTotals.append(value)
                }
            }

            let average: Double
            if dailyTotals.isEmpty {
                average = 0
            } else {
                average = dailyTotals.reduce(0, +) / Double(dailyTotals.count)
            }

            DispatchQueue.main.async {
                self?.threeDayAverageBasalEnergyExcludingToday = average
            }
        }

        healthStore.execute(query)
    }
    
    // 手動データ更新
    func refreshHealthData() {
        fetchTodayHealthData()
    }
}

