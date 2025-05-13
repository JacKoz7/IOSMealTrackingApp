//
//  Category+CoreDataProperties.swift
//  MealTrackingApp
//
//  Created by Jacek Kozłowski on 13/05/2025.
//
//

import Foundation
import CoreData


extension Category {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }

    @NSManaged public var iconName: String?
    @NSManaged public var name: String?
    @NSManaged public var toMeal: NSSet?

}

// MARK: Generated accessors for toMeal
extension Category {

    @objc(addToMealObject:)
    @NSManaged public func addToToMeal(_ value: Meal)

    @objc(removeToMealObject:)
    @NSManaged public func removeFromToMeal(_ value: Meal)

    @objc(addToMeal:)
    @NSManaged public func addToToMeal(_ values: NSSet)

    @objc(removeToMeal:)
    @NSManaged public func removeFromToMeal(_ values: NSSet)

}

extension Category : Identifiable {

}
