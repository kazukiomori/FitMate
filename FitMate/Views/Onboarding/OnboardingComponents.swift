import SwiftUI

enum AoiOnboardingTheme {
    static let background = Color(red: 0.99, green: 0.98, blue: 0.97)
    static let cardBackground = Color.white
    static let accent = Color(red: 0.90, green: 0.36, blue: 0.55) // dusty rose
    static let accentSoft = Color(red: 0.99, green: 0.91, blue: 0.94)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let border = Color.black.opacity(0.06)
    static let shadow = Color.black.opacity(0.06)
}

struct AoiPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AoiOnboardingTheme.accent)
                    .shadow(color: AoiOnboardingTheme.shadow, radius: 16, x: 0, y: 8)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct AoiSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(AoiOnboardingTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AoiOnboardingTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AoiOnboardingTheme.border, lineWidth: 1)
                    )
            )
            .shadow(color: AoiOnboardingTheme.shadow, radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct OnboardingHeader: View {
    let title: String
    let subtitle: String
    var footnote: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(AoiOnboardingTheme.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.body)
                .foregroundColor(AoiOnboardingTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if let footnote {
                Text(footnote)
                    .font(.footnote)
                    .foregroundColor(AoiOnboardingTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
        .padding(.top, 20)
    }
}

struct OnboardingHintPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundColor(AoiOnboardingTheme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(AoiOnboardingTheme.accentSoft)
                    .overlay(
                        Capsule()
                            .stroke(AoiOnboardingTheme.border, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func onboardingPagePadding() -> some View {
        self
            .padding(.horizontal, 22)
    }

    func onboardingBackground() -> some View {
        self
            .background(AoiOnboardingTheme.background)
    }
}
