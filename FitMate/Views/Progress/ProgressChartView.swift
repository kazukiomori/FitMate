//
//  ProgressChartView.swift
//  FitMate
//

import SwiftUI

struct ProgressChartView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("進捗画面")
                    .font(.title)
                Text("実装予定")
                    .foregroundColor(.gray)
            }
            .navigationTitle("進捗")
        }
    }
}

