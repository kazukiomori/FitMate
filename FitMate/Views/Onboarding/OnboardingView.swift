//
//  OnboardingView.swift
//  FitMate
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var user: User
    @State private var currentStep = 0
    private let totalSteps = 5 // トレーナー設定を追加
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Bar
                ProgressView(value: Double(currentStep) / Double(totalSteps))
                    .accentColor(.blue)
                    .padding()
                
                // Content
                TabView(selection: $currentStep) {
                    WelcomeStepView()
                        .tag(0)
                    ProfileSetupView()
                        .tag(1)
                    GoalSettingView()
                        .tag(2)
                    TrainerSetupView()
                        .tag(3)
                    FeatureIntroView()
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Navigation Buttons
                HStack {
                    if currentStep > 0 {
                        Button("戻る") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(currentStep == totalSteps - 1 ? "開始する" : "次へ") {
                        if currentStep == totalSteps - 1 {
                            user.isOnboardingComplete = true
                        } else {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
                }
                .padding()
            }
        }
    }
}
