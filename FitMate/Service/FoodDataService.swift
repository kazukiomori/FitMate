//
//  FoodDataService.swift
//  FitMate
//

import CoreData
import Combine
import Foundation

class FoodDataService: ObservableObject {
    private let container: NSPersistentContainer
    var context: NSManagedObjectContext { container.viewContext }
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FitMateModel")
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data load error: \(error)")
            }
        }
    }
    
    private func startOfDay(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    func addFoodEntry(_ foodEntry: FoodEntry) {
        let entity = FoodEntryEntity(context: context)
        entity.id = foodEntry.id
        entity.name = foodEntry.name
        entity.calories = Int16(foodEntry.calories)
        entity.carbs = foodEntry.carbs
        entity.protein = foodEntry.protein
        entity.fat = foodEntry.fat
        entity.time = foodEntry.time
        do {
            try context.save()
            
        } catch {
            context.rollback()
            print("Failed to save FoodEntry: \(error)")
        }
    }
}

