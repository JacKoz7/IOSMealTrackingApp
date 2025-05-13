//
//  MealTrackingAppApp.swift
//  MealTrackingApp
//
//  Created by Jacek Kozłowski on 08/05/2025.
//

import SwiftUI

@main
struct MealTrackingAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
