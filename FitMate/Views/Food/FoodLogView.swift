//
//  FoodLogView.swift
//  FitMate
//

import SwiftUI

struct FoodLogView: View {
    @State private var selectedMeal: MealType = .breakfast
    @State private var showingFoodAdd = false
    @State private var foodEntries: [FoodEntry] = [
        FoodEntry(name: "ご飯", calories: 252, time: Date(), mealType: .breakfast),
        FoodEntry(name: "卵焼き", calories: 128, time: Date(), mealType: .breakfast)
    ]
    
    var body: some View {
        NavigationView {
            VStack {
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
                    ForEach(foodEntries.filter { $0.mealType == selectedMeal }) { entry in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entry.name)
                                    .font(.headline)
                                Text("\(entry.calories)kcal")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Text(entry.time, style: .time)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
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
                FoodAddView(foodEntries: $foodEntries, selectedMeal: selectedMeal)
            }
        }
    }
}
