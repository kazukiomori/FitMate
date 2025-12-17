//
//  NutritionAPI.swift
//  FitMate
//
import SwiftUI

struct NutritionAPI {
    
    static func fetchNutrition(query: String) async throws -> NutritionResponse {
        var components = URLComponents(string: AppConfig.baseURL + "/nutrition")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query)
        ]
        let url = components.url!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        request.setValue(AppConfig.clientToken, forHTTPHeaderField: "x-client-token")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let http = response as? HTTPURLResponse {
            print("Status:", http.statusCode)
            print("Body:", String(data: data, encoding: .utf8) ?? "nil")
            print("TOKEN:", AppConfig.clientToken)
            print("Request:", request)
        }
        
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(NutritionResponse.self, from: data)
    }
}

struct NutritionResponse: Codable {
    let name: String
    let calories_kcal: Double
    let protein_g: Double
    let fat_g: Double
    let carbs_g: Double
}

