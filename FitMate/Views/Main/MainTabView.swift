//
//  MainTabView.swift
//  FitMate
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var user: User
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
            
            FoodLogView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("食事")
                }
            
            ProgressChartView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("進捗")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("プロフィール")
                }
        }
        .environmentObject(user)
    }
}
