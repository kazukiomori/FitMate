//
//  WeightDataService.swift
//  FitMate
//

import CoreData
import Combine

class WeightDataService: ObservableObject {
    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var weightEntries: [WeightEntry] = []
    
    init() {
        loadWeightEntries()
    }
    
    // 体重記録を保存
    func saveWeightEntry(weight: Double, date: Date = Date(), note: String? = nil) {
        let context = persistenceController.container.viewContext
        
        let newEntry = WeightEntryEntity(context: context)
        newEntry.id = UUID()
        newEntry.weight = weight
        newEntry.date = date
        newEntry.note = note
        
        persistenceController.save()
        loadWeightEntries()
        
        print("体重記録を保存しました: \(weight)kg")
    }
    
    // 体重記録を更新
    func updateWeightEntry(id: UUID, weight: Double, date: Date, note: String?) {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<WeightEntryEntity> = WeightEntryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                entity.weight = weight
                entity.date = date
                entity.note = note
                
                persistenceController.save()
                loadWeightEntries()
                
                print("体重記録を更新しました: \(weight)kg")
            }
        } catch {
            print("体重記録更新エラー: \(error)")
        }
    }
    
    // 体重記録を削除
    func deleteWeightEntry(id: UUID) {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<WeightEntryEntity> = WeightEntryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                context.delete(entity)
                persistenceController.save()
                loadWeightEntries()
                
                print("体重記録を削除しました")
            }
        } catch {
            print("体重記録削除エラー: \(error)")
        }
    }
    
    // 全ての体重記録を読み込み
    func loadWeightEntries() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<WeightEntryEntity> = WeightEntryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WeightEntryEntity.date, ascending: false)]
        
        do {
            let entities = try context.fetch(request)
            weightEntries = entities.map { WeightEntry(from: $0) }
            print("体重記録を読み込みました: \(weightEntries.count)件")
        } catch {
            print("体重記録読み込みエラー: \(error)")
            weightEntries = []
        }
    }
    
    // 期間指定で体重記録を取得
    func getWeightEntries(from startDate: Date, to endDate: Date) -> [WeightEntry] {
        return weightEntries.filter { entry in
            entry.date >= startDate && entry.date <= endDate
        }
    }
    
    // 最新の体重記録を取得
    func getLatestWeightEntry() -> WeightEntry? {
        return weightEntries.first
    }
    
    // 体重変化を計算
    func getWeightChange() -> Double {
        guard weightEntries.count >= 2 else { return 0 }
        let sortedEntries = weightEntries.sorted { $0.date < $1.date }
        return sortedEntries.last!.weight - sortedEntries.first!.weight
    }
    
    // 直近30日の体重データ取得
    func getRecentWeightEntries(days: Int = 30) -> [WeightEntry] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        return weightEntries.filter { $0.date >= startDate }
    }
    
    // 週平均体重を計算
    func getWeeklyAverageWeight() -> [(week: Date, averageWeight: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: weightEntries) { entry in
            calendar.dateInterval(of: .weekOfYear, for: entry.date)?.start ?? entry.date
        }
        
        return grouped.compactMap { (week, entries) in
            let average = entries.map { $0.weight }.reduce(0, +) / Double(entries.count)
            return (week: week, averageWeight: average)
        }.sorted { $0.week < $1.week }
    }
    
    // データをエクスポート（CSV形式）
    func exportToCSV() -> String {
        var csv = "日付,体重(kg),メモ\n"
        
        let sortedEntries = weightEntries.sorted { $0.date < $1.date }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for entry in sortedEntries {
            let dateString = dateFormatter.string(from: entry.date)
            let noteString = entry.note?.replacingOccurrences(of: ",", with: "、") ?? ""
            csv += "\(dateString),\(entry.weight),\(noteString)\n"
        }
        
        return csv
    }
    
    // バックアップ作成
    func createBackup() -> Data? {
        let csv = exportToCSV()
        return csv.data(using: .utf8)
    }
}

