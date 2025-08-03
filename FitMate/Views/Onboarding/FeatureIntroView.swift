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
        VStack(spacing: 40) {
            // タイトル
            VStack(spacing: 12) {
                Text("FitMateの機能")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("最新のAI技術であなたの健康をサポート")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            
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
            .padding(.horizontal, 20)
            
            Spacer()
            
            // 開始準備完了メッセージ
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text("準備完了！")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Text("あなたの健康的なダイエットを始めましょう")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .opacity(animateFeatures ? 1 : 0)
            .animation(.easeOut(duration: 0.8).delay(0.6), value: animateFeatures)
            
            Spacer()
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
                    .fill(
                        LinearGradient(
                            colors: [
                                feature.color.opacity(0.3),
                                feature.color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(feature.color.opacity(0.4), lineWidth: 2)
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
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .frame(height: 160)
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
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
