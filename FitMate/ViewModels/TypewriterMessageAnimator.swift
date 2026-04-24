import Foundation

@MainActor
final class TypewriterMessageAnimator: ObservableObject {
    @Published private(set) var displayedText: String = ""

    private var animationTask: Task<Void, Never>?

    deinit {
        animationTask?.cancel()
    }

    func setImmediately(_ message: String) {
        animationTask?.cancel()
        displayedText = message
    }

    func play(
        _ message: String,
        characterInterval: UInt64 = 45_000_000,
        completion: (() -> Void)? = nil
    ) {
        animationTask?.cancel()
        displayedText = ""

        animationTask = Task { [weak self] in
            guard let self else { return }

            for character in message {
                guard !Task.isCancelled else { return }
                displayedText.append(character)
                try? await Task.sleep(nanoseconds: characterInterval)
            }

            guard !Task.isCancelled else { return }
            completion?()
        }
    }
}
