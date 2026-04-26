//
//  CoachMessageViewModel.swift
//  FitMate
//

import SwiftUI

@MainActor
final class CoachMessageViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var response: CoachMessageResponse?
    @Published var nutritionResult: NutritionData?
    @Published var chatComment: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func send(
        inputText: String? = nil,
        trainerGender: TrainerGender,
        trainerPersonality: TrainerPersonality,
        intimacyLevel: Int
    ) async {
        let text = (inputText ?? self.inputText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await CoachMessageAPI.send(
                message: text,
                trainerGender: trainerGender,
                trainerPersonality: trainerPersonality,
                intimacyLevel: intimacyLevel
            )

            self.response = response

            switch response.type {
            case .nutrition:
                nutritionResult = response.nutrition
                chatComment = nil

            case .chat:
                nutritionResult = nil
                chatComment = response.comment
            }
        } catch {
            print("API error:", error)
            errorMessage = "取得に失敗しました"
            response = nil
            nutritionResult = nil
            chatComment = nil
        }
    }
}