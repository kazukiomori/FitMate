//
//  FoodAddView.swift
//  FitMate
//

import SwiftUI

import SwiftUI

struct FoodAddView: View {
    @ObservedObject var recordViewModel: RecordViewModel
    let selectedMeal: MealType
    @State private var foodName = ""
    @State private var calories = ""
    @State private var selectedDate = Date()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // カメラボタン
                Button(action: {
                    // TODO: カメラ機能実装
                }) {
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
                    
                    Text("日時")
                        .font(.headline)
                    DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                }
                
                Spacer()
                
                Button("追加") {
                    if !foodName.isEmpty, let cal = Int(calories) {
                        let newEntry = FoodEntry(
                            name: foodName,
                            calories: cal,
                            time: selectedDate,
                            mealType: selectedMeal
                        )
                        recordViewModel.addFoodEntry(newEntry)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .disabled(foodName.isEmpty || Int(calories) == nil)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(foodName.isEmpty || Int(calories) == nil ? Color.gray : Color.blue)
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
