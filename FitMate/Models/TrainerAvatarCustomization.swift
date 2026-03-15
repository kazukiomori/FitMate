import Foundation

/// 画像生成・会話人格に反映するためのトレーナー詳細設定（文字列ベースで保持）
struct TrainerAvatarCustomization: Codable, Equatable {
    var appearanceAge: String
    var vibe: String
    var bodyType: String
    var faceType: String
    var hairStyle: String
    var hairColor: String
    var outfit: String
    var speakingStyle: String
}
