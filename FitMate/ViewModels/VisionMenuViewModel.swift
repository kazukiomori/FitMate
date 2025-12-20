import Foundation
import UIKit

@MainActor
class VisionMenuViewModel: ObservableObject {
    @Published var isRecognizing = false
    @Published var recognitionResults: [FoodRecognitionService.FoodRecognitionResult] = []
    @Published var recognizedMenuName: String?
    @Published var fetchedNutrition: NutritionResponse?
    @Published var errorMessage: String?

    private let foodRecognitionService = FoodRecognitionService()

    func recognizeFood(from image: UIImage) async {
        isRecognizing = true
        recognitionResults = []
        errorMessage = nil
        recognizedMenuName = nil
        fetchedNutrition = nil

        let resized = image.resized(maxLength: 512)
        guard let data = resized.jpegData(compressionQuality: 0.8) else {
            isRecognizing = false
            errorMessage = "画像のエンコードに失敗しました"
            return
        }

        do {
            let response = try await VisionMenuAPI.recognizeMenu(imageData: data)
            recognizedMenuName = response.menu_name
            let nutrition = try await NutritionAPI.fetchNutrition(query: response.menu_name)
            fetchedNutrition = nutrition
            isRecognizing = false
        } catch {
            isRecognizing = false
            errorMessage = error.localizedDescription
        }
    }

    func estimateCalories(for label: String) -> Int {
        return foodRecognitionService.estimateCalories(for: label)
    }
}
