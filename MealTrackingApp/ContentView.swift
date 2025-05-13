import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView {
            NavigationStack {
                MealListView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .tabItem {
                Label("Meal list", systemImage: "list.bullet")
            }

            NavigationStack {
                AddMealView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .tabItem {
                Label("Add meal", systemImage: "plus.circle")
            }

            NavigationStack {
                StatisticsView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
        }
    }
}
