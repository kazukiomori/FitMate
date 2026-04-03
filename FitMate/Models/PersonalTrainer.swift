//
//  PersonalTrainer.swift
//  FitMate
//


import UIKit

struct PersonalTrainer {
    let id = UUID()
    var name: String
    var preferences: TrainerPreferences
    let images: [UIImage]
    var image: UIImage? { images.first }
    let createdAt: Date
    
    init(name: String, preferences: TrainerPreferences, images: [UIImage] = []) {
        self.name = name
        self.preferences = preferences
        self.images = images
        self.createdAt = Date()
    }

    init(name: String, preferences: TrainerPreferences, image: UIImage? = nil) {
        self.init(name: name, preferences: preferences, images: image.map { [$0] } ?? [])
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
        case .logical:
            return [
                "まずは現状を整理しましょう。今日の記録から改善点を一緒に見つけます",
                "体重は短期で上下します。1週間平均で見ていきましょう",
                "目標に対して、摂取と消費のバランスを数値で確認してみましょう",
                "再現性のある習慣に落とし込むのが近道です。できることから順に行きましょう"
            ]
        }
    }
    
    func getTodaysMessage() -> String {
        let motivationalMessages = PersonalTrainer.generateMessages(for: preferences)
        let index = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return motivationalMessages[index % motivationalMessages.count]
    }
}
