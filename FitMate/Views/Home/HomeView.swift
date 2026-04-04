//
//  HomeView.swift
//  FitMate
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var user: User
    @EnvironmentObject var recordViewModel: RecordViewModel
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var targetCalories = 1800

    private let today: Date = Calendar.current.startOfDay(for: Date())

    private var consumedCaloriesToday: Int {
        recordViewModel.dailyRecords
            .first { Calendar.current.isDate($0.date, inSameDayAs: today) }?
            .totalCalories ?? 0
    }

    private var calorieProgress: Double {
        guard targetCalories > 0 else { return 0 }
        return min(Double(consumedCaloriesToday) / Double(targetCalories), 1.0)
    }

    private var remainingCalories: Int {
        max(targetCalories - consumedCaloriesToday, 0)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let trainer = user.personalTrainer {
                        TrainerSupportBanner(trainer: trainer)
                    }

                    // 今日の概要カード
                    VStack(spacing: 15) {
                        HStack {
                            Text("今日の進捗")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Text(dateFormatter.string(from: today))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // カロリー円グラフ風
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 15)
                                .frame(width: 150, height: 150)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(calorieProgress))
                                .stroke(
                                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    style: StrokeStyle(lineWidth: 15, lineCap: .round)
                                )
                                .frame(width: 150, height: 150)
                                .rotationEffect(.degrees(-90))
                            
                            VStack {
                                Text("\(consumedCaloriesToday)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("/ \(targetCalories)kcal")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            StatCard(
                                title: "残り",
                                value: "\(remainingCalories)kcal",
                                color: .green
                            )
                            StatCard(
                                title: "消費",
                                value: "\(Int(healthKitManager.activeEnergyBurned))kcal",
                                color: .red
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
            .navigationTitle("FitMate")
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

private struct TrainerSupportBanner: View {
    let trainer: PersonalTrainer

    var body: some View {
        HStack(spacing: 16) {
            trainerImage

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("今日のひとこと")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.pink)

                        Text(trainer.name.isEmpty ? "あなたのトレーナー" : trainer.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "sun.max.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                        .padding(8)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Circle())
                }

                Text("「\(trainer.getTodaysMessage())」")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(red: 1.0, green: 0.97, blue: 0.92))

                            TrainerSpeechBubbleTail()
                                .fill(Color(red: 1.0, green: 0.97, blue: 0.92))
                                .frame(width: 14, height: 18)
                                .offset(x: -8, y: 8)
                        }
                    )

                Text("毎日あなたに合わせて応援します")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    Color.white,
                    Color(red: 1.0, green: 0.98, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.orange.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var trainerImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.98, green: 0.94, blue: 0.95))

            if let image = trainer.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(8)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.rectangle")
                        .font(.system(size: 34))
                        .foregroundColor(.pink.opacity(0.7))

                    Text("Trainer")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 112, height: 150)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

private struct TrainerSpeechBubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
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
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
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

