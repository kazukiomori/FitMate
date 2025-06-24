//
//  FoodAddView.swift
//  FitMate
//

import SwiftUI

struct FoodAddView: View {
    @Binding var foodEntries: [FoodEntry]
    let selectedMeal: MealType
    @State private var foodName = ""
    @State private var calories = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // カメラボタン
                Button(action: {}) {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                        Text("写真で記録")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
                }
                
                Text("または手動で入力")
                    .foregroundColor(.gray)
                
                // 手動入力
                VStack(alignment: .leading, spacing: 15) {
                    Text("食品名")
                        .font(.headline)
                    TextField("例: サラダ", text: $foodName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("カロリー")
                        .font(.headline)
                    TextField("例: 150", text: $calories)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                Spacer()
                
                Button("追加") {
                    if !foodName.isEmpty, let cal = Int(calories) {
                        let newEntry = FoodEntry(
                            name: foodName,
                            calories: cal,
                            time: Date(),
                            mealType: selectedMeal
                        )
                        foodEntries.append(newEntry)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding()
            .navigationTitle("食事を追加")
            .navigationBarItems(leading:
                Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
