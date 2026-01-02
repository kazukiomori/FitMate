//
//  FoodEntry.swift
//  FitMate
//

import Foundation

struct FoodEntry: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
    let time: Date
    let mealType: MealType
    let fat: Double = 0.0
    let carbs: Double = 0.0
    let protein: Double = 0.0
}
