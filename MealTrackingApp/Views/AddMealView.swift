import SwiftUI
import CoreData
import PhotosUI

struct AddMealView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    @State private var navigateToMealList = false // Stan do nawigacji
    
    @State private var mealName = ""
    @State private var calories = 0.0
    @State private var date = Date()
    @State private var selectedCategory: Category?
    
    @State private var mealType = "Lunch"
    @State private var protein = 0.0
    @State private var carbs = 0.0
    @State private var fat = 0.0
    @State private var notes = ""
    
    // UI control states
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var expandedSection: String? = "Basic"
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedUIImage: UIImage?
    @State private var isShowingFavorites = false
    @State private var searchText = ""
    
    // Recent foods list for quick adding
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Meal.date, ascending: false)],
        predicate: NSPredicate(format: "date >= %@", Date().addingTimeInterval(-60*60*24*14) as NSDate),
        animation: .default
    ) private var recentMeals: FetchedResults<Meal>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default
    ) private var categories: FetchedResults<Category>
    
    let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    let accentColor = Color.blue
    
    var mealToEdit: Meal?
    
    var body: some View {
        NavigationStack { // Używamy NavigationStack dla nawigacji
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        searchBar
                        
                        if isShowingFavorites {
                            recentFoodsGrid
                        } else {
                            mealFormSections
                        }
                        
                        Spacer(minLength: 60)
                    }
                    .padding()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(mealToEdit == nil ? "Add Meal" : "Edit Meal")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isShowingFavorites.toggle()
                        }) {
                            Label(
                                isShowingFavorites ? "Form View" : "Recent Meals",
                                systemImage: isShowingFavorites ? "square.and.pencil" : "clock"
                            )
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    saveButton
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Invalid Input"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                if let meal = mealToEdit {
                    mealName = meal.name ?? ""
                    calories = meal.calories
                    date = meal.date ?? Date()
                    selectedCategory = meal.toCategory
                    mealType = meal.mealtype ?? "Lunch"
                    protein = meal.protein
                    carbs = meal.carbs
                    fat = meal.fat
                    notes = meal.notes ?? ""
                    if let imageData = meal.imageData {
                        selectedUIImage = UIImage(data: imageData)
                    }
                }
            }
            // Nawigacja do MealListView
            .navigationDestination(isPresented: $navigateToMealList) {
                MealListView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    // MARK: - Sub Views
    
    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.black : Color.white,
                colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.95)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var headerView: some View {
        VStack(spacing: 5) {
            if !isShowingFavorites {
                HStack {
                    ForEach(mealTypes, id: \.self) { type in
                        Button(action: {
                            mealType = type
                        }) {
                            VStack {
                                Image(systemName: mealTypeIcon(type))
                                    .font(.system(size: 18))
                                Text(type)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(mealType == type ?
                                        accentColor.opacity(0.2) :
                                        Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(mealType == type ? accentColor : .primary)
                        }
                    }
                }
                .padding(.bottom, 5)
            }
        }
    }
    
    var searchBar: some View {
        Group {
            if isShowingFavorites {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search recent meals", text: $searchText)
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
                .cornerRadius(12)
            }
        }
    }
    
    var mealFormSections: some View {
        VStack(spacing: 20) {
            formCard("Basic") {
                basicInfoSection
            }
            
            formCard("Nutritional Info") {
                nutritionalInfoSection
            }
            
            // Kategoria usunięta, ponieważ nie jest używana w formularzu
            // Jeśli chcesz dodać wybór kategorii, musisz stworzyć odpowiedni interfejs
            
            formCard("Details") {
                detailsSection
            }
            
            formCard("Photo") {
                photoSection
            }
        }
    }
    
    var basicInfoSection: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundColor(.gray)
                    .frame(width: 20)
                TextField("Meal name", text: $mealName)
                    .font(.body)
            }
            .padding(.vertical, 5)
            
            Divider()
            
            HStack {
                Image(systemName: "flame")
                    .foregroundColor(.orange)
                    .frame(width: 20)
                
                Text("Calories:")
                
                Spacer()
                
                HStack(spacing: 15) {
                    Button(action: { adjustCalories(-10) }) {
                        Text("-10")
                            .font(.caption)
                            .padding(.horizontal, 2)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(5)
                    }
                    
                    Button(action: { adjustCalories(-100) }) {
                        Text("-100")
                            .font(.caption)
                            .padding(.horizontal, 2)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(5)
                    }
                    
                    TextField("0", value: $calories, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 60)
                        .padding(.vertical, 5)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    Button(action: { adjustCalories(100) }) {
                        Text("+100")
                            .font(.caption)
                            .padding(.horizontal, 2)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(5)
                    }
                    
                    Button(action: { adjustCalories(10) }) {
                        Text("+10")
                            .font(.caption)
                            .padding(.horizontal, 2)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(5)
                    }
                }
            }
            .padding(.vertical, 5)
            
            Divider()
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                DatePicker("Date & Time", selection: $date)
                    .labelsHidden()
            }
            .padding(.vertical, 5)
        }
    }
    
    var nutritionalInfoSection: some View {
        VStack(spacing: 15) {
            macroSlider(title: "Protein", value: $protein, color: .blue, icon: "p.circle")
            Divider()
            macroSlider(title: "Carbs", value: $carbs, color: .green, icon: "c.circle")
            Divider()
            macroSlider(title: "Fat", value: $fat, color: .yellow, icon: "f.circle")
        }
    }
    
    var detailsSection: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                TextField("Add notes (optional)", text: $notes)
                    .font(.body)
            }
            .padding(.vertical, 5)
        }
    }
    
    var photoSection: some View {
        VStack {
            if let image = selectedUIImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding(.vertical, 5)
                
                Button(action: {
                    selectedUIImage = nil
                    selectedPhoto = nil
                }) {
                    Text("Remove photo")
                        .foregroundColor(.red)
                }
                .padding(.top, 5)
            } else {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    VStack {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Add Photo")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .onChange(of: selectedPhoto) { newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            selectedUIImage = uiImage
                        }
                    }
                }
            }
        }
    }
    
    var recentFoodsGrid: some View {
        let filteredMeals = recentMeals.filter { meal in
            if searchText.isEmpty { return true }
            return (meal.name?.lowercased() ?? "").contains(searchText.lowercased())
        }
        
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            ForEach(filteredMeals) { meal in
                Button(action: {
                    mealName = meal.name ?? ""
                    calories = meal.calories
                    selectedCategory = meal.toCategory
                    mealType = meal.mealtype ?? "Lunch"
                    protein = meal.protein
                    carbs = meal.carbs
                    fat = meal.fat
                    notes = meal.notes ?? ""
                    if let imageData = meal.imageData {
                        selectedUIImage = UIImage(data: imageData)
                    }
                    isShowingFavorites = false
                }) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Image(systemName: getCategoryIcon(for: meal))
                                .foregroundColor(accentColor)
                            
                            Text(meal.name ?? "Unnamed")
                                .fontWeight(.medium)
                                .lineLimit(1)
                        }
                        
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            
                            Text("\(Int(meal.calories)) cal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(meal.mealtype ?? "Meal")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
        .padding(.top, 5)
    }
    
    var saveButton: some View {
        Button(action: {
            guard validateInput() else {
                alertMessage = "Please provide a valid meal name and positive calories."
                showAlert = true
                return
            }
            saveOrUpdateMeal()
            clearForm() // Czyścimy formularz
            navigateToMealList = true // Aktywujemy nawigację
        }) {
            Text(mealToEdit == nil ? "Add Meal" : "Save Changes")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(accentColor)
                .cornerRadius(15)
                .padding(.horizontal)
                .shadow(color: accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.bottom)
    }
    
    // MARK: - Helper Functions
    
    func formCard(_ title: String, @ViewBuilder content: @escaping () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Button(action: {
                withAnimation(.spring()) {
                    expandedSection = expandedSection == title ? nil : title
                }
            }) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: expandedSection == title ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                .padding(.bottom, 5)
            }
            
            if expandedSection == title {
                content()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    func macroSlider(title: String, value: Binding<Double>, color: Color, icon: String) -> some View {
        VStack(spacing: 5) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                
                Spacer()
                
                Text("\(Int(value.wrappedValue))g")
                    .fontWeight(.medium)
            }
            
            HStack {
                Slider(value: value, in: 0...150, step: 1)
                    .accentColor(color)
                
                Button(action: {
                    value.wrappedValue = 0
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 5)
    }
    
    func adjustCalories(_ amount: Double) {
        calories = max(0, calories + amount)
    }
    
    func mealTypeIcon(_ type: String) -> String {
        switch type {
        case "Breakfast": return "sunrise"
        case "Lunch": return "sun.max"
        case "Dinner": return "moon.stars"
        case "Snack": return "cup.and.saucer"
        default: return "fork.knife"
        }
    }
    
    func getCategoryIcon(for meal: Meal) -> String {
        return meal.toCategory?.iconName ?? "tag"
    }
    
    // MARK: - Data Handling
    
    private func validateInput() -> Bool {
        guard !mealName.isEmpty else { return false }
        guard calories > 0, !calories.isNaN else { return false }
        guard !protein.isNaN, protein >= 0 else { return false }
        guard !carbs.isNaN, carbs >= 0 else { return false }
        guard !fat.isNaN, fat >= 0 else { return false }
        return true
    }
    
    private func saveOrUpdateMeal() {
        let meal: Meal
        if let mealToEdit = mealToEdit {
            meal = mealToEdit
        } else {
            meal = Meal(context: viewContext)
        }
        
        meal.name = mealName
        meal.calories = calories
        meal.date = Calendar.current.startOfDay(for: date)
        meal.toCategory = selectedCategory
        meal.mealtype = mealType
        meal.protein = protein
        meal.carbs = carbs
        meal.fat = fat
        meal.notes = notes.isEmpty ? nil : notes
        meal.imageData = selectedUIImage?.jpegData(compressionQuality: 0.7)
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save meal: \(error)")
            alertMessage = "Failed to save meal. Please try again."
            showAlert = true
        }
    }
    
    // Funkcja do czyszczenia formularza
    private func clearForm() {
        mealName = ""
        calories = 0.0
        date = Date()
        selectedCategory = nil
        mealType = "Lunch"
        protein = 0.0
        carbs = 0.0
        fat = 0.0
        notes = ""
        selectedPhoto = nil
        selectedUIImage = nil
        searchText = ""
        isShowingFavorites = false
    }
}
