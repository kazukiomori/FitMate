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

    static func validate(_ input: String) -> TrainerChatInputValidationResult {
        let sanitized = input
            .trimmingCharacters(in: .whitespacesAndNewlines)

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

        guard sanitized.count <= maximumLength else {
            return TrainerChatInputValidationResult(
                sanitizedMessage: sanitized,
                errorMessage: "メッセージは\(maximumLength)文字以内で入力してください"
            )
        }

        return TrainerChatInputValidationResult(
            sanitizedMessage: sanitized,
            errorMessage: nil
        )
    }
}
