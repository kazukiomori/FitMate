//
//  FoodEntry.swift
//  FitMate
//

import CoreData
import Foundation

struct FoodEntry: Identifiable {
    let id: UUID
    let name: String
    let calories: Int
    let time: Date
    let mealType: MealType
    let fat: Double
    let carbs: Double
    let protein: Double

    init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        time: Date = Date(),
        mealType: MealType,
        fat: Double = 0.0,
        carbs: Double = 0.0,
        protein: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.time = time
        self.mealType = mealType
        self.fat = fat
        self.carbs = carbs
        self.protein = protein
    }

    // Core Data エンティティから FoodEntry を作成
    init(from coreDataEntity: FoodEntryEntity) {
        self.id = coreDataEntity.id ?? UUID()
        self.name = coreDataEntity.name ?? ""
        self.calories = Int(coreDataEntity.calories)
        self.time = coreDataEntity.time ?? Date()
        self.fat = coreDataEntity.fat
        self.carbs = coreDataEntity.carbs
        self.protein = coreDataEntity.protein

        // mealType はモデル側の属性名に依存するため、存在チェックしてからKVCで取得
        let attributes = coreDataEntity.entity.attributesByName
        if let rawNumber = (attributes["mealTypeRaw"] != nil ? coreDataEntity.value(forKey: "mealTypeRaw") : nil) as? NSNumber {
            self.mealType = MealType(rawValue: rawNumber.intValue) ?? .breakfast
        } else if let rawNumber = (attributes["mealType"] != nil ? coreDataEntity.value(forKey: "mealType") : nil) as? NSNumber {
            self.mealType = MealType(rawValue: rawNumber.intValue) ?? .breakfast
        } else {
            self.mealType = .breakfast
        }
    }
}
