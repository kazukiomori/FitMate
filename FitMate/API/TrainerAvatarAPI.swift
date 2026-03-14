import Foundation

struct TrainerAvatarAPI {
    struct CandidatesRequest: Codable {
        let count: Int
        let spec: TrainerAvatarSpec
    }

    struct Candidate: Codable, Hashable {
        let id: String
        let image_base64: String?
        let image_url: String?
    }

    struct CandidatesResponse: Codable {
        let generation_id: String
        let candidates: [Candidate]
    }

    struct FinalizeRequest: Codable {
        let generation_id: String
        let selected_candidate_id: String
        let spec: TrainerAvatarSpec
    }

    struct FinalizeResponse: Codable {
        let image_base64: String?
        let image_url: String?
    }

    static func fetchCandidates(spec: TrainerAvatarSpec, count: Int) async throws -> CandidatesResponse {
        guard let base = URL(string: AppConfig.baseURL) else {
            throw URLError(.badURL)
        }
        let url = base.appendingPathComponent("trainer/avatar/candidates")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.clientToken, forHTTPHeaderField: "x-client-token")

        let body = CandidatesRequest(count: count, spec: spec)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(CandidatesResponse.self, from: data)
    }

    static func finalize(generationId: String, selectedCandidateId: String, spec: TrainerAvatarSpec) async throws -> FinalizeResponse {
        guard let base = URL(string: AppConfig.baseURL) else {
            throw URLError(.badURL)
        }
        let url = base.appendingPathComponent("trainer/avatar/finalize")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.clientToken, forHTTPHeaderField: "x-client-token")

        let body = FinalizeRequest(
            generation_id: generationId,
            selected_candidate_id: selectedCandidateId,
            spec: spec
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(FinalizeResponse.self, from: data)
    }
}
