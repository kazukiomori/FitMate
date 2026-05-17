//
//  FitMateApp.swift
//  FitMate
//

import SwiftUI
import TipKit

@main
struct FitMateApp: App {
    init() {
        try? Tips.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
