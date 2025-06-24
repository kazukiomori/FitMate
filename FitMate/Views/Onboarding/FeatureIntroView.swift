//
//  FeatureIntroView.swift
//  FitMate
//

import SwiftUI

struct FeatureIntroView: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("主な機能")
                .font(.title)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                FeatureCard(
                    icon: "camera.fill",
                    title: "食事記録",
                    description: "写真でかんたん記録"
                )
                
                FeatureCard(
                    icon: "figure.walk",
                    title: "運動記録",
                    description: "歩数・運動を自動追跡"
                )
                
                FeatureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "進捗管理",
                    description: "グラフで変化を確認"
                )
                
                FeatureCard(
                    icon: "person.2.fill",
                    title: "コミュニティ",
                    description: "仲間と励まし合い"
                )
            }
            
            Spacer()
        }
        .padding()
    }
}

