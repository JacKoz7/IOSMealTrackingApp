import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                MealListView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .tabItem {
                Label("Meal list", systemImage: "list.bullet")
            }
            .tag(0)

            NavigationStack {
                AddMealView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .tabItem {
                Label("Add meal", systemImage: "plus.circle")
            }
            .tag(1)

            NavigationStack {
                StatisticsView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
            .tag(2)
        }
        .accentColor(.gray)
        .onAppear {
            UITabBar.appearance().tintColor = UIColor.systemBlue
        }
    }
}
