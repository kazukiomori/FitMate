//
//  RecordViewModel.swift
//  FitMate
//

import SwiftUI
import CoreData

class RecordViewModel: ObservableObject {
    @Published var dailyRecords: [DailyRecord] = []
    @Published var weightEntries: [WeightEntry] = []
    @Published var foodEntries: [FoodEntry] = []
    
    // 体重データサービス
    private let weightDataService = WeightDataService()
    // 食事データサービス
    private let foodDataService = FoodDataService()
    
    init() {
        // WeightDataServiceからデータを監視
        weightDataService.$weightEntries
            .assign(to: &$weightEntries)
        foodDataService.$foodEntries
            .assign(to: &$foodEntries)
        
        // Core Dataから体重データを読み込み
        loadWeightData()
        loadFoodData()
    }
    
    // 体重記録を追加（Core Dataに保存）
    func addWeightEntry(weight: Double, date: Date = Date(), note: String? = nil) {
        weightDataService.saveWeightEntry(weight: weight, date: date, note: note)
        
        // DailyRecord も更新
        updateDailyRecordForWeight(date: date, weightEntry: WeightEntry(weight: weight, date: date, note: note))
    }
    
    // 体重記録を更新
    func updateWeightEntry(id: UUID, weight: Double, date: Date, note: String?) {
        weightDataService.updateWeightEntry(id: id, weight: weight, date: date, note: note)
        
        // DailyRecord も更新
        updateDailyRecordForWeight(date: date, weightEntry: WeightEntry(weight: weight, date: date, note: note))
    }
    
    // 体重記録を削除
    func deleteWeightEntry(id: UUID) {
        weightDataService.deleteWeightEntry(id: id)
    }
    
    // 食事記録を追加
    func addFoodEntry(_ foodEntry: FoodEntry) {
        updateDailyRecordForFood(date: foodEntry.time, foodEntry: foodEntry)
    }
    
    // 体重用: 指定日の DailyRecord を体重エントリで更新/作成する
    @discardableResult
    func updateDailyRecordForWeight(date: Date, weightEntry: WeightEntry) -> DailyRecord {
        return updateDailyRecordInternal(for: date, weightEntry: weightEntry, foodEntry: nil)
    }
    
    // 食事用: 指定日の DailyRecord に食事エントリを追加/作成する
    @discardableResult
    func updateDailyRecordForFood(date: Date, foodEntry: FoodEntry) -> DailyRecord {
        return updateDailyRecordInternal(for: date, weightEntry: nil, foodEntry: foodEntry)
    }
    
    @discardableResult
    private func updateDailyRecordInternal(for date: Date, weightEntry: WeightEntry? = nil, foodEntry: FoodEntry? = nil) -> DailyRecord {
        let dayStart = Calendar.current.startOfDay(for: date)
        
        // 既存の記録を検索
        if let index = dailyRecords.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: dayStart) }) {
            if let weightEntry = weightEntry {
                dailyRecords[index].weightEntry = weightEntry
            }
            if let foodEntry = foodEntry {
                dailyRecords[index].foodEntries.append(foodEntry)
            }
            return dailyRecords[index]
        } else {
            // 新しい記録を作成
            var newRecord = DailyRecord(date: dayStart)
            newRecord.weightEntry = weightEntry
            if let foodEntry = foodEntry {
                newRecord.foodEntries.append(foodEntry)
            }
            dailyRecords.append(newRecord)
            dailyRecords.sort { $0.date < $1.date }
            return newRecord
        }
    }
    
    // Core Dataから体重データを読み込み
    private func loadWeightData() {
        weightDataService.loadWeightEntries()
        
        // DailyRecordsに反映
        for weightEntry in weightEntries {
            updateDailyRecordForWeight(date: weightEntry.date, weightEntry: weightEntry)
        }
    }
    
    // Core Data から食事データを読み込み、dailyRecords へ反映する
    // サービスから最新データを読み込み
    private func loadFoodData() {
        // サービスから最新データを読み込み
        foodDataService.loadFoodEntries()

        // ビューモデルの foodEntries に反映（Combine の購読でも同期されるが、念のため明示）
        // ここではサービスの現在値を使って DailyRecord を更新する
        for entry in foodDataService.foodEntries {
            updateDailyRecordForFood(date: entry.time, foodEntry: entry)
        }
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

