//
//  FoodDataService.swift
//  FitMate
//

import CoreData
import Combine

class FoodDataService: ObservableObject {
    private let persistenceController = PersistenceController.shared
    @Published var foodEntries: [FoodEntry] = []

    init() {
        loadFoodEntries()
    }

    // 食事記録を保存
    func addFoodEntry(_ foodEntry: FoodEntry) {
        let context = persistenceController.container.viewContext

        let entity = FoodEntryEntity(context: context)
        entity.id = foodEntry.id
        entity.name = foodEntry.name
        entity.calories = Int16(foodEntry.calories)
        entity.carbs = foodEntry.carbs
        entity.protein = foodEntry.protein
        entity.fat = foodEntry.fat
        entity.time = foodEntry.time

        // mealType（モデルの属性名に合わせて保存）
        let attributes = entity.entity.attributesByName
        if attributes["mealTypeRaw"] != nil {
            entity.setValue(Int16(foodEntry.mealType.rawValue), forKey: "mealTypeRaw")
        } else if attributes["mealType"] != nil {
            entity.setValue(Int16(foodEntry.mealType.rawValue), forKey: "mealType")
        } else {
            // 属性が無い場合はクラッシュ回避（モデル側に追加すると保存される）
            print("[FoodDataService] FoodEntryEntity に mealType 属性がありません。xcdatamodeld に mealTypeRaw(Int16) 等を追加してください")
        }

        persistenceController.save()
        loadFoodEntries()
    }

    // 全ての食事記録を読み込み
    func loadFoodEntries() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<FoodEntryEntity> = FoodEntryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FoodEntryEntity.time, ascending: false)]

        do {
            let entities = try context.fetch(request)
            foodEntries = entities.map { FoodEntry(from: $0) }
            print("食事記録を読み込みました: \(foodEntries.count)件")
        } catch {
            print("食事記録読み込みエラー: \(error)")
            foodEntries = []
        }
    }

    // 食事記録を削除
    func deleteFoodEntry(id: UUID) {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<FoodEntryEntity> = FoodEntryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                context.delete(entity)
                persistenceController.save()
                loadFoodEntries()
            }
        } catch {
            print("食事記録削除エラー: \(error)")
        }
    }
}

