//
//  FoodLogView.swift
//  FitMate
//

import SwiftUI

struct FoodLogView: View {
    @EnvironmentObject var recordViewModel: RecordViewModel
    @State private var selectedMeal: MealType = .breakfast
    @State private var showingFoodAdd = false
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var pendingDeleteEntry: FoodEntry?
    @State private var showingDeleteAlert = false
    
    // 選択日の食事データ
    private var entriesForSelectedDate: [FoodEntry] {
        return recordViewModel.dailyRecords
            .first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }?
            .foodEntries ?? []
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    MiniMonthCalendar(selectedDate: $selectedDate)
                        .padding(.vertical, 8)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                    DayCaloriesSummary(date: selectedDate, foodEntries: entriesForSelectedDate, weight: nil)
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 4)

                    Picker("食事", selection: $selectedMeal) {
                        ForEach(MealType.allCases, id: \.self) { meal in
                            Text(meal.title).tag(meal)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }

                Section {
                    let items = entriesForSelectedDate.filter { $0.mealType == selectedMeal }
                    if items.isEmpty {
                        Text("記録がありません")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(items) { entry in
                            FoodEntryRow(entry: entry)
                        }
                        .onDelete { indexSet in
                            guard let index = indexSet.first else { return }
                            pendingDeleteEntry = items[index]
                            showingDeleteAlert = true
                        }
                    }
                } header: {
                    Text("\(selectedMeal.title)の記録")
                }
            }
            .listStyle(.plain)
            .navigationTitle("食事記録")
            .navigationBarItems(trailing:
                Button(action: { showingFoodAdd = true }) {
                    Image(systemName: "plus")
                        .font(.title2)
                }
            )
            .sheet(isPresented: $showingFoodAdd) {
                FoodAddView(recordViewModel: recordViewModel, selectedMeal: selectedMeal)
            }
            .alert("削除しますか？", isPresented: $showingDeleteAlert) {
                Button("削除", role: .destructive) {
                    if let entry = pendingDeleteEntry {
                        recordViewModel.deleteFoodEntry(id: entry.id)
                    }
                    pendingDeleteEntry = nil
                }
                Button("キャンセル", role: .cancel) {
                    pendingDeleteEntry = nil
                }
            } message: {
                if let entry = pendingDeleteEntry {
                    Text("\(entry.name) を削除します")
                } else {
                    Text("この記録を削除します")
                }
            }
        }
    }
}

struct DayCaloriesSummary: View {
    let date: Date
    let foodEntries: [FoodEntry]
    let weight: Double?

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    private var totalCalories: Int {
        foodEntries.reduce(0) { $0 + $1.calories }
    }

    private var caloriesByMeal: [MealType: Int] {
        var result: [MealType: Int] = [:]
        for meal in MealType.allCases {
            result[meal] = foodEntries.filter { $0.mealType == meal }.reduce(0) { $0 + $1.calories }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("摂取カロリー")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text(dateFormatter.string(from: date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // 総カロリー
            Text("\(totalCalories) kcal")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)

            // 食事別カロリー
            HStack(spacing: 20) {
                ForEach(MealType.allCases, id: \.self) { meal in
                    VStack {
                        Text(meal.title)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(caloriesByMeal[meal] ?? 0)kcal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }

            if let weight {
                Divider()
                HStack {
                    Label("体重", systemImage: "scalemass")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.1f kg", weight))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

struct MiniMonthCalendar: View {
    @Binding var selectedDate: Date
    @State private var displayedDate: Date = Date()

    private let calendar = Calendar.current
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月"
        return f.string(from: displayedDate)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { changeMonth(-1) }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)

                Spacer()
                Text(monthTitle)
                    .font(.headline)
                Spacer()

                Button(action: { changeMonth(1) }) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
            }

            HStack {
                ForEach(weekdays, id: \.self) { w in
                    Text(w)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(daysForGrid(), id: \.self) { date in
                    DayCell(date: date,
                            isInMonth: calendar.isDate(date, equalTo: displayedDate, toGranularity: .month),
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate)) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = date
                        }
                    }
                }
            }
        }
        .onAppear { displayedDate = selectedDate }
    }

    private func changeMonth(_ delta: Int) {
        if let newDate = calendar.date(byAdding: .month, value: delta, to: displayedDate) {
            withAnimation(.easeInOut(duration: 0.25)) {
                displayedDate = newDate
            }
        }
    }

    private func daysForGrid() -> [Date] {
        let startOfMonth = calendar.dateInterval(of: .month, for: displayedDate)!.start
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startOfMonth))!
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private struct DayCell: View {
        let date: Date
        let isInMonth: Bool
        let isSelected: Bool
        let onTap: () -> Void

        private var dayString: String {
            let f = DateFormatter()
            f.dateFormat = "d"
            return f.string(from: date)
        }

        var body: some View {
            Button(action: onTap) {
                Text(dayString)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    .foregroundColor(fg)
                    .frame(height: 32)
                    .frame(maxWidth: .infinity)
                    .background(bg)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }

        private var fg: Color {
            if isSelected { return .white }
            return isInMonth ? .primary : .secondary.opacity(0.4)
        }
        private var bg: Color {
            if isSelected { return Color.blue }
            return Color.clear
        }
    }
}

struct FoodEntryRow: View {
    let entry: FoodEntry
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.headline)
                Text("\(entry.calories)kcal")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(timeFormatter.string(from: entry.time))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}
