//
//  FeatureIntroView.swift
//  FitMate
//

import SwiftUI

struct FeatureIntroView: View {
    @State private var animateFeatures = false
    @State private var currentFeatureIndex = 0
    
    let features = [
        FeatureData(icon: "camera.fill", title: "AI食事認識", description: "写真を撮るだけで\n自動でカロリー計算", color: .pink),
        FeatureData(icon: "heart.text.square", title: "HealthKit連携", description: "歩数・消費カロリー\n自動で記録", color: .red),
        FeatureData(icon: "chart.line.uptrend.xyaxis", title: "スマート分析", description: "AIが進捗を分析\nアドバイスを提案", color: .blue),
        FeatureData(icon: "person.2.fill", title: "パーソナルトレーナー", description: "あなた専用の\nAIコーチがサポート", color: .green)
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 26) {
                OnboardingHeader(
                    title: "できることは、これだけ",
                    subtitle: "難しい操作はありません。\n写真や歩数は、できるだけ自動で。",
                    footnote: "完璧じゃなくてOK。続いた日がえらい"
                )

                // フィーチャーグリッド
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 15),
                    GridItem(.flexible(), spacing: 15)
                ], spacing: 20) {
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        ModernFeatureCard(
                            feature: feature,
                            delay: Double(index) * 0.1
                        )
                        .opacity(animateFeatures ? 1 : 0)
                        .offset(y: animateFeatures ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(Double(index) * 0.1), value: animateFeatures)
                    }
                }

                // 開始準備完了メッセージ
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)

                        Text("準備できたよ")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(AoiOnboardingTheme.textPrimary)
                    }

                    Text("今日の“できた”を、ひとつ増やそう")
                        .font(.subheadline)
                        .foregroundColor(AoiOnboardingTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(animateFeatures ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.6), value: animateFeatures)

                Spacer(minLength: 120)
            }
            .onboardingPagePadding()
        }
        .onAppear {
            animateFeatures = true
        }
    }
}

// MARK: - フィーチャーデータ
struct FeatureData {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - モダンフィーチャーカード
struct ModernFeatureCard: View {
    let feature: FeatureData
    let delay: Double
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 15) {
            // アイコン
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.12))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(feature.color.opacity(0.25), lineWidth: 2)
                    )
                
                Image(systemName: feature.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(feature.color)
            }
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isHovered)
            
            // テキスト
            VStack(spacing: 8) {
                Text(feature.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AoiOnboardingTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(AoiOnboardingTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .frame(height: 160)
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AoiOnboardingTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AoiOnboardingTheme.border, lineWidth: 1)
                )
        )
        .shadow(color: AoiOnboardingTheme.shadow, radius: 14, x: 0, y: 7)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isHovered)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isHovered.toggle()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isHovered = false
                }
            }
        }
    }
}
