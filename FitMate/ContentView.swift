//
//  ContentView.swift
//  FitMate
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false
    @StateObject private var user = User()
    
    var body: some View {
        if isOnboardingComplete {
            MainTabView()
                .environmentObject(user)
        } else {
            OnboardingView()
                .environmentObject(user)
        }
    }
}

#Preview {
    ContentView()
}
