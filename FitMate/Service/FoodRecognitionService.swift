//
//  FoodRecognitionService.swift
//  FitMate
//

import UIKit
import Foundation

class FoodRecognitionService {
    private let apiURL = "https://api-inference.huggingface.co/models/aspis/swin-finetuned-food101"
    private let apiKey = "" // 実際のAPIキーに置き換える
    
    // 食事認識結果の構造体
    struct FoodRecognitionResult {
        let label: String
        let confidence: Double
    }
    
    // 画像から食事を認識
    func recognizeFood(from image: UIImage, completion: @escaping (Result<[FoodRecognitionResult], Error>) -> Void) {
            // APIキーが設定されていない場合はデモ機能を使用
            if apiKey == "YOUR_HUGGING_FACE_API_KEY" || apiKey.isEmpty {
                print("APIキーが設定されていません。デモ機能を使用します。")
//                recognizeFoodDemo(from: image, completion: completion)
                return
            }
            
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                completion(.failure(NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "画像の処理に失敗しました"])))
                return
            }
            
            guard let url = URL(string: apiURL) else {
                completion(.failure(NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "APIのURLが無効です"])))
                return
            }
            
            // APIリクエストの作成 - バイナリデータとして送信
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = imageData
            request.timeoutInterval = 30.0 // タイムアウトを30秒に設定
            
            print("Hugging Face APIリクエスト開始...")
            print("URL: \(apiURL)")
            print("Content-Type: image/jpeg")
            print("画像サイズ: \(imageData.count) bytes")
            
            // APIリクエスト実行
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("ネットワークエラー: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        // ネットワークエラーの場合はデモ機能を使用
//                        self.recognizeFoodDemo(from: image, completion: completion)
                    }
                    return
                }
                
                // HTTPレスポンスの確認
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)")
                    print("Response Headers: \(httpResponse.allHeaderFields)")
                    
                    switch httpResponse.statusCode {
                    case 200:
                        // 成功
                        break
                    case 503:
                        print("モデルが読み込み中です。少し待ってから再試行してください。")
                        DispatchQueue.main.async {
//                            self.recognizeFoodDemo(from: image, completion: completion)
                        }
                        return
                    case 404:
                        print("モデルが見つかりません。デモ機能を使用します。")
                        DispatchQueue.main.async {
//                            self.recognizeFoodDemo(from: image, completion: completion)
                        }
                        return
                    case 401, 403:
                        print("認証エラー。APIキーを確認してください。")
                        DispatchQueue.main.async {
//                            self.recognizeFoodDemo(from: image, completion: completion)
                        }
                        return
                    default:
                        print("APIエラー: \(httpResponse.statusCode)")
                        DispatchQueue.main.async {
//                            self.recognizeFoodDemo(from: image, completion: completion)
                        }
                        return
                    }
                }
                
                guard let data = data else {
                    print("レスポンスデータがありません")
                    DispatchQueue.main.async {
//                        self.recognizeFoodDemo(from: image, completion: completion)
                    }
                    return
                }
                
                // レスポンスデータをデバッグ出力
                if let responseString = String(data: data, encoding: .utf8) {
                    print("API Response: \(responseString)")
                }
                
                do {
                    // JSON レスポンスの解析
                    if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        let results = jsonArray.compactMap { item -> FoodRecognitionResult? in
                            guard let label = item["label"] as? String,
                                  let confidence = item["score"] as? Double else {
                                return nil
                            }
                            return FoodRecognitionResult(label: label, confidence: confidence)
                        }
                        
                        print("認識結果: \(results.count)件")
                        DispatchQueue.main.async {
                            completion(.success(results))
                        }
                    } else if let jsonDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // エラーレスポンスまたは異なる形式の場合
                        print("JSON辞書形式のレスポンス: \(jsonDict)")
                        
                        if let error = jsonDict["error"] as? String {
                            print("APIエラーメッセージ: \(error)")
                        }
                        
                        DispatchQueue.main.async {
//                            self.recognizeFoodDemo(from: image, completion: completion)
                        }
                    } else {
                        print("予期しないレスポンス形式です")
                        DispatchQueue.main.async {
//                            self.recognizeFoodDemo(from: image, completion: completion)
                        }
                    }
                } catch {
                    print("JSON解析エラー: \(error.localizedDescription)")
                    DispatchQueue.main.async {
//                        self.recognizeFoodDemo(from: image, completion: completion)
                    }
                }
            }.resume()
        }
    
    // 食事名からカロリーを推定（簡易版）
    func estimateCalories(for foodName: String) -> Int {
        let calorieDatabase: [String: Int] = [
            "rice": 200,
            "bread": 250,
            "chicken": 165,
            "beef": 250,
            "fish": 150,
            "vegetables": 50,
            "fruit": 80,
            "pasta": 220,
            "pizza": 300,
            "salad": 100,
            "soup": 80,
            "sandwich": 300,
            "burger": 400,
            "noodles": 200,
            "cake": 350,
            "cookie": 200
        ]
        
        let lowercasedName = foodName.lowercased()
        
        // 部分一致でカロリーを推定
        for (key, calories) in calorieDatabase {
            if lowercasedName.contains(key) {
                return calories
            }
        }
        
        // デフォルト値
        return 200
    }
}


