import Foundation

struct MenuRecognitionResponse: Codable {
    let menu_name: String
    let confidence: Double
}

struct VisionMenuAPI {

    static func recognizeMenu(imageData: Data) async throws -> MenuRecognitionResponse {
        guard let base = URL(string: AppConfig.visionURL) else {
            throw URLError(.badURL)
        }
        let url = base.appendingPathComponent("vision-menu")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.clientToken, forHTTPHeaderField: "x-client-token")

        let base64Image = imageData.base64EncodedString()
        let body: [String: Any] = [
            "image": base64Image
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        print("request:\(request)")
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        return try decoder.decode(MenuRecognitionResponse.self, from: data)
    }
}
