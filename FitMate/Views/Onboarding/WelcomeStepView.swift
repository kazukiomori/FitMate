//
//  WelcomeStepView.swift
//  FitMate
//

import SwiftUI
import UIKit

struct MBTISelectionStepView: View {
    @EnvironmentObject var user: User
    let onContinue: () -> Void

    @State private var carouselSelection: MBTIType? = .esfp
    @State private var selectedFilter: MBTIFilter = .explorers

    private let displayFilters: [MBTIFilter] = [.analysts, .diplomats, .sentinels, .explorers]

    private var selectedType: MBTIType {
        carouselSelection ?? .esfp
    }

    private var activeFilter: MBTIFilter {
        selectedFilter
    }

    private var carouselTypes: [MBTIType] {
        MBTIType.selectableCases
    }

    private var selectedIndex: Int {
        carouselTypes.firstIndex(of: selectedType) ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerSection
                    heroSection
                    filterTabsSection
                    pageIndicatorSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }

            bottomActionSection
                .padding(.horizontal, 20)
                .padding(.top, 16)
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
            let initialType = user.mbti == .undecided ? MBTIType.esfp : user.mbti
            carouselSelection = initialType
            user.mbti = initialType
            selectedFilter = initialType.group
        }
        .onChange(of: carouselSelection) { newValue in
            guard let newValue else { return }
            user.mbti = newValue
            selectedFilter = newValue.group
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(carouselTypes, id: \.self) { type in
                    MBTICarouselCard(type: type)
                        .frame(width: UIScreen.main.bounds.width * 0.76)
                        .id(type)
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1.0 : 0.90)
                                .offset(y: phase.isIdentity ? 0 : 0)
                        }
                }
            }
            .padding(.horizontal, UIScreen.main.bounds.width * 0.12)
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $carouselSelection)
        .frame(height: 560)
    }
    
    private var filterTabsSection: some View {
        HStack(spacing: 0) {
            ForEach(displayFilters, id: \.self) { filter in
                let isActive = selectedFilter == filter
                
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        selectedFilter = filter
                        jumpToGroup(filter)
                    }
                } label: {
                    Text(filter.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(isActive ? filter.tint : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                if isActive {
                                    Color.white
                                } else {
                                    filter.tint
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(isActive ? filter.tint : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.92), lineWidth: 1)
        )
        .shadow(color: AoiOnboardingTheme.shadow, radius: 10, x: 0, y: 5)
    }

    private var pageIndicatorSection: some View {
        HStack(spacing: 8) {
            ForEach(Array(carouselTypes.enumerated()), id: \.offset) { index, type in
                Circle()
                    .fill(index == selectedIndex ? Color.black.opacity(0.42) : Color.black.opacity(0.14))
                    .frame(width: index == selectedIndex ? 10 : 8, height: index == selectedIndex ? 10 : 8)
                    .scaleEffect(index == selectedIndex ? 1 : 0.92)
                    .animation(.easeInOut(duration: 0.18), value: selectedIndex)
            }
        }
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
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.57, green: 0.39, blue: 0.88),
                            Color(red: 0.45, green: 0.31, blue: 0.83)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
                .shadow(color: Color(red: 0.57, green: 0.39, blue: 0.88).opacity(0.28), radius: 14, x: 0, y: 8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
    }

    private func jumpToGroup(_ filter: MBTIFilter) {
        if let firstType = carouselTypes.first(where: { $0.group == filter }) {
            carouselSelection = firstType
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

    var tint: Color {
        switch self {
        case .all:
            return AoiOnboardingTheme.accent
        case .analysts:
            return Color(red: 0.48, green: 0.40, blue: 0.77)
        case .diplomats:
            return Color(red: 0.31, green: 0.69, blue: 0.48)
        case .sentinels:
            return Color(red: 0.28, green: 0.48, blue: 0.78)
        case .explorers:
            return Color(red: 0.90, green: 0.67, blue: 0.33)
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

private struct MBTICarouselCard: View {
    let type: MBTIType

    private let cardCornerRadius: CGFloat = 32
    private let cardHeight = UIScreen.main.bounds.height * 0.55
    
    private var cardWidth: CGFloat {
        UIScreen.main.bounds.width * 0.76
    }

    var body: some View {
        let theme = type.presentation

        ZStack(alignment: .bottomLeading) {
            MBTITrainerImageView(
                assetNamespace: theme.trainerAssetNamespace,
                imageName: "first",
                contentMode: .fill
            )
            .frame(width: cardWidth, height: min(cardHeight, 520))
            .clipped()

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.78)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 6) {
                Text(type.rawValue)
                    .font(.system(size: 44, weight: .heavy, design: .serif))
                    .foregroundColor(.white)

                Text(theme.tagline)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 26)
        }
        .frame(width: cardWidth, height: min(cardHeight, 520))
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
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
    var groupTint: Color {
        group.tint
    }

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
            return MBTIPresentation(title: "管理者", badge: "番人タイプ", tagline: "静かに整えてくれる安定感", strengths: ["誠実で堅実", "責任感が強い", "現実的で頼れる"], compatibleType: "ENFP", compatibilityMessage: "違う視点をくれる相手", tint: groupTint, trainerAssetNamespace: "trainer12")
        case .isfj:
            return MBTIPresentation(title: "擁護者", badge: "番人タイプ", tagline: "やさしく寄り添う安心感", strengths: ["気配りが細かい", "思いやりが深い", "穏やかで丁寧"], compatibleType: "ENTP", compatibilityMessage: "新しい世界を見せてくれる", tint: groupTint, trainerAssetNamespace: "trainer2")
        case .infj:
            return MBTIPresentation(title: "提唱者", badge: "外交官タイプ", tagline: "静かな理想で支えてくれる", strengths: ["洞察力が高い", "誠実で一途", "深く寄り添える"], compatibleType: "ENFP", compatibilityMessage: "心を自然にひらける相手", tint: groupTint, trainerAssetNamespace: "trainer6")
        case .intj:
            return MBTIPresentation(title: "建築家", badge: "分析家タイプ", tagline: "冷静に未来を描く", strengths: ["論理的", "自立心が強い", "戦略的に考える"], compatibleType: "ENFP", compatibilityMessage: "感性を広げてくれる相手", tint: groupTint, trainerAssetNamespace: "trainer7")
        case .istp:
            return MBTIPresentation(title: "巨匠", badge: "探検家タイプ", tagline: "自然体で頼れる職人肌", strengths: ["柔軟で実践的", "観察力が高い", "冷静に対処できる"], compatibleType: "ESFJ", compatibilityMessage: "日常に温度をくれる相手", tint: groupTint, trainerAssetNamespace: "trainer14")
        case .isfp:
            return MBTIPresentation(title: "冒険家", badge: "探検家タイプ", tagline: "やさしさで彩るマイペース", strengths: ["感受性が豊か", "自然体でやさしい", "美意識が高い"], compatibleType: "ENFJ", compatibilityMessage: "気持ちを汲み取ってくれる", tint: groupTint, trainerAssetNamespace: "trainer15")
        case .infp:
            return MBTIPresentation(title: "仲介者", badge: "外交官タイプ", tagline: "理想を大切にするやさしさ", strengths: ["共感力が高い", "想像力が豊か", "芯がやわらかい"], compatibleType: "ENFJ", compatibilityMessage: "想いを形にしてくれる相手", tint: groupTint, trainerAssetNamespace: "trainer11")
        case .intp:
            return MBTIPresentation(title: "論理学者", badge: "分析家タイプ", tagline: "静かに深く考える知性派", strengths: ["発想がユニーク", "分析力が高い", "マイペースで自由"], compatibleType: "ENTJ", compatibilityMessage: "行動に移す力をくれる", tint: groupTint, trainerAssetNamespace: "trainer8")
        case .estp:
            return MBTIPresentation(title: "起業家", badge: "探検家タイプ", tagline: "今を楽しむ行動派", strengths: ["明るく社交的", "判断が速い", "場を動かせる"], compatibleType: "ISFJ", compatibilityMessage: "ほっとできる安定感", tint: groupTint, trainerAssetNamespace: "trainer16")
        case .esfp:
            return MBTIPresentation(title: "エンターテイナー", badge: "探検家タイプ", tagline: "みんなを笑顔にする\nムードメーカー", strengths: ["社交的で明るい", "好奇心が旺盛", "今を楽しむタイプ"], compatibleType: "ISFP", compatibilityMessage: "一緒にいて自然体でいられる関係に♡", tint: groupTint, trainerAssetNamespace: "trainer5")
        case .enfp:
            return MBTIPresentation(title: "運動家", badge: "外交官タイプ", tagline: "前向きなエネルギーで惹きつける", strengths: ["発想が豊か", "人を元気づける", "自由で前向き"], compatibleType: "INFJ", compatibilityMessage: "心の深さで支えてくれる", tint: groupTint, trainerAssetNamespace: "trainer4")
        case .entp:
            return MBTIPresentation(title: "討論者", badge: "分析家タイプ", tagline: "ひらめきで世界を広げる", strengths: ["会話が軽やか", "好奇心が強い", "変化を楽しめる"], compatibleType: "INFJ", compatibilityMessage: "深さのある理解者", tint: groupTint, trainerAssetNamespace: "trainer10")
        case .estj:
            return MBTIPresentation(title: "幹部", badge: "番人タイプ", tagline: "まっすぐ導くリーダー気質", strengths: ["行動力がある", "決断が早い", "責任感が強い"], compatibleType: "ISFP", compatibilityMessage: "やわらかさで支えてくれる", tint: groupTint, trainerAssetNamespace: "trainer13")
        case .esfj:
            return MBTIPresentation(title: "領事", badge: "番人タイプ", tagline: "人のために動けるあたたかさ", strengths: ["面倒見が良い", "空気が読める", "親しみやすい"], compatibleType: "ISTP", compatibilityMessage: "自然体でいられる相手", tint: groupTint, trainerAssetNamespace: "trainer3")
        case .enfj:
            return MBTIPresentation(title: "主人公", badge: "外交官タイプ", tagline: "人を導く包容力", strengths: ["共感力が高い", "前向きに励ませる", "愛情深い"], compatibleType: "INFP", compatibilityMessage: "やさしさを返してくれる", tint: groupTint, trainerAssetNamespace: "trainer1")
        case .entj:
            return MBTIPresentation(title: "指揮官", badge: "分析家タイプ", tagline: "意志の強さで道を拓く", strengths: ["戦略的", "頼もしさがある", "目標志向"], compatibleType: "INTP", compatibilityMessage: "思考を刺激し合える", tint: groupTint, trainerAssetNamespace: "trainer9")
        case .undecided:
            return .init(title: "未選択", badge: "スキップOK", tagline: "あとでゆっくり選べます", strengths: ["直感で選んでOK"], compatibleType: "--", compatibilityMessage: "あとから変更できます", tint: AoiOnboardingTheme.accent, trainerAssetNamespace: nil)
        }
        }
    }

