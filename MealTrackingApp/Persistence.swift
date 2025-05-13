import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "MealTrackingApp")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}



//import Foundation
//import CoreData
//
//extension Meal {
//    @nonobjc public class func fetchRequest() -> NSFetchRequest<Meal> {
//        return NSFetchRequest<Meal>(entityName: "Meal")
//    }
//
//    @NSManaged public var name: String?
//    @NSManaged public var calories: Double
//    @NSManaged public var mealtype: String?
//    @NSManaged public var date: Date?
//    @NSManaged public var toCategory: Category?
//    
//    // New properties
//    @NSManaged public var protein: Double
//    @NSManaged public var carbs: Double
//    @NSManaged public var fat: Double
//    @NSManaged public var notes: String?
//    @NSManaged public var imageData: Data?
//}
//
//extension Meal : Identifiable {
//    // Computed properties for convenience
//    var formattedDate: String {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .short
//        formatter.timeStyle = .short
//        return formatter.string(from: date ?? Date())
//    }
//    
//    var formattedTime: String {
//        let formatter = DateFormatter()
//        formatter.timeStyle = .short
//        return formatter.string(from: date ?? Date())
//    }
//    
//    var totalNutrients: Double {
//        return protein + carbs + fat
//    }
//    
//    var mealTypeIcon: String {
//        switch mealtype?.lowercased() {
//        case "breakfast": return "sunrise"
//        case "lunch": return "sun.max"
//        case "dinner": return "moon.stars"
//        case "snack": return "cup.and.saucer"
//        default: return "fork.knife"
//        }
//    }
//}




