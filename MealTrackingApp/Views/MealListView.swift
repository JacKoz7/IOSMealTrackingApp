import SwiftUI
import CoreData
import UIKit // For haptic feedback

struct MealListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingAddView = false
    @State private var mealToEdit: Meal?
    @State private var searchText = ""
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker = false
    @State private var filterMealType: String? = nil
    @State private var showFilterSheet = false
    @State private var showingStatistics = false
    
    // Normalize selected date to start of day
    private var normalizedSelectedDate: Date {
        Calendar.current.startOfDay(for: selectedDate)
    }
    
    // Define FetchRequest for meals on the selected date
    @FetchRequest private var mealsForSelectedDay: FetchedResults<Meal>
    
    // For all meals (search results)
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Meal.date, ascending: false)],
        animation: .default
    ) private var allMeals: FetchedResults<Meal>
    
    // Initialize FetchRequest with dynamic predicate
    init() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        _mealsForSelectedDay = FetchRequest<Meal>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Meal.date, ascending: true)],
            predicate: predicate,
            animation: .default
        )
    }
    
    // Filter meals based on search text and meal type
    var filteredMeals: [Meal] {
        let meals = searchText.isEmpty ? Array(mealsForSelectedDay) : Array(allMeals)
        return meals.filter { meal in
            let matchesSearch = searchText.isEmpty ||
                (meal.name?.lowercased().contains(searchText.lowercased()) ?? false) ||
                (meal.toCategory?.name?.lowercased().contains(searchText.lowercased()) ?? false)
            let matchesFilter = filterMealType == nil || meal.mealtype == filterMealType
            return matchesSearch && matchesFilter
        }
    }
    
    // Calculate total calories for the day
    var totalCalories: Double {
        let sum = mealsForSelectedDay.reduce(0) { $0 + $1.calories }
        return sum.isNaN ? 0 : sum
    }
    
    // Calculate total nutrients for the day
    var totalProtein: Double {
        let sum = mealsForSelectedDay.reduce(0) { $0 + $1.protein }
        return sum.isNaN ? 0 : sum
    }
    
    var totalCarbs: Double {
        let sum = mealsForSelectedDay.reduce(0) { $0 + $1.carbs }
        return sum.isNaN ? 0 : sum
    }
    
    var totalFat: Double {
        let sum = mealsForSelectedDay.reduce(0) { $0 + $1.fat }
        return sum.isNaN ? 0 : sum
    }
    
    // Group meals by meal type
    var groupedMeals: [String: [Meal]] {
        Dictionary(grouping: filteredMeals) { meal in
            meal.mealtype ?? "Other"
        }
    }
    
    // Sorted meal types for display
    var sortedMealTypes: [String] {
        groupedMeals.keys.sorted()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(colorScheme == .dark ? .black : .white)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerSection
                    dateSelector
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                    
                    if searchText.isEmpty && filterMealType == nil {
                        dailySummary
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                    }
                    
                    filterRow
                        .padding(.horizontal)
                    searchBar
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                    mealsList
                    Spacer()
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        addButton
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
            .sheet(isPresented: $showingAddView) {
                AddMealView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(item: $mealToEdit) { meal in
                AddMealView(mealToEdit: meal)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterView(selectedMealType: $filterMealType)
            }
            .onChange(of: selectedDate) { newDate in
                updateFetchRequest()
            }
            .navigationDestination(isPresented: $showingStatistics) {
                StatisticsView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    // MARK: - View Components
    
    var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("My Meals")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.leading)
                
                Spacer()
                
                Button(action: {
                    showFilterSheet = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .padding(.trailing)
                }
            }
            .padding(.vertical, 10)
            
            Divider()
        }
        .background(Color(colorScheme == .dark ? .black : .white))
    }
    
    var dateSelector: some View {
        HStack {
            Button(action: {
                withAnimation {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? Date()
                }
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
            
            Spacer()
            
            Button(action: {
                showDatePicker.toggle()
            }) {
                HStack {
                    Text(formattedDate(normalizedSelectedDate))
                        .font(.headline)
                    
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            .popover(isPresented: $showDatePicker) {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .onChange(of: selectedDate) { _ in
                        selectedDate = normalizedSelectedDate
                    }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? Date()
                }
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
        }
    }
    
    var dailySummary: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Daily Total")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(Int(totalCalories)) calories")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(lineWidth: 10)
                        .opacity(0.3)
                        .foregroundColor(.blue)
                    
                    Circle()
                        .trim(from: 0.0, to: min(CGFloat(totalCalories) / 2000, 1.0))
                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                        .foregroundColor(calorieColor)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear, value: totalCalories)
                    
                    VStack {
                        Text("Goal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("2000")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 60, height: 60)
            }
            
            HStack(spacing: 10) {
                macroNutrientView(value: totalProtein, title: "Protein", color: .blue, unit: "g")
                macroNutrientView(value: totalCarbs, title: "Carbs", color: .green, unit: "g")
                macroNutrientView(value: totalFat, title: "Fat", color: .yellow, unit: "g")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .onTapGesture(count: 2) {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            showingStatistics = true
        }
    }
    
    var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: {
                    filterMealType = nil
                }) {
                    HStack {
                        Image(systemName: "chevron.down.circle")
                        Text("All")
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(filterMealType == nil ? Color.blue : Color.gray.opacity(0.1))
                    .foregroundColor(filterMealType == nil ? .white : .primary)
                    .cornerRadius(20)
                }
                
                ForEach(["Breakfast", "Lunch", "Dinner", "Snack"], id: \.self) { mealType in
                    Button(action: {
                        filterMealType = mealType == filterMealType ? nil : mealType
                    }) {
                        HStack {
                            Image(systemName: getMealTypeIcon(mealType))
                            Text(mealType)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(filterMealType == mealType ? Color.blue : Color.gray.opacity(0.1))
                        .foregroundColor(filterMealType == mealType ? .white : .primary)
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search meals", text: $searchText)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(10)
    }
    
    var mealsList: some View {
        List {
            ForEach(sortedMealTypes, id: \.self) { mealType in
                if let meals = groupedMeals[mealType], !meals.isEmpty {
                    Section(header: HStack {
                        Image(systemName: getMealTypeIcon(mealType))
                            .foregroundColor(.blue)
                        Text(mealType)
                            .font(.headline)
                        Spacer()
                        Text("\(meals.reduce(0) { $0 + Int($1.calories) }) cal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }) {
                        ForEach(meals, id: \.self) { meal in
                            MealRowView(meal: meal)
                                .onTapGesture {
                                    mealToEdit = meal
                                }
                        }
                        .onDelete { offsets in
                            deleteItems(offsets: offsets, for: meals)
                        }
                    }
                }
            }
            if filteredMeals.isEmpty {
                noMealsView
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .animation(.default, value: filteredMeals.count)
    }
    
    var noMealsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(searchText.isEmpty ? "No meals recorded for this day" : "No meals match your search")
                .font(.headline)
                .foregroundColor(.gray)
            
            Button(action: {
                showingAddView = true
            }) {
                Text("Add a meal")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
    
    var addButton: some View {
        Button(action: {
            showingAddView = true
        }) {
            Image(systemName: "plus")
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
        }
    }
    
    // MARK: - Helper Methods
    
    func macroNutrientView(value: Double, title: String, color: Color, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline) {
                Text("\(Int(value))")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 5)
                        .opacity(0.3)
                        .foregroundColor(color)
                    
                    Rectangle()
                        .frame(width: min(CGFloat(value) / 100 * geometry.size.width, geometry.size.width), height: 5)
                        .foregroundColor(color)
                }
                .cornerRadius(2.5)
            }
            .frame(height: 5)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }
    
    func formattedDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }
        if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        }
        if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    func getMealTypeIcon(_ mealType: String) -> String {
        switch mealType {
        case "Breakfast": return "sunrise"
        case "Lunch": return "sun.max"
        case "Dinner": return "moon.stars"
        case "Snack": return "cup.and.saucer"
        default: return "fork.knife"
        }
    }
    
    var calorieColor: Color {
        let ratio = totalCalories / 2000
        if ratio < 0.7 { return .green }
        else if ratio < 0.9 { return .yellow }
        else { return .red }
    }
    
    private func deleteItems(offsets: IndexSet, for meals: [Meal]) {
        withAnimation(.easeInOut) {
            // Provide haptic feedback
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.impactOccurred()
            
            // Log meals to be deleted
            let mealsToDelete = offsets.map { meals[$0] }
            print("Deleting meals: \(mealsToDelete.map { $0.name ?? "Unnamed" })")
            
            // Delete meals from Core Data
            mealsToDelete.forEach(viewContext.delete)
            
            // Save context
            do {
                try viewContext.save()
                print("Successfully deleted meals and saved context")
            } catch {
                print("Failed to delete meals: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateFetchRequest() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)

        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        mealsForSelectedDay.nsPredicate = predicate
    }
}

// MARK: - Supporting Views

struct MealRowView: View {
    let meal: Meal
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 15) {
            // Meal image or placeholder
            if let imageData = meal.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "fork.knife")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name ?? "Unnamed Meal")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    if let category = meal.toCategory {
                        HStack(spacing: 4) {
                            Image(systemName: category.iconName ?? "tag")
                                .foregroundColor(.blue)
                                .font(.caption)
                            
                            Text(category.name ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("·")
                        .foregroundColor(.gray)
                    
                    Text(formatMealTime(meal.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(meal.calories))")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("cal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
    }
    
    func formatMealTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct FilterView: View {
    @Binding var selectedMealType: String?
    @Environment(\.dismiss) var dismiss
    
    let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    
    var body: some View {
        NavigationStack {
            List {
                Button("All Meals") {
                    selectedMealType = nil
                    dismiss()
                }
                
                ForEach(mealTypes, id: \.self) { type in
                    Button {
                        selectedMealType = type
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: getMealTypeIcon(type))
                                .foregroundColor(.blue)
                            
                            Text(type)
                            
                            Spacer()
                            
                            if selectedMealType == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func getMealTypeIcon(_ mealType: String) -> String {
        switch mealType {
        case "Breakfast": return "sunrise"
        case "Lunch": return "sun.max"
        case "Dinner": return "moon.stars"
        case "Snack": return "cup.and.saucer"
        default: return "fork.knife"
        }
    }
}
