//
//  TrainerPreferences.swift
//  FitMate
//

import Foundation

struct TrainerPreferences {
    let gender: TrainerGender
    let age: TrainerAge
    let style: TrainerStyle
    let personality: TrainerPersonality
    let specialization: TrainerSpecialization
}

enum TrainerGender: String, CaseIterable {
    case male = "男性"
    case female = "女性"
    case nonBinary = "その他"
    
    var promptKeyword: String {
        switch self {
        case .male: return "handsome man"
        case .female: return "beautiful woman"
        case .nonBinary: return "person"
        }
    }
}

enum TrainerAge: String, CaseIterable {
    case young = "20代"
    case middle = "30代"
    case mature = "40代以上"
    
    var promptKeyword: String {
        switch self {
        case .young: return "young"
        case .middle: return "middle-aged"
        case .mature: return "mature"
        }
    }
}

enum TrainerStyle: String, CaseIterable {
    case professional = "プロフェッショナル"
    case friendly = "フレンドリー"
    case energetic = "エネルギッシュ"
    case calm = "穏やか"
    
    var promptKeyword: String {
        switch self {
        case .professional: return "professional, business attire"
        case .friendly: return "friendly, casual sportwear"
        case .energetic: return "energetic, athletic wear"
        case .calm: return "calm, comfortable clothing"
        }
    }
}

enum TrainerPersonality: String, CaseIterable {
    case motivational = "やる気を引き出す"
    case supportive = "優しくサポート"
    case strict = "厳しく指導"
    case encouraging = "励ましてくれる"
    
    var description: String {
        switch self {
        case .motivational: return "目標達成に向けて強くモチベーションを高めてくれます"
        case .supportive: return "優しく寄り添いながらサポートしてくれます"
        case .strict: return "規律正しく、時には厳しく指導してくれます"
        case .encouraging: return "常に前向きな言葉で励ましてくれます"
        }
    }
}

enum TrainerSpecialization: String, CaseIterable {
    case weightLoss = "体重減少"
    case muscleBuilding = "筋力アップ"
    case healthyLifestyle = "健康的な生活"
    case nutritionFocus = "栄養指導重視"
    
    var promptKeyword: String {
        switch self {
        case .weightLoss: return "fitness trainer, weight loss specialist"
        case .muscleBuilding: return "strength trainer, muscle building coach"
        case .healthyLifestyle: return "wellness coach, lifestyle trainer"
        case .nutritionFocus: return "nutrition coach, dietary specialist"
        }
    }
}

