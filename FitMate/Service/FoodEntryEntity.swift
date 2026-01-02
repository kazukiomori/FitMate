import Foundation
import CoreData

@objc(FoodEntryEntity)
public class FoodEntryEntity: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FoodEntryEntity> {
        return NSFetchRequest<FoodEntryEntity>(entityName: "FoodEntryEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var time: Date?
    @NSManaged public var name: String?
    @NSManaged public var calories: Double
    @NSManaged public var note: String?
}
