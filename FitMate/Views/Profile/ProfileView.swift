//
//  ProfileView.swift
//  FitMate
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var user: User
    
    var body: some View {
        NavigationView {
            List {
                Section("基本情報") {
                    HStack {
                        Text("年齢")
                        Spacer()
                        Text("\(user.age)歳")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("身長")
                        Spacer()
                        Text("\(Int(user.height))cm")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("現在の体重")
                        Spacer()
                        Text("\(String(format: "%.1f", user.currentWeight))kg")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("目標体重")
                        Spacer()
                        Text("\(String(format: "%.1f", user.targetWeight))kg")
                            .foregroundColor(.gray)
                    }
                }
                
                Section("設定") {
                    NavigationLink(destination: GoalSettingView().environmentObject(user)) {
                        HStack {
                            Image(systemName: "target")
                            Text("目標を修正")
                        }
                    }
                    
                    HStack {
                        Image(systemName: "bell")
                        Text("通知設定")
                    }
                    
                    HStack {
                        Image(systemName: "lock")
                        Text("プライバシー")
                    }
                    
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("ヘルプ")
                    }
                }
            }
            .navigationTitle("プロフィール")
        }
    }
}
