//
//  FeatureCard.swift
//  FitMate
//

import SwiftUI

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(height: 120)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}
