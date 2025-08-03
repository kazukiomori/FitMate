//
//  OnboardingView.swift
//  FitMate
//

// MARK: - Views/Onboarding/OnboardingView.swift (モダンUI版)
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var user: User
    @State private var currentStep = 0
    @State private var offset: CGFloat = 0
    private let totalSteps = 4
    
    var body: some View {
        ZStack {
            // 動的グラデーション背景
            AnimatedGradientBackground(currentStep: currentStep)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // プログレスバー
                VStack(spacing: 15) {
                    HStack {
                        ForEach(0..<totalSteps, id: \.self) { index in
                            Capsule()
                                .fill(index <= currentStep ? Color.white : Color.white.opacity(0.3))
                                .frame(height: 6)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Text("\(currentStep + 1) / \(totalSteps)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 20)
                
                // コンテンツ
                TabView(selection: $currentStep) {
                    WelcomeStepView()
                        .tag(0)
                    ProfileSetupView()
                        .tag(1)
                    GoalSettingView()
                        .tag(2)
                    FeatureIntroView()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: currentStep)
                
                // ナビゲーションボタン
                HStack(spacing: 20) {
                    if currentStep > 0 {
                        Button("戻る") {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(SecondaryGlassButtonStyle())
                    } else {
                        Spacer()
                    }
                    
                    Button(currentStep == totalSteps - 1 ? "始める" : "次へ") {
                        if currentStep == totalSteps - 1 {
                            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                                user.isOnboardingComplete = true
                            }
                        } else {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                currentStep += 1
                            }
                        }
                    }
                    .buttonStyle(PrimaryGlassButtonStyle())
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
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
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
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
