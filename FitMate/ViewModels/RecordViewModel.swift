//
//  RecordViewModel.swift
//  FitMate
//

import SwiftUI
import CoreData

class RecordViewModel: ObservableObject {
    @Published var dailyRecords: [DailyRecord] = []
    @Published var weightEntries: [WeightEntry] = []
    
    // 体重データサービス
    private let weightDataService = WeightDataService()
    
    init() {
        // WeightDataServiceからデータを監視
        weightDataService.$weightEntries
            .assign(to: &$weightEntries)
        
        // サンプルデータ生成（食事記録用）
        generateSampleFoodData()
        
        // Core Dataから体重データを読み込み
        loadWeightData()
    }
    
    // 体重記録を追加（Core Dataに保存）
    func addWeightEntry(weight: Double, date: Date = Date(), note: String? = nil) {
        weightDataService.saveWeightEntry(weight: weight, date: date, note: note)
        
        // DailyRecord も更新
        updateDailyRecordForWeight(for: date, weightEntry: WeightEntry(weight: weight, date: date, note: note))
    }
    
    // 体重記録を更新
    func updateWeightEntry(id: UUID, weight: Double, date: Date, note: String?) {
        weightDataService.updateWeightEntry(id: id, weight: weight, date: date, note: note)
        
        // DailyRecord も更新
        updateDailyRecordForWeight(for: date, weightEntry: WeightEntry(weight: weight, date: date, note: note))
    }
    
    // 体重記録を削除
    func deleteWeightEntry(id: UUID) {
        weightDataService.deleteWeightEntry(id: id)
    }
    
    // 食事記録を追加
    func addFoodEntry(_ foodEntry: FoodEntry) {
        updateDailyRecordForFood(for: foodEntry.time, foodEntry: foodEntry)
    }
    
    // 日別記録を更新（体重用）
    private func updateDailyRecordForWeight(for date: Date, weightEntry: WeightEntry) {
        let dayStart = Calendar.current.startOfDay(for: date)
        if let index = dailyRecords.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: dayStart) }) {
            dailyRecords[index].weightEntry = weightEntry
        } else {
            var newRecord = DailyRecord(date: dayStart)
            newRecord.weightEntry = weightEntry
            dailyRecords.append(newRecord)
            dailyRecords.sort { $0.date < $1.date }
        }
    }

    // 日別記録を更新（食事用）
    private func updateDailyRecordForFood(for date: Date, foodEntry: FoodEntry) {
        let dayStart = Calendar.current.startOfDay(for: date)
        if let index = dailyRecords.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: dayStart) }) {
            dailyRecords[index].foodEntries.append(foodEntry)
        } else {
            var newRecord = DailyRecord(date: dayStart)
            newRecord.foodEntries.append(foodEntry)
            dailyRecords.append(newRecord)
            dailyRecords.sort { $0.date < $1.date }
        }
    }

    // Core Dataから体重データを読み込み
    private func loadWeightData() {
        weightDataService.loadWeightEntries()
        
        // DailyRecordsに反映
        for weightEntry in weightEntries {
            updateDailyRecordForWeight(for: weightEntry.date, weightEntry: weightEntry)
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
    
    // サンプル食事データを生成（体重データは実際のCore Dataを使用）
    private func generateSampleFoodData() {
        // 今日の食事データのみサンプル作成
        let today = Date()
        let breakfast = FoodEntry(name: "ご飯", calories: 252, time: today, mealType: .breakfast)
        let lunch = FoodEntry(name: "サラダ", calories: 150, time: today, mealType: .lunch)
        addFoodEntry(breakfast)
        addFoodEntry(lunch)
    }
}
