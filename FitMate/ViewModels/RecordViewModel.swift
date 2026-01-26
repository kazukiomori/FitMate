//
//  RecordViewModel.swift
//  FitMate
//

import SwiftUI
import CoreData
import Combine

class RecordViewModel: ObservableObject {
    @Published var dailyRecords: [DailyRecord] = []
    @Published var weightEntries: [WeightEntry] = []
    @Published var foodEntries: [FoodEntry] = []
    
    // 体重データサービス
    private let weightDataService = WeightDataService()
    private let foodDataService = FoodDataService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 体重・食事の永続データを監視して日別記録を再構築
        weightDataService.$weightEntries
            .sink { [weak self] entries in
                self?.weightEntries = entries
                self?.rebuildDailyRecords()
            }
            .store(in: &cancellables)

        foodDataService.$foodEntries
            .sink { [weak self] entries in
                self?.foodEntries = entries
                self?.rebuildDailyRecords()
            }
            .store(in: &cancellables)

        // 初期ロード（サービス側initでも読み込みますが、明示しておく）
        weightDataService.loadWeightEntries()
        foodDataService.loadFoodEntries()
    }
    
    // 体重記録を追加（Core Dataに保存）
    func addWeightEntry(weight: Double, date: Date = Date(), note: String? = nil) {
        weightDataService.saveWeightEntry(weight: weight, date: date, note: note)
    }
    
    // 体重記録を更新
    func updateWeightEntry(id: UUID, weight: Double, date: Date, note: String?) {
        weightDataService.updateWeightEntry(id: id, weight: weight, date: date, note: note)
    }
    
    // 体重記録を削除
    func deleteWeightEntry(id: UUID) {
        weightDataService.deleteWeightEntry(id: id)
    }
    
    // 食事記録を追加
    func addFoodEntry(_ foodEntry: FoodEntry) {
        foodDataService.addFoodEntry(foodEntry)
    }

    // 食事記録を削除
    func deleteFoodEntry(id: UUID) {
        foodDataService.deleteFoodEntry(id: id)
    }
    
    private func rebuildDailyRecords() {
        let calendar = Calendar.current
        let groupedFood = Dictionary(grouping: foodEntries) { entry in
            calendar.startOfDay(for: entry.time)
        }
        let groupedWeight = Dictionary(grouping: weightEntries) { entry in
            calendar.startOfDay(for: entry.date)
        }

        let allDays = Set(groupedFood.keys).union(groupedWeight.keys)
        let records: [DailyRecord] = allDays
            .sorted()
            .map { day in
                var record = DailyRecord(date: day)
                record.foodEntries = (groupedFood[day] ?? []).sorted { $0.time < $1.time }
                // 同一日に複数体重がある場合は最新（時間が新しい）を採用
                if let entries = groupedWeight[day] {
                    record.weightEntry = entries.sorted { $0.date < $1.date }.last
                }
                return record
            }

        dailyRecords = records
    }
    
    // 直近N日の体重データを取得
    func getRecentWeightEntries(days: Int = 30) -> [WeightEntry] {
        return weightDataService.getRecentWeightEntries(days: days)
    }
    
    // 体重変化を計算
    func getWeightChange() -> Double {
        return weightDataService.getWeightChange()
    }
    
    // 最新の体重を取得
    func getLatestWeight() -> Double? {
        return weightDataService.getLatestWeightEntry()?.weight
    }
    
    // データをCSV形式でエクスポート
    func exportWeightData() -> String {
        return weightDataService.exportToCSV()
    }
    
    // バックアップデータを作成
    func createWeightBackup() -> Data? {
        return weightDataService.createBackup()
    }
    
    // 週平均体重を取得
    func getWeeklyAverageWeight() -> [(week: Date, averageWeight: Double)] {
        return weightDataService.getWeeklyAverageWeight()
    }
    

}
