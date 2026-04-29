//
//  ContentView.swift
//  FitMate
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false
    @StateObject private var user = User()
    
    var body: some View {
        Group {
            if isOnboardingComplete {
                MainTabView()
                    .environmentObject(user)
            } else {
                OnboardingView()
                    .environmentObject(user)
            }
        }
        .onAppear {
            user.markAppLaunch()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                user.markAppLaunch()
            }
        }
    }
}

#Preview {
    ContentView()
}
