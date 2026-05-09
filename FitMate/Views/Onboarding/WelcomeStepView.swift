//
//  WelcomeStepView.swift
//  FitMate
//

import SwiftUI

struct MBTISelectionStepView: View {
    @EnvironmentObject var user: User
    @State private var animateCard = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(AoiOnboardingTheme.accentSoft)
                            .frame(width: 132, height: 132)
                            .overlay(
                                Circle()
                                    .stroke(AoiOnboardingTheme.border, lineWidth: 2)
                            )

                        Image(systemName: "person.text.rectangle.fill")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(AoiOnboardingTheme.accent)
                    }

                    OnboardingHeader(
                        title: "あなたのMBTIを教えてください",
                        subtitle: "わかる範囲で大丈夫です。\nあとからプロフィールで変更できます。",
                        footnote: "未選択のまま進んでもOK"
                    )

                    OnboardingHintPill(text: "迷ったら未選択でも大丈夫")
                }

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.title3)
                            .foregroundColor(AoiOnboardingTheme.accent)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("現在の選択")
                                .font(.caption)
                                .foregroundColor(AoiOnboardingTheme.textSecondary)

                            Text(user.mbti.rawValue)
                                .font(.title3.weight(.bold))
                                .foregroundColor(AoiOnboardingTheme.textPrimary)
                        }
                    }

                    FlexibleTagLayout(spacing: 10, runSpacing: 10) {
                        SelectableChip(
                            title: MBTIType.undecided.rawValue,
                            isSelected: user.mbti == .undecided
                        ) {
                            user.mbti = .undecided
                        }

                        ForEach(MBTIType.selectableCases, id: \.self) { type in
                            SelectableChip(
                                title: type.rawValue,
                                isSelected: user.mbti == type
                            ) {
                                user.mbti = type
                            }
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AoiOnboardingTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(AoiOnboardingTheme.border, lineWidth: 1)
                        )
                )
                .shadow(color: AoiOnboardingTheme.shadow, radius: 14, x: 0, y: 7)
                .opacity(animateCard ? 1 : 0)
                .offset(y: animateCard ? 0 : 24)
                .animation(.easeOut(duration: 0.8).delay(0.15), value: animateCard)

                VStack(spacing: 12) {
                    MBTIInfoRow(
                        icon: "lightbulb",
                        title: "ざっくりでOK",
                        detail: "正確じゃなくても大丈夫。今の自分に近いものを選べます。"
                    )

                    MBTIInfoRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "あとで変更可能",
                        detail: "プロフィール設定からいつでも見直せます。"
                    )
                }

                Spacer(minLength: 80)
            }
            .onboardingPagePadding()
        }
        .onAppear {
            animateCard = true
        }
    }
}

private struct MBTIInfoRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(AoiOnboardingTheme.accent)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AoiOnboardingTheme.textPrimary)

                Text(detail)
                    .font(.footnote)
                    .foregroundColor(AoiOnboardingTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}
