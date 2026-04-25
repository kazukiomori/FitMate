import Foundation

struct TrainerChatInputValidationResult {
    let sanitizedMessage: String
    let errorMessage: String?

    var isValid: Bool {
        errorMessage == nil
    }
}

enum TrainerChatInputValidator {
    static let minimumLength = 3
    static let maximumLength = 120

    // 必要に応じて運用しながら追加してください
    private static let prohibitedTerms = [
        "死ね",
        "殺す",
        "暴力",
        "ばか",
        "バカ",
        "あほ",
        "アホ"
    ]

    static func validate(_ input: String) -> TrainerChatInputValidationResult {
        let sanitized = input
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let normalized = normalizedText(for: sanitized)

        guard !sanitized.isEmpty else {
            return TrainerChatInputValidationResult(
                sanitizedMessage: sanitized,
                errorMessage: "メッセージを入力してください"
            )
        }

        guard sanitized.count >= minimumLength else {
            return TrainerChatInputValidationResult(
                sanitizedMessage: sanitized,
                errorMessage: "メッセージは\(minimumLength)文字以上で入力してください"
            )
        }

        guard containsMeaningfulCharacters(in: sanitized) else {
            return TrainerChatInputValidationResult(
                sanitizedMessage: sanitized,
                errorMessage: "記号だけでは送信できません"
            )
        }

        guard sanitized.count <= maximumLength else {
            return TrainerChatInputValidationResult(
                sanitizedMessage: sanitized,
                errorMessage: "メッセージは\(maximumLength)文字以内で入力してください"
            )
        }

        guard !containsProhibitedTerm(in: normalized) else {
            return TrainerChatInputValidationResult(
                sanitizedMessage: sanitized,
                errorMessage: "このメッセージは送信できません。表現を変えて入力してください"
            )
        }

        return TrainerChatInputValidationResult(
            sanitizedMessage: sanitized,
            errorMessage: nil
        )
    }

    private static func normalizedText(for text: String) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "ja_JP"))
            .replacingOccurrences(of: "\s+", with: "", options: .regularExpression)
    }

    private static func containsMeaningfulCharacters(in text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            CharacterSet.letters.contains(scalar) || CharacterSet.decimalDigits.contains(scalar)
        }
    }

    private static func containsProhibitedTerm(in normalizedText: String) -> Bool {
        prohibitedTerms.contains { term in
            let normalizedTerm = normalizedText(for: term)
            return !normalizedTerm.isEmpty && normalizedText.contains(normalizedTerm)
        }
    }
}
