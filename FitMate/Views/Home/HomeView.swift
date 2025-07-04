//
//  HomeView.swift
//  FitMate
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var user: User
    @StateObject private var healthKitManager = HealthKitManager()
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
                        
                        HStack(spacing: 20) {
                            StatCard(
                                title: "残り",
                                value: "\(targetCalories - todayCalories)kcal",
                                color: .green
                            )
                            StatCard(
                                title: "消費",
                                value: "\(Int(healthKitManager.activeEnergyBurned))kcal",
                                color: .red
                            )
                            StatCard(
                                title: "水分",
                                value: "1.2L",
                                color: .blue
                            )
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    
                    // HealthKit活動データ
                    HealthActivityCard(healthKitManager: healthKitManager)
                    
                    // 今日のおすすめ
                    VStack(alignment: .leading, spacing: 15) {
                        Text("今日のおすすめ")
                            .font(.headline)
                        
                        RecommendationCard(
                            icon: "leaf.fill",
                            title: "野菜を多めに",
                            description: "今日はビタミンが不足気味です"
                        )
                        
                        // HealthKitデータに基づく提案
                        if healthKitManager.stepCount < 8000 {
                            RecommendationCard(
                                icon: "figure.walk",
                                title: "散歩の時間",
                                description: "目標まであと\(8000 - healthKitManager.stepCount)歩です"
                            )
                        }
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
            .refreshable {
                healthKitManager.refreshHealthData()
            }
        }
        .onAppear {
            healthKitManager.fetchTodayHealthData()
        }
    }
}

struct HealthActivityCard: View {
    @ObservedObject var healthKitManager: HealthKitManager
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("今日の活動")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    healthKitManager.refreshHealthData()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
            }
            
            if healthKitManager.isAuthorized {
                VStack(spacing: 20) {
                    // 歩数表示
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "figure.walk")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                Text("歩数")
                                    .font(.headline)
                            }
                            
                            Text("\(healthKitManager.stepCount)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            
                            // 目標達成率
                            let stepGoal = 8000
                            let stepProgress = min(Double(healthKitManager.stepCount) / Double(stepGoal), 1.0)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("目標: \(stepGoal)歩")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                ProgressView(value: stepProgress)
                                    .accentColor(.green)
                                    .frame(height: 6)
                                
                                Text("\(Int(stepProgress * 100))%達成")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                        
                        // 消費カロリー表示
                        VStack(alignment: .trailing) {
                            HStack {
                                Text("消費カロリー")
                                    .font(.headline)
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                            }
                            
                            Text("\(Int(healthKitManager.activeEnergyBurned))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            
                            Text("kcal")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // 活動レベル表示
                    HStack {
                        VStack(alignment: .leading) {
                            Text("活動レベル")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            let activityLevel = getActivityLevel()
                            HStack {
                                Text(activityLevel.title)
                                    .font(.headline)
                                    .foregroundColor(activityLevel.color)
                                
                                Circle()
                                    .fill(activityLevel.color)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("推定距離")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            let distance = Double(healthKitManager.stepCount) * 0.0008 // 1歩≈0.8m
                            Text(String(format: "%.1f km", distance))
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    
                    Text("HealthKitへのアクセス許可が必要です")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("設定 > プライバシーとセキュリティ > ヘルスケアから許可してください")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
    
    private func getActivityLevel() -> (title: String, color: Color) {
        let steps = healthKitManager.stepCount
        let calories = healthKitManager.activeEnergyBurned
        
        if steps >= 10000 || calories >= 400 {
            return ("とても活発", .green)
        } else if steps >= 7000 || calories >= 300 {
            return ("活発", .orange)
        } else if steps >= 5000 || calories >= 200 {
            return ("普通", .yellow)
        } else {
            return ("運動不足", .red)
        }
    }
}
