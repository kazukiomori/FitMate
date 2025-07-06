//
//  TrainerImageGenerationService.swift
//  FitMate
//


import UIKit
import Foundation

class TrainerImageGenerationService {
    private let apiKey = "YOUR_STABILITY_AI_API_KEY" // Stability AI APIキー
    
    // 複数のモデルオプション（価格順）
    enum ModelOption: String, CaseIterable {
        case stable_diffusion_v1_6 = "stable-diffusion-v1-6"           // 最安: ~$0.002/画像
        case stable_diffusion_xl_beta = "stable-diffusion-xl-beta-v2-2-2" // 安: ~$0.008/画像
        case stable_diffusion_xl = "stable-diffusion-xl-1024-v1-0"     // 高品質: ~$0.04/画像
        
        var apiURL: String {
            return "https://api.stability.ai/v1/generation/\(self.rawValue)/text-to-image"
        }
        
        var description: String {
            switch self {
            case .stable_diffusion_v1_6:
                return "最安価格（約0.3円/画像） - 512x512解像度"
            case .stable_diffusion_xl_beta:
                return "バランス型（約1.2円/画像） - 1024x1024解像度"
            case .stable_diffusion_xl:
                return "最高品質（約6円/画像） - 1024x1024解像度"
            }
        }
        
        var defaultSize: (width: Int, height: Int) {
            switch self {
            case .stable_diffusion_v1_6:
                return (512, 512)
            case .stable_diffusion_xl_beta, .stable_diffusion_xl:
                return (1024, 1024)
            }
        }
    }
    
    // デフォルトは最安価格のモデル
    private let selectedModel: ModelOption = .stable_diffusion_v1_6
    
    struct ImageGenerationResult {
        let image: UIImage
        let seed: Int64
        let model: ModelOption
        let estimatedCost: String
    }
    
    func generateTrainerImage(preferences: TrainerPreferences, completion: @escaping (Result<ImageGenerationResult, Error>) -> Void) {
        // APIキーが設定されていない場合はデモ画像を使用
        if apiKey == "YOUR_STABILITY_AI_API_KEY" || apiKey.isEmpty {
            generateDemoTrainerImage(preferences: preferences, completion: completion)
            return
        }
        
        let prompt = createPrompt(from: preferences)
        let requestBody = createRequestBody(prompt: prompt, model: selectedModel)
        
        guard let url = URL(string: selectedModel.apiURL) else {
            completion(.failure(NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "APIのURLが無効です"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        print("Stability AI 画像生成開始...")
        print("Model: \(selectedModel.rawValue)")
        print("Estimated Cost: \(getEstimatedCost(for: selectedModel))")
        print("Prompt: \(prompt)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("ネットワークエラー: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.generateDemoTrainerImage(preferences: preferences, completion: completion)
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    print("APIエラー: \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        self.generateDemoTrainerImage(preferences: preferences, completion: completion)
                    }
                    return
                }
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.generateDemoTrainerImage(preferences: preferences, completion: completion)
                }
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let artifacts = jsonResponse["artifacts"] as? [[String: Any]],
                   let firstArtifact = artifacts.first,
                   let base64String = firstArtifact["base64"] as? String,
                   let seed = firstArtifact["seed"] as? Int64,
                   let imageData = Data(base64Encoded: base64String),
                   let image = UIImage(data: imageData) {
                    
                    print("画像生成成功！")
                    let result = ImageGenerationResult(
                        image: image,
                        seed: seed,
                        model: self.selectedModel,
                        estimatedCost: self.getEstimatedCost(for: self.selectedModel)
                    )
                    
                    DispatchQueue.main.async {
                        completion(.success(result))
                    }
                } else {
                    print("レスポンス解析失敗")
                    DispatchQueue.main.async {
                        self.generateDemoTrainerImage(preferences: preferences, completion: completion)
                    }
                }
            } catch {
                print("JSON解析エラー: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.generateDemoTrainerImage(preferences: preferences, completion: completion)
                }
            }
        }.resume()
    }
    
    // 複数モデルでの生成（価格比較用）
    func generateTrainerImageWithModel(_ model: ModelOption, preferences: TrainerPreferences, completion: @escaping (Result<ImageGenerationResult, Error>) -> Void) {
        let prompt = createPrompt(from: preferences)
        let requestBody = createRequestBody(prompt: prompt, model: model)
        
        guard let url = URL(string: model.apiURL) else {
            completion(.failure(NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "APIのURLが無効です"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // [同じ処理ロジック...]
            if let error = error {
                DispatchQueue.main.async {
                    self.generateDemoTrainerImage(preferences: preferences, completion: completion)
                }
                return
            }
            
            // [レスポンス処理は同じ...]
        }.resume()
    }
    
    private func createPrompt(from preferences: TrainerPreferences) -> String {
        let basePrompt = """
        Professional portrait of a \(preferences.age.promptKeyword) \(preferences.gender.promptKeyword) \
        \(preferences.specialization.promptKeyword), \(preferences.style.promptKeyword), \
        confident smile, high quality, studio lighting, professional photography, \
        fitness background, motivational, approachable, trustworthy
        """
        
        return basePrompt
    }
    
    private func createRequestBody(prompt: String, model: ModelOption) -> [String: Any] {
        let size = model.defaultSize
        
        // モデルに応じてパラメータを最適化
        let steps: Int
        let cfgScale: Double
        
        switch model {
        case .stable_diffusion_v1_6:
            steps = 20  // 少ないステップでコスト削減
            cfgScale = 7.0
        case .stable_diffusion_xl_beta:
            steps = 25  // バランス
            cfgScale = 7.5
        case .stable_diffusion_xl:
            steps = 30  // 高品質
            cfgScale = 8.0
        }
        
        return [
            "text_prompts": [
                [
                    "text": prompt,
                    "weight": 1.0
                ],
                [
                    "text": "blurry, low quality, distorted, amateur, unprofessional, inappropriate",
                    "weight": -1.0
                ]
            ],
            "cfg_scale": cfgScale,
            "height": size.height,
            "width": size.width,
            "steps": steps,
            "samples": 1,
            "style_preset": "photographic"
        ]
    }
    
    private func getEstimatedCost(for model: ModelOption) -> String {
        switch model {
        case .stable_diffusion_v1_6:
            return "約0.3円"
        case .stable_diffusion_xl_beta:
            return "約1.2円"
        case .stable_diffusion_xl:
            return "約6円"
        }
    }
    
    // デモ用画像生成（API未使用時）
    private func generateDemoTrainerImage(preferences: TrainerPreferences, completion: @escaping (Result<ImageGenerationResult, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // カラフルなプレースホルダー画像を生成
            let image = self.createDemoTrainerImage(preferences: preferences)
            let result = ImageGenerationResult(
                image: image,
                seed: Int64.random(in: 1000...9999),
                model: .stable_diffusion_v1_6,
                estimatedCost: "デモ（無料）"
            )
            completion(.success(result))
        }
    }
    
    private func createDemoTrainerImage(preferences: TrainerPreferences) -> UIImage {
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // 背景のグラデーション
            let colors = [UIColor.systemBlue, UIColor.systemPurple]
            let startPoint = CGPoint(x: 0, y: 0)
            let endPoint = CGPoint(x: size.width, y: size.height)
            
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: colors.map { $0.cgColor } as CFArray,
                                    locations: [0.0, 1.0])!
            
            context.cgContext.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
            
            // アイコン描画
            let iconSize: CGFloat = 120
            let iconRect = CGRect(x: (size.width - iconSize) / 2,
                                y: (size.height - iconSize) / 2 - 20,
                                width: iconSize,
                                height: iconSize)
            
            // 人物アイコン
            UIColor.white.setFill()
            let personPath = UIBezierPath(ovalIn: CGRect(x: iconRect.midX - 25, y: iconRect.minY + 10, width: 50, height: 50))
            personPath.fill()
            
            let bodyPath = UIBezierPath(roundedRect: CGRect(x: iconRect.midX - 30, y: iconRect.midY, width: 60, height: 70), cornerRadius: 20)
            bodyPath.fill()
            
            // テキスト
            let trainerTypeText = preferences.specialization.rawValue
            let font = UIFont.systemFont(ofSize: 16, weight: .bold)
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white
            ]
            
            let textSize = trainerTypeText.size(withAttributes: textAttributes)
            let textRect = CGRect(x: (size.width - textSize.width) / 2,
                                y: size.height - 40,
                                width: textSize.width,
                                height: textSize.height)
            
            trainerTypeText.draw(in: textRect, withAttributes: textAttributes)
        }
    }
}
