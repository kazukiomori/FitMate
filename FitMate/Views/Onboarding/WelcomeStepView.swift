//
//  WelcomeStepView.swift
//  FitMate
//

import SwiftUI
import UIKit

struct MBTISelectionStepView: View {
    @EnvironmentObject var user: User
    let onContinue: () -> Void

    @State private var animateHero = false
    @State private var selectedFilter: MBTIFilter = .all

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    private var selectedType: MBTIType {
        user.mbti == .undecided ? .esfp : user.mbti
    }

    private var filteredTypes: [MBTIType] {
        switch selectedFilter {
        case .all:
            return MBTIType.selectableCases
        default:
            return MBTIType.selectableCases.filter { $0.group == selectedFilter }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                    heroSection
                    filterTabsSection
                    gridSection
                    helperNote
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 18)
            }

            bottomActionSection
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
                .background(
                    LinearGradient(
                        colors: [
                            AoiOnboardingTheme.background.opacity(0.0),
                            AoiOnboardingTheme.background.opacity(0.96),
                            AoiOnboardingTheme.background
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .onAppear {
            animateHero = true
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("あなたに近いタイプを\n選んでください")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(AoiOnboardingTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text("あとからいつでも変更できます")
                .font(.subheadline)
                .foregroundColor(AoiOnboardingTheme.textSecondary)
        }
        .padding(.top, 4)
    }

    private var heroSection: some View {
        let theme = selectedType.presentation

        return ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.tint.opacity(0.22),
                            Color.white.opacity(0.9),
                            theme.tint.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                )

            Circle()
                .fill(theme.tint.opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 20)
                .offset(x: 68, y: 8)

            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedType.rawValue)
                            .font(.system(size: 36, weight: .heavy, design: .serif))
                            .foregroundColor(theme.tint)

                        Text(theme.title)
                            .font(.title3.weight(.bold))
                            .foregroundColor(theme.tint)

                        Text(theme.badge)
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(theme.tint, in: Capsule())
                    }

                    Text(theme.tagline)
                        .font(.headline)
                        .foregroundColor(theme.tint)
                        .lineSpacing(4)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(theme.strengths, id: \.self) { trait in
                            Label(trait, systemImage: "heart.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(AoiOnboardingTheme.textPrimary)
                                .labelStyle(.titleAndIcon)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.leading, 20)
                .padding(.top, 22)
                .padding(.bottom, 22)

                MBTITrainerImageView(
                    assetNamespace: theme.trainerAssetNamespace,
                    imageName: "first",
                    contentMode: .fit
                )
                .frame(width: 180, height: 288)
                .scaleEffect(animateHero ? 1 : 0.96)
                .opacity(animateHero ? 1 : 0)
                .animation(.easeOut(duration: 0.7), value: animateHero)
                .padding(.top, 18)
                .padding(.trailing, 10)
            }
        }
        .frame(minHeight: 400)
        .shadow(color: AoiOnboardingTheme.shadow, radius: 20, x: 0, y: 10)
    }

    private var filterTabsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("すべてのタイプから選ぶ")
                .font(.headline)
                .foregroundColor(AoiOnboardingTheme.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MBTIFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            Text(filter.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(selectedFilter == filter ? .white : AoiOnboardingTheme.textSecondary)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(selectedFilter == filter ? AoiOnboardingTheme.accent : Color.white)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(AoiOnboardingTheme.border, lineWidth: selectedFilter == filter ? 0 : 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private var gridSection: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(filteredTypes, id: \.self) { type in
                MBTIGridCard(
                    type: type,
                    isSelected: user.mbti == type
                ) {
                    user.mbti = type
                }
            }
        }
    }

    private var helperNote: some View {
        Text("※あとからプロフィール画面でいつでも変更できます")
            .font(.footnote)
            .foregroundColor(AoiOnboardingTheme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }

    private var bottomActionSection: some View {
        HStack(spacing: 14) {
            Button(action: onContinue) {
                HStack(spacing: 8) {
                    Text(user.mbti == .undecided ? "未選択で次へ" : "このタイプで次へ")
                        .font(.headline.weight(.bold))
                    Image(systemName: "chevron.right")
                        .font(.headline.weight(.bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [
                            AoiOnboardingTheme.accent,
                            Color(red: 0.97, green: 0.48, blue: 0.66)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
                .shadow(color: AoiOnboardingTheme.accent.opacity(0.28), radius: 14, x: 0, y: 8)
            }
            .buttonStyle(.plain)
        }
    }
}

private enum MBTIFilter: CaseIterable {
    case all
    case analysts
    case diplomats
    case sentinels
    case explorers

    var title: String {
        switch self {
        case .all: return "すべて"
        case .analysts: return "分析家"
        case .diplomats: return "外交官"
        case .sentinels: return "番人"
        case .explorers: return "探検家"
        }
    }
}

private struct MBTIPresentation {
    let title: String
    let badge: String
    let tagline: String
    let strengths: [String]
    let compatibleType: String
    let compatibilityMessage: String
    let tint: Color
    let trainerAssetNamespace: String?
}

private struct MBTIGridCard: View {
    let type: MBTIType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    MBTITrainerImageView(
                        assetNamespace: type.presentation.trainerAssetNamespace,
                        imageName: "smile",
                        contentMode: .fill
                    )
                    .frame(height: 82)
                    .frame(maxWidth: .infinity)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    if isSelected {
                        Circle()
                            .fill(Color(red: 0.96, green: 0.43, blue: 0.63))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 6, y: -6)
                    }
                }

                VStack(spacing: 2) {
                    Text(type.rawValue)
                        .font(.headline.weight(.bold))
                        .foregroundColor(type.presentation.tint)

                    Text(type.presentation.title)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(type.presentation.tint)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? type.presentation.tint.opacity(0.12) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isSelected ? type.presentation.tint.opacity(0.35) : AoiOnboardingTheme.border, lineWidth: isSelected ? 2 : 1)
                    )
            )
            .shadow(color: AoiOnboardingTheme.shadow, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private struct MBTITrainerImageView: View {
    let assetNamespace: String?
    let imageName: String
    let contentMode: ContentMode

    var body: some View {
        Group {
            if let image = trainerImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.55))
            }
        }
    }

    private var trainerImage: UIImage? {
        guard let assetNamespace else { return nil }
        return UIImage(named: "\(assetNamespace)/\(imageName)")
            ?? UIImage(named: "\(assetNamespace)_\(imageName)")
    }
}

private extension MBTIType {
    var group: MBTIFilter {
        switch self {
        case .intj, .intp, .entj, .entp:
            return .analysts
        case .infj, .infp, .enfj, .enfp:
            return .diplomats
        case .istj, .isfj, .estj, .esfj:
            return .sentinels
        case .istp, .isfp, .estp, .esfp:
            return .explorers
        case .undecided:
            return .all
        }
    }

    var presentation: MBTIPresentation {
        switch self {
        case .istj:
            return MBTIPresentation(title: "管理者", badge: "番人タイプ", tagline: "静かに整えてくれる安定感", strengths: ["誠実で堅実", "責任感が強い", "現実的で頼れる"], compatibleType: "ENFP", compatibilityMessage: "違う視点をくれる相手", tint: Color(red: 0.30, green: 0.48, blue: 0.74), trainerAssetNamespace: nil)
        case .isfj:
            return MBTIPresentation(title: "擁護者", badge: "番人タイプ", tagline: "やさしく寄り添う安心感", strengths: ["気配りが細かい", "思いやりが深い", "穏やかで丁寧"], compatibleType: "ENTP", compatibilityMessage: "新しい世界を見せてくれる", tint: Color(red: 0.26, green: 0.70, blue: 0.78), trainerAssetNamespace: "trainer2")
        case .infj:
            return MBTIPresentation(title: "提唱者", badge: "外交官タイプ", tagline: "静かな理想で支えてくれる", strengths: ["洞察力が高い", "誠実で一途", "深く寄り添える"], compatibleType: "ENFP", compatibilityMessage: "心を自然にひらける相手", tint: Color(red: 0.27, green: 0.70, blue: 0.63), trainerAssetNamespace: "trainer6")
        case .intj:
            return MBTIPresentation(title: "建築家", badge: "分析家タイプ", tagline: "冷静に未来を描く", strengths: ["論理的", "自立心が強い", "戦略的に考える"], compatibleType: "ENFP", compatibilityMessage: "感性を広げてくれる相手", tint: Color(red: 0.48, green: 0.40, blue: 0.77), trainerAssetNamespace: nil)
        case .istp:
            return MBTIPresentation(title: "巨匠", badge: "探検家タイプ", tagline: "自然体で頼れる職人肌", strengths: ["柔軟で実践的", "観察力が高い", "冷静に対処できる"], compatibleType: "ESFJ", compatibilityMessage: "日常に温度をくれる相手", tint: Color(red: 0.84, green: 0.60, blue: 0.20), trainerAssetNamespace: nil)
        case .isfp:
            return MBTIPresentation(title: "冒険家", badge: "探検家タイプ", tagline: "やさしさで彩るマイペース", strengths: ["感受性が豊か", "自然体でやさしい", "美意識が高い"], compatibleType: "ENFJ", compatibilityMessage: "気持ちを汲み取ってくれる", tint: Color(red: 0.90, green: 0.67, blue: 0.33), trainerAssetNamespace: nil)
        case .infp:
            return MBTIPresentation(title: "仲介者", badge: "外交官タイプ", tagline: "理想を大切にするやさしさ", strengths: ["共感力が高い", "想像力が豊か", "芯がやわらかい"], compatibleType: "ENFJ", compatibilityMessage: "想いを形にしてくれる相手", tint: Color(red: 0.42, green: 0.74, blue: 0.45), trainerAssetNamespace: nil)
        case .intp:
            return MBTIPresentation(title: "論理学者", badge: "分析家タイプ", tagline: "静かに深く考える知性派", strengths: ["発想がユニーク", "分析力が高い", "マイペースで自由"], compatibleType: "ENTJ", compatibilityMessage: "行動に移す力をくれる", tint: Color(red: 0.56, green: 0.45, blue: 0.78), trainerAssetNamespace: nil)
        case .estp:
            return MBTIPresentation(title: "起業家", badge: "探検家タイプ", tagline: "今を楽しむ行動派", strengths: ["明るく社交的", "判断が速い", "場を動かせる"], compatibleType: "ISFJ", compatibilityMessage: "ほっとできる安定感", tint: Color(red: 0.92, green: 0.53, blue: 0.21), trainerAssetNamespace: nil)
        case .esfp:
            return MBTIPresentation(title: "エンターテイナー", badge: "探検家タイプ", tagline: "みんなを笑顔にする\nムードメーカー", strengths: ["社交的で明るい", "好奇心が旺盛", "今を楽しむタイプ"], compatibleType: "ISFP", compatibilityMessage: "一緒にいて自然体でいられる関係に♡", tint: Color(red: 0.95, green: 0.48, blue: 0.63), trainerAssetNamespace: "trainer5")
        case .enfp:
            return MBTIPresentation(title: "運動家", badge: "外交官タイプ", tagline: "前向きなエネルギーで惹きつける", strengths: ["発想が豊か", "人を元気づける", "自由で前向き"], compatibleType: "INFJ", compatibilityMessage: "心の深さで支えてくれる", tint: Color(red: 0.29, green: 0.73, blue: 0.40), trainerAssetNamespace: "trainer4")
        case .entp:
            return MBTIPresentation(title: "討論者", badge: "分析家タイプ", tagline: "ひらめきで世界を広げる", strengths: ["会話が軽やか", "好奇心が強い", "変化を楽しめる"], compatibleType: "INFJ", compatibilityMessage: "深さのある理解者", tint: Color(red: 0.51, green: 0.43, blue: 0.78), trainerAssetNamespace: nil)
        case .estj:
            return MBTIPresentation(title: "幹部", badge: "番人タイプ", tagline: "まっすぐ導くリーダー気質", strengths: ["行動力がある", "決断が早い", "責任感が強い"], compatibleType: "ISFP", compatibilityMessage: "やわらかさで支えてくれる", tint: Color(red: 0.28, green: 0.48, blue: 0.78), trainerAssetNamespace: nil)
        case .esfj:
            return MBTIPresentation(title: "領事", badge: "番人タイプ", tagline: "人のために動けるあたたかさ", strengths: ["面倒見が良い", "空気が読める", "親しみやすい"], compatibleType: "ISTP", compatibilityMessage: "自然体でいられる相手", tint: Color(red: 0.27, green: 0.63, blue: 0.82), trainerAssetNamespace: "trainer3")
        case .enfj:
            return MBTIPresentation(title: "主人公", badge: "外交官タイプ", tagline: "人を導く包容力", strengths: ["共感力が高い", "前向きに励ませる", "愛情深い"], compatibleType: "INFP", compatibilityMessage: "やさしさを返してくれる", tint: Color(red: 0.31, green: 0.69, blue: 0.48), trainerAssetNamespace: "trainer1")
        case .entj:
            return MBTIPresentation(title: "指揮官", badge: "分析家タイプ", tagline: "意志の強さで道を拓く", strengths: ["戦略的", "頼もしさがある", "目標志向"], compatibleType: "INTP", compatibilityMessage: "思考を刺激し合える", tint: Color(red: 0.45, green: 0.36, blue: 0.70), trainerAssetNamespace: nil)
        case .undecided:
            return .init(title: "未選択", badge: "スキップOK", tagline: "あとでゆっくり選べます", strengths: ["直感で選んでOK"], compatibleType: "--", compatibilityMessage: "あとから変更できます", tint: AoiOnboardingTheme.accent, trainerAssetNamespace: nil)
        }
        }
    }

