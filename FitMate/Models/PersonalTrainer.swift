//
//  PersonalTrainer.swift
//  FitMate
//


import UIKit

struct PersonalTrainer {
    let id = UUID()
    let name: String
    let preferences: TrainerPreferences
    let image: UIImage?
    let motivationalMessages: [String]
    let createdAt: Date
    
    init(name: String, preferences: TrainerPreferences, image: UIImage? = nil) {
        self.name = name
        self.preferences = preferences
        self.image = image
        self.createdAt = Date()
        self.motivationalMessages = PersonalTrainer.generateMessages(for: preferences)
    }
    
    static func generateMessages(for preferences: TrainerPreferences) -> [String] {
        switch preferences.personality {
        case .motivational:
            return [
                "今日も頑張りましょう！あなたならできます！",
                "目標まであと少しです。諦めずに続けましょう！",
                "毎日の積み重ねが大きな成果につながります！",
                "今日の努力が明日の自分を作ります！"
            ]
        case .supportive:
            return [
                "無理をせず、自分のペースで進めましょう",
                "小さな変化も大切な一歩です",
                "体調に気をつけて、健康第一で行きましょう",
                "一緒に健康的な習慣を身につけていきましょう"
            ]
        case .strict:
            return [
                "目標達成のためには継続が必要です",
                "今日のノルマは達成しましたか？",
                "甘えは禁物。結果にコミットしましょう",
                "規則正しい生活が成功の鍵です"
            ]
        case .encouraging:
            return [
                "素晴らしい取り組みですね！",
                "毎日記録をつけて偉いです！",
                "着実に成果が出ていますよ",
                "あなたの努力を応援しています！"
            ]
        }
    }
    
    func getTodaysMessage() -> String {
        let index = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return motivationalMessages[index % motivationalMessages.count]
    }
}
