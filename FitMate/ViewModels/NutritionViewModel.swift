//
//  NutritionViewModel.swift
//  FitMate
//

import SwiftUI

final class NutritionViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var result: NutritionResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func search(query: String? = nil) async {
        let q = (query ?? self.query).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let res = try await NutritionAPI.fetchNutrition(query: q)
            result = res
        } catch {
            print("API error:", error)
            errorMessage = "取得に失敗しました"
        }
    }
}


