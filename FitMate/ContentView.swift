//
//  ContentView.swift
//  FitMate
//
//  Created by Kazuki Omori on 2025/06/22.
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
