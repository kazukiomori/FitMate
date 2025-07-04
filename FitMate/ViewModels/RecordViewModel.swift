//
//  RecordViewModel.swift
//  FitMate
//

import SwiftUI

class RecordViewModel: ObservableObject {
    @Published var dailyRecords: [DailyRecord] = []
    @Published var weightEntries: [WeightEntry] = []
    
    init() {
        // サンプルデータ
        generateSampleData()
    }
    
    // 体重記録追加
    func addWeightEntry(weight: Double, date: Date = Date(), note: String? = nil) {
        let newEntry = WeightEntry(weight: weight, date: date, note: note)
        weightEntries.append(newEntry)
        weightEntries.sort { $0.date < $1.date }
        
        // 該当日のDailyRecordを更新
        updateDailyRecord(for: date, weightEntry: newEntry)
    }
    
    // 食事記録追加
    func addFoodEntry(_ foodEntry: FoodEntry) {
        updateDailyRecord(for: foodEntry.time, foodEntry: foodEntry)
    }
    
    // 日別記録更新
    private func updateDailyRecord(for date: Date, weightEntry: WeightEntry? = nil, foodEntry: FoodEntry? = nil) {
        let dayStart = Calendar.current.startOfDay(for: date)
        
        if let index = dailyRecords.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: dayStart) }) {
            if let weightEntry = weightEntry {
                dailyRecords[index].weightEntry = weightEntry
            }
            if let foodEntry = foodEntry {
                dailyRecords[index].foodEntries.append(foodEntry)
            }
        } else {
            var newRecord = DailyRecord(date: dayStart)
            newRecord.weightEntry = weightEntry
            if let foodEntry = foodEntry {
                newRecord.foodEntries.append(foodEntry)
            }
            dailyRecords.append(newRecord)
            dailyRecords.sort { $0.date < $1.date }
        }
    }
    
    // 直近30日の体重データ取得
    func getRecentWeightEntries(days: Int = 30) -> [WeightEntry] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        return weightEntries.filter { $0.date >= startDate }
    }
    
    // 体重変化計算
    func getWeightChange() -> Double {
        guard weightEntries.count >= 2 else { return 0 }
        let sortedEntries = weightEntries.sorted { $0.date < $1.date }
        return sortedEntries.last!.weight - sortedEntries.first!.weight
    }
    
    // サンプルデータ生成
    private func generateSampleData() {
        let calendar = Calendar.current
        
        // 過去30日の体重データ
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let weight = 70.0 + Double.random(in: -2...2) - (Double(i) * 0.05) // 徐々に減量
            addWeightEntry(weight: weight, date: date)
        }
        
        // 今日の食事データ
        let today = Date()
        let breakfast = FoodEntry(name: "ご飯", calories: 252, time: today, mealType: .breakfast)
        let lunch = FoodEntry(name: "サラダ", calories: 150, time: today, mealType: .lunch)
        addFoodEntry(breakfast)
        addFoodEntry(lunch)
    }
}

