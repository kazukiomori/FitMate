//
//  WelcomeStepView.swift
//  FitMate
//

import SwiftUI

struct WelcomeStepView: View {
    @State private var animateIcon = false
    @State private var animateText = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // アニメーションアイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: Color.white.opacity(0.3), radius: 10)
            }
            
            VStack(spacing: 20) {
                Text("FitMate")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 2)
                    .opacity(animateText ? 1 : 0)
                    .offset(y: animateText ? 0 : 20)
                
                VStack(spacing: 12) {
                    Text("あなた専用の")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("AIパーソナルトレーナー")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .opacity(animateText ? 1 : 0)
                .offset(y: animateText ? 0 : 30)
                .animation(.easeOut(duration: 0.8).delay(0.3), value: animateText)
                
                Text("健康的で持続可能なダイエットを\n楽しくサポートします")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(animateText ? 1 : 0)
                    .offset(y: animateText ? 0 : 40)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: animateText)
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateText = true
            }
            animateIcon = true
        }
    }
}
