//
//  ExerciseView.swift
//  FitMate
//

import SwiftUI

struct ExerciseView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("運動記録画面")
                    .font(.title)
                Text("実装予定")
                    .foregroundColor(.gray)
            }
            .navigationTitle("運動")
        }
    }
}

