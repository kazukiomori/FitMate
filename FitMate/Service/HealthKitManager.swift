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
    @Published var isAuthorized: Bool = false
    
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
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
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
    
    // 手動データ更新
    func refreshHealthData() {
        fetchTodayHealthData()
    }
}

