//
//  HomeView.swift
//  FitMate
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var user: User
    @AppStorage("lastHomeOpenedDayKey") private var lastHomeOpenedDayKey: String = ""
    @State private var isFirstHomeOpenToday = false
    @State private var userMessage: String = ""
    @FocusState private var isMessageFieldFocused: Bool

    private var dayKeyFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private var todayDayKey: String {
        dayKeyFormatter.string(from: Date())
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let trainer = user.personalTrainer {
                        TrainerConversationSection(
                            trainer: trainer,
                            isFirstOpenToday: isFirstHomeOpenToday,
                            userMessage: $userMessage,
                            isMessageFieldFocused: $isMessageFieldFocused
                        )
                    }
                }
                .padding()
            }
            .background(Color.gray.opacity(0.1))
            .simultaneousGesture(
                TapGesture().onEnded {
                    isMessageFieldFocused = false
                }
            )
        }
        .onAppear {
            updateHomeOpenState()
        }
    }

    private func updateHomeOpenState() {
        isFirstHomeOpenToday = lastHomeOpenedDayKey != todayDayKey

        if isFirstHomeOpenToday {
            lastHomeOpenedDayKey = todayDayKey
        }
    }
}

private struct TrainerConversationSection: View {
    let trainer: PersonalTrainer
    let isFirstOpenToday: Bool
    @Binding var userMessage: String
    @FocusState.Binding var isMessageFieldFocused: Bool

    private var trainerMessage: String {
        trainer.getHomeMessage(isFirstOpenToday: isFirstOpenToday)
    }

    var body: some View {
        VStack(spacing: 18) {
            trainerHeroImage

            VStack(spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    trainerAvatar

                    VStack(alignment: .leading, spacing: 8) {
                        Text(trainer.name.isEmpty ? "あなたのトレーナー" : trainer.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(trainerMessage)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineSpacing(5)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.white)

                            TrainerSpeechBubbleTail()
                                .fill(Color.white)
                                .frame(width: 14, height: 18)
                                .offset(x: -8, y: 10)
                        }
                    )

                    Spacer(minLength: 0)
                }

                HStack(alignment: .bottom, spacing: 12) {
                    Spacer(minLength: 32)

                    HStack(spacing: 10) {
                        TextField("今日の相談や気持ちを入力してください", text: $userMessage, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(2...4)
                            .focused($isMessageFieldFocused)

                        Button(action: {
                            isMessageFieldFocused = false
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 38, height: 38)
                                .background(Color.black)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.97, green: 0.97, blue: 0.98))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                }
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.97, blue: 0.95),
                    Color(red: 0.95, green: 0.96, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }

    private var trainerHeroImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.90, blue: 0.90),
                            Color(red: 0.96, green: 0.95, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let image = trainer.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.rectangle")
                        .font(.system(size: 42))
                        .foregroundColor(.pink.opacity(0.7))

                    Text("Trainer")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.2)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
        )
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 4) {
                Text(isFirstOpenToday ? "今日のあいさつ" : "トレーナーチャット")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))

                Text(trainer.name.isEmpty ? "あなたのトレーナー" : trainer.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(18)
        }
    }

    private var trainerAvatar: some View {
        Group {
            if let image = trainer.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .foregroundColor(.pink.opacity(0.8))
                    .background(Color.white)
            }
        }
        .frame(width: 48, height: 48)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 2)
        )
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

                            let distance = Double(healthKitManager.stepCount) * 0.0008
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

