//
//  ProfileSetupView.swift
//  FitMate
//

import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var user: User
    
    var body: some View {
        VStack(spacing: 25) {
            Text("基本情報を入力")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("年齢: \(Int(user.age))歳")
                Slider(value: Binding(
                    get: { Double(user.age) },
                    set: { user.age = Int($0) }
                ), in: 18...80, step: 1)
                
                Text("性別")
                Picker("性別", selection: $user.gender) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Text(gender.rawValue).tag(gender)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Text("身長: \(Int(user.height))cm")
                Slider(value: $user.height, in: 140...200, step: 1)
                
                Text("現在の体重: \(String(format: "%.1f", user.currentWeight))kg")
                Slider(value: $user.currentWeight, in: 40...120, step: 0.1)
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
}

