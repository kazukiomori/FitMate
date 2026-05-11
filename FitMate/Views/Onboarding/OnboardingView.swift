//
//  OnboardingView.swift
//  FitMate
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var user: User
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false
    @State private var currentStep = 0
    @State private var offset: CGFloat = 0
    @State private var pendingTrainer: PersonalTrainer? = nil
    private let totalSteps = 5

    private var remainingSteps: Int {
        max(totalSteps - (currentStep + 1), 0)
    }

    private let stepTitles = [
        "MBTI",
        "あなたのこと",
        "目標（ゆるめでOK）",
        "トレーナー",
        "できること"
    ]
    
    var body: some View {
        ZStack {
            AoiOnboardingTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // プログレスバー
                VStack(spacing: 15) {
                    HStack {
                        ForEach(0..<totalSteps, id: \.self) { index in
                            Capsule()
                                .fill(index <= currentStep ? AoiOnboardingTheme.accent : AoiOnboardingTheme.border)
                                .frame(height: 7)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
                        }
                    }
                    .padding(.horizontal, 40)

                    VStack(spacing: 4) {
                        Text(stepTitles[currentStep])
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(AoiOnboardingTheme.textPrimary)

                        Text(remainingSteps == 0 ? "これで最後" : "あと\(remainingSteps)つ")
                            .font(.caption)
                            .foregroundColor(AoiOnboardingTheme.textSecondary)
                    }
                }
                .padding(.top, 20)
                
                // コンテンツ
                TabView(selection: $currentStep) {
                    MBTISelectionStepView(
                        onContinue: {
                            advanceToNextStep()
                        }
                    )
                        .tag(0)
                    ProfileSetupView()
                        .tag(1)
                    GoalSettingView(showsBackground: false)
                        .tag(2)
                    TrainerSetupView(pendingTrainer: $pendingTrainer)
                        .tag(3)
                    FeatureIntroView()
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: currentStep)
                .onChange(of: currentStep) { newStep in
                    if newStep != 3 {
                        pendingTrainer = nil
                    }
                }
                
                // ナビゲーションボタン
                if currentStep != 0 {
                    HStack(spacing: 20) {
                        if currentStep > 0 {
                            Button(backButtonTitle) {
                                handleBack()
                            }
                            .buttonStyle(AoiSecondaryButtonStyle())
                            .frame(maxWidth: .infinity)
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        }

                        Button(nextButtonTitle) {
                            handleNext()
                        }
                        .buttonStyle(AoiPrimaryButtonStyle())
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 56)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func advanceToNextStep() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentStep += 1
        }
    }

    private var isTrainerPendingConfirmation: Bool {
        currentStep == 3 && pendingTrainer != nil
    }

    private var backButtonTitle: String {
        isTrainerPendingConfirmation ? "別の候補へ" : "戻る"
    }

    private var nextButtonTitle: String {
        if isTrainerPendingConfirmation {
            return "決定"
        }
        return currentStep == totalSteps - 1 ? "始める" : "次へ"
    }

    private func handleBack() {
        if isTrainerPendingConfirmation {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                pendingTrainer = nil
            }
            return
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentStep -= 1
        }
    }

    private func handleNext() {
        if isTrainerPendingConfirmation {
            guard let trainer = pendingTrainer else { return }
            user.setPersonalTrainer(trainer)
            pendingTrainer = nil
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentStep += 1
            }
            return
        }

        if currentStep == totalSteps - 1 {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                isOnboardingComplete = true
            }
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentStep += 1
            }
        }
    }
}

// MARK: - アニメーション背景
struct AnimatedGradientBackground: View {
    let currentStep: Int
    @State private var animateGradient = false
    
    private var gradientColors: [Color] {
        switch currentStep {
        case 0: return [Color.purple, Color.pink, Color.orange]
        case 1: return [Color.blue, Color.cyan, Color.mint]
        case 2: return [Color.green, Color.teal, Color.blue]
        case 3: return [Color.orange, Color.red, Color.pink]
        default: return [Color.purple, Color.blue, Color.cyan]
        }
    }
    
    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)
        .onAppear {
            animateGradient = true
        }
        .onChange(of: currentStep) {
            withAnimation(.easeInOut(duration: 1)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - ガラスモーフィズム ボタンスタイル
struct PrimaryGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

