//
//  WelcomeStepView.swift
//  FitMate
//

import SwiftUI

struct WelcomeStepView: View {
    @State private var animateIcon = false
    @State private var animateText = false
    
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            
            // アニメーションアイコン
            ZStack {
                Circle()
                    .fill(AoiOnboardingTheme.accentSoft)
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle()
                            .stroke(AoiOnboardingTheme.border, lineWidth: 2)
                    )
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(AoiOnboardingTheme.accent)
            }
            
            VStack(spacing: 20) {
                Text("FitMate")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(AoiOnboardingTheme.textPrimary)
                    .opacity(animateText ? 1 : 0)
                    .offset(y: animateText ? 0 : 20)

                OnboardingHeader(
                    title: "続けることを、いちばん大事に。",
                    subtitle: "毎日じゃなくてOK。\nできた日だけ記録して、\n“続いた”を増やしていこう。",
                    footnote: "あとでいつでも変えられます"
                )
                .opacity(animateText ? 1 : 0)
                .offset(y: animateText ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.25), value: animateText)

                OnboardingHintPill(text: "まずは3日続いたら、もう勝ち")
                    .opacity(animateText ? 1 : 0)
                    .offset(y: animateText ? 0 : 18)
                    .animation(.easeOut(duration: 0.8).delay(0.45), value: animateText)
            }
            
            Spacer()
        }
        .onboardingPagePadding()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateText = true
            }
            animateIcon = true
        }
    }
}
