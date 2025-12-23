//
//  FoodLogView.swift
//  FitMate
//

import SwiftUI

struct FoodLogView: View {
    @StateObject private var recordViewModel = RecordViewModel()
    @State private var selectedMeal: MealType = .breakfast
    @State private var showingFoodAdd = false
    
    // 今日の食事データ
    private var todayFoodEntries: [FoodEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return recordViewModel.dailyRecords
            .first { Calendar.current.isDate($0.date, inSameDayAs: today) }?
            .foodEntries ?? []
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 今日のカロリー概要
                TodayCaloriesSummary(foodEntries: todayFoodEntries)
                
                // 食事タイプ選択
                Picker("食事", selection: $selectedMeal) {
                    ForEach(MealType.allCases, id: \.self) { meal in
                        Text(meal.rawValue).tag(meal)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // 食事リスト
                List {
                    ForEach(todayFoodEntries.filter { $0.mealType == selectedMeal }) { entry in
                        FoodEntryRow(entry: entry)
                    }
                    .onDelete { indexSet in
                        // 削除機能（実装可能）
                    }
                }
                
                Spacer()
            }
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
        }
    }
}

struct TodayCaloriesSummary: View {
    let foodEntries: [FoodEntry]
    
    private let today: Date = Calendar.current.startOfDay(for: Date())
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
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
                Text("今日の摂取カロリー")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text(dateFormatter.string(from: today))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 総カロリー
            Text("\(totalCalories)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            // 食事別カロリー
            HStack(spacing: 20) {
                ForEach(MealType.allCases, id: \.self) { meal in
                    VStack {
                        Text(meal.rawValue)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(caloriesByMeal[meal] ?? 0)kcal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
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
