import SwiftUI
import CoreData
import Charts

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    // Fetch all meals
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Meal.date, ascending: false)],
        animation: .default
    ) private var allMeals: FetchedResults<Meal>
    
    // State variables
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedChart: ChartType = .calories
    @State private var selectedMealType: String? = nil
    
    // Scale state for pinch gestures
    @State private var chartScale: CGFloat = 1.0
    @State private var lastScaleValue: CGFloat = 1.0
    
    // Enums for chart customization
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        
        var id: String { self.rawValue }
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }
    
    enum ChartType: String, CaseIterable, Identifiable {
        case calories = "Calories"
        case macros = "Macros"
        case mealTypes = "Meal Types"
        
        var id: String { self.rawValue }
    }
    
    // Computed properties for filtering and data processing
    private var filteredMeals: [Meal] {
        let startDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        
        return allMeals.filter { meal in
            guard let mealDate = meal.date else { return false }
            
            let matchesDate = mealDate >= startDate
            let matchesMealType = selectedMealType == nil || meal.mealtype == selectedMealType
            
            return matchesDate && matchesMealType
        }
    }
    
    // Data grouping by days
    private var mealsByDay: [Date: [Meal]] {
        let calendar = Calendar.current
        var result = [Date: [Meal]]()
        
        for meal in filteredMeals {
            if let date = meal.date {
                let day = calendar.startOfDay(for: date)
                if result[day] == nil {
                    result[day] = [meal]
                } else {
                    result[day]?.append(meal)
                }
            }
        }
        
        return result
    }
    
    // Summary statistics
    private var totalCalories: Double {
        filteredMeals.reduce(0) { $0 + $1.calories }
    }
    
    private var averageDailyCalories: Double {
        let days = mealsByDay.count
        return days > 0 ? totalCalories / Double(days) : 0
    }
    
    private var totalProtein: Double {
        filteredMeals.reduce(0) { $0 + $1.protein }
    }
    
    private var totalCarbs: Double {
        filteredMeals.reduce(0) { $0 + $1.carbs }
    }
    
    private var totalFat: Double {
        filteredMeals.reduce(0) { $0 + $1.fat }
    }
    
    // Calendar data for the chart
    private var dailyCaloriesData: [(date: Date, calories: Double)] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days + 1, to: Date()) ?? Date()
        
        var result = [(date: Date, calories: Double)]()
        
        // Create array of all dates in range
        var date = calendar.startOfDay(for: startDate)
        let endDate = calendar.startOfDay(for: Date())
        
        while date <= endDate {
            let calories = mealsByDay[date]?.reduce(0) { $0 + $1.calories } ?? 0
            result.append((date: date, calories: calories))
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return result
    }
    
    // Meal type distribution
    private var mealTypeDistribution: [(type: String, count: Int)] {
        var counts: [String: Int] = [:]
        
        for meal in filteredMeals {
            let type = meal.mealtype ?? "Other"
            counts[type, default: 0] += 1
        }
        
        return counts.map { (type: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    // Main view body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header stats
                    headerStats
                    
                    // Filter controls
                    filterOptions
                    
                    // Main chart section
                    chartSection
                    
                    // Additional statistics based on data
                    additionalStats
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .background(colorScheme == .dark ? Color.black : Color(white: 0.95))
        }
    }
    
    // MARK: - View Components
    
    // Header with summary statistics
    private var headerStats: some View {
        VStack(spacing: 15) {
            HStack {
                StatCardView(
                    title: "Total Meals",
                    value: "\(filteredMeals.count)",
                    icon: "fork.knife",
                    color: .blue
                )
                
                StatCardView(
                    title: "Avg. Daily Calories",
                    value: "\(Int(averageDailyCalories))",
                    icon: "flame.fill",
                    color: .orange
                )
            }
            
            HStack {
                StatCardView(
                    title: "Most Common",
                    value: "\(mealTypeDistribution.first?.type ?? "None")",
                    icon: "star.fill",
                    color: .yellow
                )
                
                StatCardView(
                    title: "Total Days",
                    value: "\(mealsByDay.count)",
                    icon: "calendar",
                    color: .green
                )
            }
        }
    }
    
    // Filter options for time range and meal type
    private var filterOptions: some View {
        VStack(spacing: 15) {
            // Time range selector
            HStack {
                Text("Time Range:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                ForEach(TimeRange.allCases) { range in
                    Button(action: {
                        withAnimation {
                            selectedTimeRange = range
                        }
                    }) {
                        Text(range.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTimeRange == range ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedTimeRange == range ? .white : .primary)
                            .cornerRadius(8)
                    }
                }
            }
            
            // Chart type selector
            HStack {
                Text("Chart:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Picker("Chart Type", selection: $selectedChart) {
                    ForEach(ChartType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.leading)
            }
            
            // Meal type filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button(action: {
                        selectedMealType = nil
                    }) {
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                            Text("All")
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(selectedMealType == nil ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedMealType == nil ? .white : .primary)
                        .cornerRadius(20)
                    }
                    
                    ForEach(["Breakfast", "Lunch", "Dinner", "Snack"], id: \.self) { mealType in
                        Button(action: {
                            selectedMealType = (selectedMealType == mealType) ? nil : mealType
                        }) {
                            HStack {
                                Image(systemName: getMealTypeIcon(mealType))
                                    .font(.system(size: 12))
                                Text(mealType)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(selectedMealType == mealType ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedMealType == mealType ? .white : .primary)
                            .cornerRadius(20)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // Main chart section
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(chartTitle)
                .font(.headline)
                .padding(.leading, 5)
            
            // Chart container with pinch zoom
            chartContent
                .frame(height: 300 * chartScale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScaleValue
                            lastScaleValue = value
                            let newScale = chartScale * delta
                            chartScale = min(max(newScale, 0.5), 3.0) // Limit scaling between 0.5x and 3x
                        }
                        .onEnded { _ in
                            lastScaleValue = 1.0
                        }
                )
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("Pinch to zoom")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .padding(8)
                        }
                    }
                )
        }
    }
    
    // Dynamic chart title based on selection
    private var chartTitle: String {
        switch selectedChart {
        case .calories:
            return "Daily Calorie Intake (\(selectedTimeRange.rawValue))"
        case .macros:
            return "Macronutrient Distribution"
        case .mealTypes:
            return "Meal Type Distribution"
        }
    }
    
    // Dynamic chart content based on selection
    @ViewBuilder
    private var chartContent: some View {
        switch selectedChart {
        case .calories:
            caloriesChart
        case .macros:
            macrosChart
        case .mealTypes:
            mealTypesChart
        }
    }
    
    // Calories chart
    private var caloriesChart: some View {
        Chart {
            ForEach(dailyCaloriesData, id: \.date) { item in
                BarMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Calories", item.calories)
                )
                .foregroundStyle(Color.blue.gradient)
                .cornerRadius(4)
            }
            
            // Target line at 2000 calories
            RuleMark(y: .value("Target", 2000))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .foregroundStyle(.red)
                .annotation(position: .top, alignment: .trailing) {
                    Text("Target")
                        .font(.caption)
                        .foregroundColor(.red)
                }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(formatAxisDate(date))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text("\(Int(val))")
                    }
                }
            }
        }
    }
    
    // Macros chart
    private var macrosChart: some View {
        Chart {
            BarMark(
                x: .value("Type", "Protein"),
                y: .value("Grams", totalProtein)
            )
            .foregroundStyle(.blue.gradient)
            
            BarMark(
                x: .value("Type", "Carbs"),
                y: .value("Grams", totalCarbs)
            )
            .foregroundStyle(.green.gradient)
            
            BarMark(
                x: .value("Type", "Fat"),
                y: .value("Grams", totalFat)
            )
            .foregroundStyle(.yellow.gradient)
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text("\(Int(val))g")
                    }
                }
            }
        }
    }
    
    // Meal types chart
    private var mealTypesChart: some View {
        Chart {
            ForEach(mealTypeDistribution.prefix(5), id: \.type) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .cornerRadius(5)
                .foregroundStyle(by: .value("Type", item.type))
                .annotation(position: .overlay) {
                    Text("\(item.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // Additional statistics section
    private var additionalStats: some View {
        VStack(spacing: 20) {
            // Macronutrient summary
            if selectedChart != .macros {
                macroSummary
            }
            
            // Meal count by type
            if selectedChart != .mealTypes {
                mealTypesSummary
            }
            
            // Insights based on data
            insightsSection
        }
    }
    
    // Macro summary
    private var macroSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Macronutrient Summary")
                .font(.headline)
                .padding(.leading, 5)
            
            HStack(spacing: 15) {
                MacroCardView(
                    title: "Protein",
                    value: "\(Int(totalProtein))g",
                    percentage: calculateMacroPercentage(totalProtein),
                    color: .blue
                )
                
                MacroCardView(
                    title: "Carbs",
                    value: "\(Int(totalCarbs))g",
                    percentage: calculateMacroPercentage(totalCarbs),
                    color: .green
                )
                
                MacroCardView(
                    title: "Fat",
                    value: "\(Int(totalFat))g",
                    percentage: calculateMacroPercentage(totalFat),
                    color: .yellow
                )
            }
        }
    }
    
    // Meal types summary
    private var mealTypesSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Meal Count by Type")
                .font(.headline)
                .padding(.leading, 5)
            
            VStack(spacing: 12) {
                ForEach(mealTypeDistribution.prefix(4), id: \.type) { item in
                    HStack {
                        Image(systemName: getMealTypeIcon(item.type))
                            .foregroundColor(.blue)
                            .frame(width: 25)
                        
                        Text(item.type)
                        
                        Spacer()
                        
                        Text("\(item.count)")
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // Insights section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Insights")
                .font(.headline)
                .padding(.leading, 5)
            
            VStack(spacing: 12) {
                insightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Consumption Pattern",
                    message: consumptionPatternInsight
                )
                
                insightCard(
                    icon: "flame",
                    title: "Calorie Trend",
                    message: calorieTrendInsight
                )
                
                insightCard(
                    icon: "chart.bar.fill",
                    title: "Meal Frequency",
                    message: mealFrequencyInsight
                )
            }
        }
    }
    
    // MARK: - Helper Views
    
    // Statistic card view
    private struct StatCardView: View {
        let title: String
        let value: String
        let icon: String
        let color: Color
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // Macro card view
    private struct MacroCardView: View {
        let title: String
        let value: String
        let percentage: Int
        let color: Color
        
        var body: some View {
            VStack(spacing: 5) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                
                Text("\(percentage)%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(height: 6)
                        .opacity(0.2)
                        .foregroundColor(color)
                    
                    Rectangle()
                        .frame(width: calculateWidth(percentage: percentage), height: 6)
                        .foregroundColor(color)
                }
                .cornerRadius(3)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        
        private func calculateWidth(percentage: Int) -> CGFloat {
            let maxWidth: CGFloat = 100
            return maxWidth * CGFloat(percentage) / 100
        }
    }
    
    // Insight card
    private func insightCard(icon: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Functions
    
    // Get appropriate icon for meal type
    private func getMealTypeIcon(_ mealType: String) -> String {
        switch mealType {
        case "Breakfast": return "sunrise"
        case "Lunch": return "sun.max"
        case "Dinner": return "moon.stars"
        case "Snack": return "cup.and.saucer"
        default: return "fork.knife"
        }
    }
    
    // Format date for chart axis
    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch selectedTimeRange {
        case .week:
            formatter.dateFormat = "E"
        case .month:
            formatter.dateFormat = "d"
        case .year:
            formatter.dateFormat = "MMM"
        }
        
        return formatter.string(from: date)
    }
    
    // Calculate macro percentage
    private func calculateMacroPercentage(_ value: Double) -> Int {
        let total = totalProtein + totalCarbs + totalFat
        guard total > 0 else { return 0 }
        return Int((value / total) * 100)
    }
    
    // Generate consumption pattern insight
    private var consumptionPatternInsight: String {
        let mostCommonMeal = mealTypeDistribution.first?.type ?? "meals"
        
        if mealTypeDistribution.first?.count ?? 0 > filteredMeals.count / 2 {
            return "You're having \(mostCommonMeal) more frequently than other meals."
        } else {
            return "Your meal distribution is relatively balanced across different types."
        }
    }
    
    // Generate calorie trend insight
    private var calorieTrendInsight: String {
        let averageDaily = averageDailyCalories
        
        if averageDaily < 1500 {
            return "Your average daily intake of \(Int(averageDaily)) calories is below the typical 2000 calorie recommendation."
        } else if averageDaily > 2500 {
            return "Your average daily intake of \(Int(averageDaily)) calories is above the typical 2000 calorie recommendation."
        } else {
            return "Your average daily intake of \(Int(averageDaily)) calories is within a healthy range."
        }
    }
    
    // Generate meal frequency insight
    private var mealFrequencyInsight: String {
        let mealCount = filteredMeals.count
        let dayCount = max(1, mealsByDay.count)
        let averageMealsPerDay = Double(mealCount) / Double(dayCount)
        
        if averageMealsPerDay < 2.5 {
            return "You're averaging \(String(format: "%.1f", averageMealsPerDay)) meals per day, which is on the lower side."
        } else if averageMealsPerDay > 4.5 {
            return "You're averaging \(String(format: "%.1f", averageMealsPerDay)) meals per day, including multiple snacks."
        } else {
            return "You're averaging \(String(format: "%.1f", averageMealsPerDay)) meals per day, which is typical."
        }
    }
}
