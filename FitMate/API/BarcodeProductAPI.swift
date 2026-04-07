import Foundation

struct BarcodeProductLookupResult {
    let barcode: String
    let name: String?
    let caloriesKcal: Double?
    let proteinG: Double?
    let fatG: Double?
    let carbsG: Double?

    var asNutritionResponse: NutritionResponse? {
        guard let name, !name.isEmpty, let caloriesKcal else { return nil }
        return NutritionResponse(
            name: name,
            calories_kcal: caloriesKcal,
            protein_g: proteinG ?? 0,
            fat_g: fatG ?? 0,
            carbs_g: carbsG ?? 0
        )
    }
}

enum BarcodeProductAPI {
    static func fetchProduct(barcode: String) async throws -> BarcodeProductLookupResult {
        let normalizedBarcode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedBarcode.isEmpty,
              let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(normalizedBarcode).json") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        let status = json["status"] as? Int ?? 0
        guard status == 1, let product = json["product"] as? [String: Any] else {
            throw NSError(domain: "BarcodeProductAPI", code: 404, userInfo: [NSLocalizedDescriptionKey: "商品が見つかりませんでした"])
        }

        let nutriments = product["nutriments"] as? [String: Any]
        let productName = firstNonEmptyString(
            product["product_name_ja"],
            product["product_name"],
            product["generic_name_ja"],
            product["generic_name"]
        )

        return BarcodeProductLookupResult(
            barcode: normalizedBarcode,
            name: productName,
            caloriesKcal: firstDouble(
                nutriments?["energy-kcal_serving"],
                nutriments?["energy-kcal_100g"],
                nutriments?["energy-kcal_value"],
                nutriments?["energy-kcal"]
            ),
            proteinG: firstDouble(
                nutriments?["proteins_serving"],
                nutriments?["proteins_100g"],
                nutriments?["proteins"]
            ),
            fatG: firstDouble(
                nutriments?["fat_serving"],
                nutriments?["fat_100g"],
                nutriments?["fat"]
            ),
            carbsG: firstDouble(
                nutriments?["carbohydrates_serving"],
                nutriments?["carbohydrates_100g"],
                nutriments?["carbohydrates"]
            )
        )
    }

    private static func firstNonEmptyString(_ values: Any?...) -> String? {
        for value in values {
            if let string = value as? String {
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }
        return nil
    }

    private static func firstDouble(_ values: Any?...) -> Double? {
        for value in values {
            if let number = doubleValue(from: value) {
                return number
            }
        }
        return nil
    }

    private static func doubleValue(from value: Any?) -> Double? {
        switch value {
        case let number as NSNumber:
            return number.doubleValue
        case let string as String:
            return Double(string.trimmingCharacters(in: .whitespacesAndNewlines))
        default:
            return nil
        }
    }
}
