import CoreData
import Combine

private typealias FoodEntryMO = FoodEntryEntity

class FoodDataService: ObservableObject {
    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()

    @Published var foodEntries: [FoodEntry] = []

    init() {
        loadFoodEntries()
    }

    // 食事記録を保存
    func saveFoodEntry(id: UUID = UUID(), time: Date = Date(), name: String, calories: Double?, note: String? = nil) {
        let context = persistenceController.container.viewContext
        let newEntry = FoodEntryMO(context: context)
        newEntry.id = id
        newEntry.time = time
        newEntry.name = name
        newEntry.calories = calories ?? 0
        newEntry.note = note

        persistenceController.save()
        loadFoodEntries()
        print("食事記録を保存しました: \(name)")
    }

    // 食事記録を更新
    func updateFoodEntry(id: UUID, time: Date, name: String, calories: Double?, note: String?) {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<FoodEntryMO> = FoodEntryMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                entity.time = time
                entity.name = name
                entity.calories = calories ?? 0
                entity.note = note

                persistenceController.save()
                loadFoodEntries()
                print("食事記録を更新しました: \(name)")
            }
        } catch {
            print("食事記録更新エラー: \(error)")
        }
    }

    // 食事記録を削除
    func deleteFoodEntry(id: UUID) {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<FoodEntryMO> = FoodEntryMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                context.delete(entity)
                persistenceController.save()
                loadFoodEntries()
                print("食事記録を削除しました")
            }
        } catch {
            print("食事記録削除エラー: \(error)")
        }
    }

    // 全ての食事記録を読み込み
    func loadFoodEntries() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<FoodEntryMO> = FoodEntryMO.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]

        do {
            let entities = try context.fetch(request)
            foodEntries = entities.map { entity in
                FoodEntry(
                    name: entity.name ?? "",
                    calories: Int(entity.calories),
                    time: entity.time ?? Date(),
                    mealType: .breakfast
                )
            }
            print("食事記録を読み込みました: \(foodEntries.count)件")
        } catch {
            print("食事記録読み込みエラー: \(error)")
            foodEntries = []
        }
    }

    // 期間指定で食事記録を取得
    func getFoodEntries(from startDate: Date, to endDate: Date) -> [FoodEntry] {
        return foodEntries.filter { entry in
            entry.time >= startDate && entry.time <= endDate
        }
    }

    // 直近N日の食事データ取得
    func getRecentFoodEntries(days: Int = 30) -> [FoodEntry] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return foodEntries.filter { $0.time >= startDate }
    }
}

