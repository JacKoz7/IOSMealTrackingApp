//
//  Meal+CoreDataProperties.swift
//  MealTrackingApp
//
//  Created by Jacek Kozłowski on 13/05/2025.
//
//

import Foundation
import CoreData


extension Meal {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Meal> {
        return NSFetchRequest<Meal>(entityName: "Meal")
    }

    @NSManaged public var calories: Double
    @NSManaged public var date: Date?
    @NSManaged public var mealtype: String?
    @NSManaged public var name: String?
    @NSManaged public var protein: Double
    @NSManaged public var carbs: Double
    @NSManaged public var fat: Double
    @NSManaged public var notes: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var toCategory: Category?

}

extension Meal : Identifiable {

}
