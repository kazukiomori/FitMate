//
//  GoalSettingView.swift
//  FitMate
//

import SwiftUI

struct GoalSettingView: View {
    @EnvironmentObject var user: User
    
    var body: some View {
        VStack(spacing: 25) {
            Text("目標を設定")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("目標体重: \(String(format: "%.1f", user.targetWeight))kg")
                Slider(value: $user.targetWeight, in: 40...120, step: 0.1)
                
                Text("活動レベル")
                Picker("活動レベル", selection: $user.activityLevel) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // 推奨カロリー計算表示
                VStack(alignment: .leading, spacing: 10) {
                    Text("推奨設定")
                        .font(.headline)
                    
                    HStack {
                        Text("1日の目標カロリー:")
                        Spacer()
                        Text("\(user.calculateDailyCalories())kcal")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("週の減量目標:")
                        Spacer()
                        Text("0.5kg")
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
}
