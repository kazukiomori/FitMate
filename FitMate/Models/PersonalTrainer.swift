//
//  PersonalTrainer.swift
//  FitMate
//


import UIKit

enum TrainerAvatarExpression: String, Codable, CaseIterable {
    case smile
    case sad
    case angry
}

struct PersonalTrainer {
    let id = UUID()
    var name: String
    var preferences: TrainerPreferences
    let images: [UIImage]
    let assetNamespace: String?
    var image: UIImage? { images.first }
    let createdAt: Date
    
    init(name: String, preferences: TrainerPreferences, images: [UIImage] = [], assetNamespace: String? = nil) {
        self.init(name: name, preferences: preferences, images: images, assetNamespace: assetNamespace, createdAt: Date())
    }

    init(name: String, preferences: TrainerPreferences, images: [UIImage] = [], assetNamespace: String? = nil, createdAt: Date) {
        self.name = name
        self.preferences = preferences
        self.images = images
        self.assetNamespace = assetNamespace
        self.createdAt = createdAt
    }

    init(name: String, preferences: TrainerPreferences, image: UIImage? = nil, assetNamespace: String? = nil) {
        self.init(name: name, preferences: preferences, images: image.map { [$0] } ?? [], assetNamespace: assetNamespace)
    }

    func avatarImage(for expression: TrainerAvatarExpression = .smile) -> UIImage? {
        guard let assetNamespace else { return image }

        return UIImage(named: "\(assetNamespace)/\(expression.rawValue)")
            ?? UIImage(named: "\(assetNamespace)_\(expression.rawValue)")
            ?? image
    }

    func profileImage(named imageName: String) -> UIImage? {
        let fallbackImage: UIImage? = switch imageName {
        case "first":
            images.first
        case "second":
            images.count > 1 ? images[1] : images.first
        case "smile":
            avatarImage(for: .smile)
        case "angry":
            avatarImage(for: .angry)
        case "sad":
            avatarImage(for: .sad)
        default:
            nil
        }

        guard let assetNamespace else { return fallbackImage }

        return UIImage(named: "\(assetNamespace)/\(imageName)")
            ?? UIImage(named: "\(assetNamespace)_\(imageName)")
            ?? fallbackImage
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

    func getHomeMessage(isFirstOpenToday: Bool) -> String {
        guard isFirstOpenToday else {
            return getTodaysMessage()
        }

        switch preferences.personality {
        case .encouraging, .supportive:
            return "今日もアプリを開いてくれてありがとう。昨日のあなたより、ちゃんと前に進めていますよ"
        case .strict:
            return "今日も開いてくれてありがとうございます。まずは記録から始めましょう。継続が結果を作ります"
        case .logical:
            return "今日もアプリを開いてくれてありがとうございます。まずは今日の状態を確認して、やることを整理していきましょう"
        case .motivational:
            return "今日もアプリを開いてくれてありがとう。この一回が理想の自分に近づく一歩です"
        }
    }
}

extension PersonalTrainer {
    var resolvedDisplayName: String {
        if !name.isEmpty {
            return name
        }

        if let fullName = profile?.name.full, !fullName.isEmpty {
            return fullName
        }

        return defaultDisplayName
    }

    var resolvedAgeText: String {
        if let age = profile?.age {
            return "\(age)歳"
        }

        return preferences.age.rawValue
    }

    var resolvedGenderText: String {
        preferences.gender.rawValue
    }

    private var defaultDisplayName: String {
        guard let assetNamespace, assetNamespace.hasPrefix("trainer") else {
            return "トレーナー"
        }

        let suffix = assetNamespace.replacingOccurrences(of: "trainer", with: "")
        return suffix.isEmpty ? "トレーナー" : "トレーナー\(suffix)"
    }
}
