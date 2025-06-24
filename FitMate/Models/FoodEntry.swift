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
}
