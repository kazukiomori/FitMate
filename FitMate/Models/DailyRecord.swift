//
//  DailyRecord.swift
//  FitMate
//

import Foundation

struct DailyRecord: Identifiable {
    let id = UUID()
    let date: Date
    var weightEntry: WeightEntry?
    var foodEntries: [FoodEntry] = []
    var totalCalories: Int {
        foodEntries.reduce(0) { $0 + $1.calories }
    }
    
    init(date: Date) {
        self.date = date
    }
}

