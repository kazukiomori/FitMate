//
//  WeightEntry.swift
//  FitMate
//

import CoreData
import Foundation

struct WeightEntry: Identifiable {
    let id: UUID
    let weight: Double
    let date: Date
    let note: String?
    
    init(weight: Double, date: Date = Date(), note: String? = nil) {
        self.id = UUID()
        self.weight = weight
        self.date = date
        self.note = note
    }
    
    // Core Data エンティティから WeightEntry を作成
    init(from coreDataEntity: WeightEntryEntity) {
        self.id = coreDataEntity.id ?? UUID()
        self.weight = coreDataEntity.weight
        self.date = coreDataEntity.date ?? Date()
        self.note = coreDataEntity.note
    }
    
    // Core Data エンティティに変換
    func toCoreDataEntity(context: NSManagedObjectContext) -> WeightEntryEntity {
        let entity = WeightEntryEntity(context: context)
        entity.id = self.id
        entity.weight = self.weight
        entity.date = self.date
        entity.note = self.note
        return entity
    }
}

