//
//  HomeView.swift
//  FitMate
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var user: User
    @State private var todayCalories = 1200
    @State private var targetCalories = 1800
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 今日の概要カード
                    VStack(spacing: 15) {
                        Text("今日の進捗")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // カロリー円グラフ風
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 15)
                                .frame(width: 150, height: 150)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(todayCalories) / CGFloat(targetCalories))
                                .stroke(
                                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    style: StrokeStyle(lineWidth: 15, lineCap: .round)
                                )
                                .frame(width: 150, height: 150)
                                .rotationEffect(.degrees(-90))
                            
                            VStack {
                                Text("\(todayCalories)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("/ \(targetCalories)kcal")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        HStack(spacing: 30) {
                            StatCard(title: "残り", value: "\(targetCalories - todayCalories)kcal", color: .green)
                            StatCard(title: "歩数", value: "8,234歩", color: .orange)
                            StatCard(title: "水分", value: "1.2L", color: .blue)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    
                    // 今日のおすすめ
                    VStack(alignment: .leading, spacing: 15) {
                        Text("今日のおすすめ")
                            .font(.headline)
                        
                        RecommendationCard(
                            icon: "leaf.fill",
                            title: "野菜を多めに",
                            description: "今日はビタミンが不足気味です"
                        )
                        
                        RecommendationCard(
                            icon: "figure.walk",
                            title: "散歩の時間",
                            description: "天気が良いので30分歩きませんか？"
                        )
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                }
                .padding()
            }
            .navigationTitle("HealthyLife")
            .background(Color.gray.opacity(0.1))
        }
    }
}

