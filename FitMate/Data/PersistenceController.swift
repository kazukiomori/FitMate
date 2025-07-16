//
//  PersistenceController.swift
//  FitMate
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // プレビュー用のサンプルデータ
        for i in 0..<10 {
            let entry = WeightEntryEntity(context: viewContext)
            entry.id = UUID()
            entry.weight = 70.0 - Double(i) * 0.2
            entry.date = Calendar.current.date(byAdding: .day, value: -i, to: Date())
            entry.note = i % 3 == 0 ? "朝食後" : nil
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FitMateDataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Core Data エラー: \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("Core Data 保存成功")
            } catch {
                let nsError = error as NSError
                print("Core Data 保存エラー: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func deleteAll() {
        let context = container.viewContext
        let request: NSFetchRequest<NSFetchRequestResult> = WeightEntryEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("全データ削除完了")
        } catch {
            print("データ削除エラー: \(error)")
        }
    }
}
