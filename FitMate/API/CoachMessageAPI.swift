//
//  CoachMessageAPI.swift
//  FitMate
//

import Foundation

struct CoachMessageAPI {
    static func send(
        message: String,
        trainerGender: TrainerGender,
        trainerPersonality: TrainerPersonality,
        intimacyLevel: Int
    ) async throws -> CoachMessageResponse {
        let url = URL(string: AppConfig.baseURL + "/coach-message")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.clientToken, forHTTPHeaderField: "x-client-token")

        let body = CoachMessageRequest(
            message: message,
            trainerGender: trainerGender,
            trainerPersonality: trainerPersonality,
            intimacyLevel: intimacyLevel
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse {
            print("Status:", http.statusCode)
            print("Body:", String(data: data, encoding: .utf8) ?? "nil")
        }

        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(CoachMessageResponse.self, from: data)
    }

    static func fetchNutrition(
        query: String,
        trainerGender: TrainerGender = .female,
        trainerPersonality: TrainerPersonality = .supportive,
        intimacyLevel: Int = 0
    ) async throws -> NutritionData {
        let response = try await send(
            message: query,
            trainerGender: trainerGender,
            trainerPersonality: trainerPersonality,
            intimacyLevel: intimacyLevel
        )

        guard let nutrition = response.nutrition else {
            throw NSError(
                domain: "CoachMessageAPI",
                code: 0,
                userInfo: [
                    NSLocalizedDescriptionKey: response.comment.isEmpty
                        ? "栄養情報を取得できませんでした"
                        : response.comment
                ]
            )
        }

        return nutrition
    }
}

struct CoachMessageRequest: Encodable {
    let message: String
    let trainerGender: TrainerGender
    let trainerPersonality: TrainerPersonality
    let intimacyLevel: Int

    enum CodingKeys: String, CodingKey {
        case message
        case trainerGender
        case trainerPersonality
        case intimacyLevel
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(message, forKey: .message)
        try container.encode(serializedGender, forKey: .trainerGender)
        try container.encode(serializedPersonality, forKey: .trainerPersonality)
        try container.encode(intimacyLevel, forKey: .intimacyLevel)
    }

    private var serializedGender: String {
        switch trainerGender {
        case .female:
            return "female"
        case .male:
            return "male"
        case .nonBinary:
            return "female"
        }
    }

    private var serializedPersonality: String {
        switch trainerPersonality {
        case .supportive:
            return "gentle"
        case .encouraging:
            return "cheerful"
        case .motivational:
            return "energetic"
        case .logical:
            return "cool"
        case .strict:
            return "strict"
        }
    }
}

struct CoachMessageResponse: Codable {
    let type: CoachResponseType
    let comment: String
    let nutrition: NutritionData?
}

enum CoachResponseType: String, Codable {
    case nutrition
    case chat
}

struct NutritionData: Codable {
    let name: String
    let calories_kcal: Double
    let protein_g: Double
    let fat_g: Double
    let carbs_g: Double
}

typealias NutritionResponse = NutritionData

@available(*, deprecated, renamed: "CoachMessageAPI")
enum NutritionAPI {
    static func fetchNutrition(query: String) async throws -> NutritionResponse {
        try await CoachMessageAPI.fetchNutrition(query: query)
    }
}