//
//  ContentView.swift
//  FitMate
//

import SwiftUI

struct ContentView: View {
    @StateObject private var user = User()
    
    var body: some View {
        if user.isOnboardingComplete {
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
