import Foundation

/// 2D/3D どちらにも引き継げる「トレーナー見た目仕様」。
/// - 画像生成ではこの Spec からプロンプト/パラメータを組み立てる
/// - 将来 Unity の 3D アバターでもこの Spec をマッピングして再現する
struct TrainerAvatarSpec: Codable, Equatable {
    enum RenderingStyle: String, Codable {
        case realisticPhotographic
    }

    enum Expression: String, Codable, CaseIterable {
        case neutral
        case smile
        case encouraging
        case strict
    }

    var version: Int = 1
    var renderingStyle: RenderingStyle = .realisticPhotographic
    var expression: Expression = .smile

    // 既存の TrainerPreferences から決まる軸（UIと整合）
    var gender: TrainerGender
    var age: TrainerAge
    var style: TrainerStyle
    var personality: TrainerPersonality
    var specialization: TrainerSpecialization

    // 将来 3D/追加UIで拡張するための自由記述
    var notes: String? = nil

    init(
        gender: TrainerGender,
        age: TrainerAge,
        style: TrainerStyle,
        personality: TrainerPersonality,
        specialization: TrainerSpecialization,
        renderingStyle: RenderingStyle = .realisticPhotographic,
        expression: Expression = .smile,
        notes: String? = nil
    ) {
        self.gender = gender
        self.age = age
        self.style = style
        self.personality = personality
        self.specialization = specialization
        self.renderingStyle = renderingStyle
        self.expression = expression
        self.notes = notes
    }

    init(preferences: TrainerPreferences) {
        self.init(
            gender: preferences.gender,
            age: preferences.age,
            style: preferences.style,
            personality: preferences.personality,
            specialization: preferences.specialization
        )
    }
}
