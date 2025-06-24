//
//  WelcomeStepView.swift
//  FitMate
//

import SwiftUI

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "heart.fill")
                .font(.system(size: 80))
                .foregroundColor(.pink)
            
            Text("HealthyLife")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("健康的なダイエットを\nサポートします")
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding()
    }
}
