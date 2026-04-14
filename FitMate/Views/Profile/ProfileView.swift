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
                        Text("登録時の体重")
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

                    NavigationLink(destination: TrainerSelectionSettingsView().environmentObject(user)) {
                        HStack {
                            Image(systemName: "person.crop.rectangle")
                            Text("トレーナーを選び直す")
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
        }
    }
}

private struct TrainerSelectionSettingsView: View {
    @EnvironmentObject var user: User
    @Environment(\.dismiss) private var dismiss

    @State private var pendingTrainer: PersonalTrainer?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let trainer = user.personalTrainer {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("現在のトレーナー")
                            .font(.headline)

                        HStack(spacing: 14) {
                            currentTrainerImage(for: trainer)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(trainer.name.isEmpty ? "あなたのトレーナー" : trainer.name)
                                    .font(.headline)

                                Text(trainer.preferences.personality.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                }

                TrainerSetupView(
                    pendingTrainer: $pendingTrainer,
                    allowsReplacingExistingTrainer: true
                )
                .environmentObject(user)
            }
            .padding()
        }
        .background(Color.gray.opacity(0.08))
        .navigationTitle("トレーナー設定")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    guard let pendingTrainer else { return }
                    user.setPersonalTrainer(pendingTrainer)
                    dismiss()
                }
                .disabled(pendingTrainer == nil)
            }
        }
    }

    private func currentTrainerImage(for trainer: PersonalTrainer) -> some View {
        Group {
            if let image = trainer.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.12))
                    .overlay(
                        Image(systemName: "person.crop.rectangle")
                            .foregroundColor(.secondary)
                    )
            }
        }
        .frame(width: 72, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
