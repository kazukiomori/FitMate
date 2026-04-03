//
//  TrainerSetupView.swift
//  FitMate
//

import SwiftUI
import UIKit

struct TrainerSetupView: View {
    @EnvironmentObject var user: User

    @State private var candidates: [TrainerCandidate] = []
    @State private var topIndex: Int = 0

    @Binding var pendingTrainer: PersonalTrainer?

    @State private var trainerNameDraft: String = ""

    @State private var genderFilter: TrainerGenderFilter = .any

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    @State private var isGeneratingCandidates = false
    @State private var didInitialize = false

    private let imageGenerationService = TrainerImageGenerationService()

    private let swipeThreshold: CGFloat = 120
    private let maxVisibleCards = 3

    private let selectablePersonalities: [TrainerPersonality] = [.encouraging, .strict, .logical]

    init(pendingTrainer: Binding<PersonalTrainer?>) {
        self._pendingTrainer = pendingTrainer
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                OnboardingHeader(
                    title: "トレーナーを選ぶ",
                    subtitle: "カードを左右にスワイプして選びましょう。\n右スワイプでLikeすると専属トレーナーに設定されます。"
                )

                if user.personalTrainer != nil {
                    dedicatedTrainerCard
                } else if pendingTrainer != nil {
                    pendingConfirmationCard
                } else {
                    genderFilterSection

                    OnboardingHintPill(text: "右スワイプでLike / 左でスキップ")

                    deckArea

                    if isGeneratingCandidates {
                        HStack(spacing: 10) {
                            ProgressView().tint(AoiOnboardingTheme.accent)
                            Text("候補を準備中…")
                                .font(.caption)
                                .foregroundColor(AoiOnboardingTheme.textSecondary)
                        }
                        .padding(.top, 6)
                    }
                }

                Spacer(minLength: 80)
            }
            .onboardingPagePadding()
        }
        .onAppear {
            guard !didInitialize else { return }
            didInitialize = true
            prepareCandidatesIfNeeded()
            syncNameDraftFromPendingTrainer()
        }
        .onChange(of: pendingTrainer?.id) { _ in
            syncNameDraftFromPendingTrainer()
        }
        .onChange(of: trainerNameDraft) { newValue in
            guard var trainer = pendingTrainer else { return }
            trainer.name = newValue
            pendingTrainer = trainer
        }
    }

    private func syncNameDraftFromPendingTrainer() {
        trainerNameDraft = pendingTrainer?.name ?? ""
    }

    private func setPendingTrainerPersonality(_ personality: TrainerPersonality) {
        guard var trainer = pendingTrainer else { return }
        trainer.preferences.personality = personality
        pendingTrainer = trainer
    }

    private var genderFilterSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("トレーナーの性別")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AoiOnboardingTheme.textPrimary)

            FlexibleTagLayout {
                ForEach(TrainerGenderFilter.allCases) { filter in
                    SelectableChip(
                        title: filter.label,
                        isSelected: genderFilter == filter
                    ) {
                        guard genderFilter != filter else { return }
                        genderFilter = filter
                        regenerateCandidates()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var deckArea: some View {
        ZStack {
            if topIndex >= candidates.count {
                emptyDeckCard
            } else {
                ForEach(visibleCandidates.reversed()) { candidate in
                    let index = indexOf(candidate)

                    Group {
                        if index == topIndex {
                            TrainerSwipeCard(
                                candidate: candidate,
                                dragOffset: dragOffset,
                                isTop: true
                            )
                            .gesture(dragGestureForTopCard, including: .gesture)
                        } else {
                            TrainerSwipeCard(
                                candidate: candidate,
                                dragOffset: .zero,
                                isTop: false
                            )
                        }
                    }
                    .rotationEffect(.degrees(index == topIndex ? Double(dragOffset.width / 18) : 0))
                    .offset(x: index == topIndex ? dragOffset.width : 0,
                            y: stackYOffset(for: index))
                    .scaleEffect(stackScale(for: index))
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: dragOffset)
                }
            }
        }
        .onChange(of: topIndex) {
            prefetchCandidateImagesIfNeeded()
        }
    }

    private var dedicatedTrainerCard: some View {
        VStack(spacing: 14) {
            Text("専属トレーナー")
                .font(.headline)
                .foregroundColor(AoiOnboardingTheme.textPrimary)

            if let trainer = user.personalTrainer {
                TrainerDedicatedCard(trainer: trainer)
            }

            HStack(spacing: 12) {
                Button("変更する") {
                    user.clearPersonalTrainer()
                    pendingTrainer = nil
                    regenerateCandidates()
                }
                .buttonStyle(AoiSecondaryButtonStyle())
                .frame(maxWidth: .infinity)
            }

            Text("次へ進んでも、この設定は保存されます")
                .font(.caption)
                .foregroundColor(AoiOnboardingTheme.textSecondary)
        }
    }

    private var pendingConfirmationCard: some View {
        VStack(spacing: 14) {
            Text("このトレーナーで決定しますか？")
                .font(.headline)
                .foregroundColor(AoiOnboardingTheme.textPrimary)

            if let trainer = pendingTrainer {
                VStack(spacing: 12) {
                    TrainerCardImageCarousel(images: trainer.images)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("性格")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AoiOnboardingTheme.textPrimary)

                        FlexibleTagLayout {
                            ForEach(selectablePersonalities, id: \.self) { personality in
                                SelectableChip(
                                    title: personalityChipTitle(for: personality),
                                    isSelected: trainer.preferences.personality == personality
                                ) {
                                    setPendingTrainerPersonality(personality)
                                }
                            }
                        }
                        .tint(AoiOnboardingTheme.accent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("トレーナー名")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AoiOnboardingTheme.textPrimary)

                        TextField("例: あおい先生", text: $trainerNameDraft)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AoiOnboardingTheme.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AoiOnboardingTheme.border, lineWidth: 1)
                                    )
                            )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AoiOnboardingTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AoiOnboardingTheme.border, lineWidth: 1)
                        )
                )
                .shadow(color: AoiOnboardingTheme.shadow, radius: 12, x: 0, y: 6)
            }

            Text("下のボタンで決定するか、別の候補を見るか選べます")
                .font(.caption)
                .foregroundColor(AoiOnboardingTheme.textSecondary)
        }
    }

    private func personalityChipTitle(for personality: TrainerPersonality) -> String {
        switch personality {
        case .encouraging:
            return "褒めてくれる"
        case .strict:
            return "クールで厳しい"
        case .logical:
            return "論理的"
        default:
            return personality.rawValue
        }
    }

    private var emptyDeckCard: some View {
        VStack(spacing: 10) {
            Text("候補がありません")
                .font(.headline)
                .foregroundColor(AoiOnboardingTheme.textPrimary)
            Text("すべてスキップしました")
                .font(.caption)
                .foregroundColor(AoiOnboardingTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AoiOnboardingTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AoiOnboardingTheme.border, lineWidth: 1)
                )
        )
        .shadow(color: AoiOnboardingTheme.shadow, radius: 12, x: 0, y: 6)
    }

    private var visibleCandidates: [TrainerCandidate] {
        guard topIndex < candidates.count else { return [] }
        let endExclusive = min(candidates.count, topIndex + maxVisibleCards)
        return Array(candidates[topIndex..<endExclusive])
    }

    private func indexOf(_ candidate: TrainerCandidate) -> Int {
        candidates.firstIndex(where: { $0.id == candidate.id }) ?? 0
    }

    private func stackYOffset(for index: Int) -> CGFloat {
        let diff = index - topIndex
        return CGFloat(diff) * 10
    }

    private func stackScale(for index: Int) -> CGFloat {
        let diff = index - topIndex
        return 1.0 - CGFloat(diff) * 0.04
    }

    private var dragGestureForTopCard: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation
            }
            .onEnded { value in
                isDragging = false
                handleSwipeEnd(translation: value.translation)
            }
    }

    private func handleSwipeEnd(translation: CGSize) {
        guard topIndex < candidates.count else {
            withAnimation { dragOffset = .zero }
            return
        }

        if translation.width > swipeThreshold {
            likeTopCandidate()
        } else if translation.width < -swipeThreshold {
            dislikeTopCandidate()
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                dragOffset = .zero
            }
        }
    }

    private func dislikeTopCandidate() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            dragOffset = CGSize(width: -600, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            dragOffset = .zero
            topIndex = min(topIndex + 1, candidates.count)
        }
    }

    private func likeTopCandidate() {
        let candidate = candidates[topIndex]
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            dragOffset = CGSize(width: 600, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            dragOffset = .zero
            let trainer = PersonalTrainer(
                name: candidate.name,
                preferences: candidate.preferences,
                images: candidate.images
            )

            pendingTrainer = trainer
            topIndex = min(topIndex + 1, candidates.count)
        }
    }

    private func prepareCandidatesIfNeeded() {
        guard candidates.isEmpty else {
            prefetchCandidateImagesIfNeeded()
            return
        }

        regenerateCandidates()
    }

    private func regenerateCandidates() {
        isGeneratingCandidates = true
        pendingTrainer = nil
        candidates = TrainerCandidate.generateDefaults(count: 8, genderFilter: genderFilter)
        topIndex = 0
        isGeneratingCandidates = false
        prefetchCandidateImagesIfNeeded()
    }

    private func prefetchCandidateImagesIfNeeded() {
        guard topIndex < candidates.count else { return }

        let indicesToPrefetch = [topIndex, topIndex + 1, topIndex + 2]
            .filter { $0 >= 0 && $0 < candidates.count }

        for index in indicesToPrefetch {
            if candidates[index].images.count >= TrainerCandidate.targetImageCount {
                candidates[index].hasRequestedImages = true
                continue
            }
            if candidates[index].hasRequestedImages {
                continue
            }
            candidates[index].hasRequestedImages = true
            requestImages(for: index)
        }
    }

    private func requestImages(for index: Int) {
        guard index >= 0 && index < candidates.count else { return }

        let candidateID = candidates[index].id
        let preferences = candidates[index].preferences

        func appendImageIfPossible(_ image: UIImage) {
            guard let currentIndex = candidates.firstIndex(where: { $0.id == candidateID }) else { return }
            guard candidates[currentIndex].images.count < TrainerCandidate.targetImageCount else { return }
            candidates[currentIndex].images.append(image)
        }

        // 2枚分をまとめてリクエスト（失敗してもそのまま）
        for _ in 0..<TrainerCandidate.targetImageCount {
            imageGenerationService.generateTrainerImage(preferences: preferences) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let imageResult):
                        appendImageIfPossible(imageResult.image)
                    case .failure:
                        break
                    }
                }
            }
        }
    }
}

private enum TrainerGenderFilter: String, CaseIterable, Identifiable, Equatable {
    case any
    case female
    case male

    var id: String { rawValue }

    var label: String {
        switch self {
        case .any:
            return "指定なし"
        case .female:
            return "女性"
        case .male:
            return "男性"
        }
    }

    var fixedGender: TrainerGender? {
        switch self {
        case .any:
            return nil
        case .female:
            return .female
        case .male:
            return .male
        }
    }
}

private struct TrainerCandidate: Identifiable {
    let id: UUID
    let name: String
    let preferences: TrainerPreferences
    var images: [UIImage]
    var hasRequestedImages: Bool

    static let targetImageCount = 2

    static func generateDefaults(count: Int, genderFilter: TrainerGenderFilter) -> [TrainerCandidate] {
        struct AssetTrainer {
            let name: String
            let gender: TrainerGender
            let imageNames: [String]
        }

        let assetTrainers: [AssetTrainer] = [
            AssetTrainer(name: "", gender: .female, imageNames: ["trainer1_first", "trainer1_second"]),
            AssetTrainer(name: "", gender: .female, imageNames: ["trainer2_first", "trainer2_second"]),
            AssetTrainer(name: "", gender: .female, imageNames: ["trainer3_first", "trainer3_second"])
        ]

        func randomPreferences(fixedGender: TrainerGender?) -> TrainerPreferences {
            TrainerPreferences(
                gender: fixedGender ?? (genderFilter.fixedGender ?? (TrainerGender.allCases.randomElement() ?? .female)),
                age: TrainerAge.allCases.randomElement() ?? .middle,
                style: TrainerStyle.allCases.randomElement() ?? .friendly,
                personality: TrainerPersonality.allCases.randomElement() ?? .supportive,
                specialization: TrainerSpecialization.allCases.randomElement() ?? .weightLoss
            )
        }

        // 現状アセットが女性トレーナーのみの前提。男性指定のときは生成（デモ含む）に任せる。
        if genderFilter.fixedGender == .male {
            return (0..<count).map { i in
                TrainerCandidate(
                    id: UUID(),
                    name: "健太コーチ\(i + 1)",
                    preferences: randomPreferences(fixedGender: .male),
                    images: [],
                    hasRequestedImages: false
                )
            }
        }

        let allowedTrainers = assetTrainers.filter { trainer in
            guard let fixed = genderFilter.fixedGender else { return true }
            return trainer.gender == fixed
        }

        let trainersToUse = allowedTrainers.isEmpty ? assetTrainers : allowedTrainers

        return (0..<count).map { i in
            let trainer = trainersToUse[i % trainersToUse.count]

            let images = trainer.imageNames.compactMap { UIImage(named: $0) }

            return TrainerCandidate(
                id: UUID(),
                name: trainer.name,
                preferences: randomPreferences(fixedGender: trainer.gender),
                images: images,
                hasRequestedImages: images.count >= targetImageCount
            )
        }
    }
}

private struct TrainerSwipeCard: View {
    let candidate: TrainerCandidate
    let dragOffset: CGSize
    let isTop: Bool

    private var likeProgress: CGFloat {
        min(max(dragOffset.width / 140, -1), 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                TrainerCardImageCarousel(images: candidate.images)
                .frame(maxWidth: .infinity)

                swipeLabelOverlay
                    .padding(14)
                    .allowsHitTesting(false)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AoiOnboardingTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AoiOnboardingTheme.border, lineWidth: 1)
                )
        )
        .shadow(color: AoiOnboardingTheme.shadow, radius: 18, x: 0, y: 10)
        .padding(.horizontal, 6)
    }

    @ViewBuilder
    private var swipeLabelOverlay: some View {
        if isTop {
            if likeProgress > 0.15 {
                Text("LIKE")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(AoiOnboardingTheme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AoiOnboardingTheme.cardBackground.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AoiOnboardingTheme.accent, lineWidth: 2)
                            )
                    )
                    .opacity(Double(min(likeProgress, 1)))
            } else if likeProgress < -0.15 {
                Text("SKIP")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(AoiOnboardingTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AoiOnboardingTheme.cardBackground.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AoiOnboardingTheme.border, lineWidth: 2)
                            )
                    )
                    .opacity(Double(min(-likeProgress, 1)))
            }
        }
    }
}

private struct TrainerCardImageCarousel: View {
    let images: [UIImage]

    @State private var selectedIndex: Int = 0

    private let imageAspectRatio: CGFloat = 3.0 / 4.0

    var body: some View {
        ZStack {
            if images.isEmpty {
                Rectangle()
                    .fill(AoiOnboardingTheme.accentSoft)
                    .overlay(
                        VStack(spacing: 8) {
                            ProgressView()
                                .tint(AoiOnboardingTheme.accent)
                            Text("画像を準備中")
                                .font(.caption)
                                .foregroundColor(AoiOnboardingTheme.textSecondary)
                        }
                    )
            } else {
                ZStack(alignment: .bottom) {
                    TabView(selection: $selectedIndex) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    if images.count > 1 {
                        HStack(spacing: 6) {
                            ForEach(0..<images.count, id: \.self) { index in
                                Circle()
                                    .fill(index == selectedIndex ? AoiOnboardingTheme.accent : AoiOnboardingTheme.border)
                                    .frame(width: 6, height: 6)
                                    .opacity(index == selectedIndex ? 1 : 0.6)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AoiOnboardingTheme.cardBackground.opacity(0.75))
                        )
                        .padding(.bottom, 10)
                        .allowsHitTesting(false)
                    }
                }

                if images.count > 1 {
                    HStack(spacing: 0) {
                        Color.clear
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    selectedIndex = max(selectedIndex - 1, 0)
                                }
                            }
                            .accessibilityLabel("前の画像")
                            .accessibilityAddTraits(.isButton)

                        Color.clear
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    selectedIndex = min(selectedIndex + 1, images.count - 1)
                                }
                            }
                            .accessibilityLabel("次の画像")
                            .accessibilityAddTraits(.isButton)
                    }
                }
            }
        }
        .aspectRatio(imageAspectRatio, contentMode: .fit)
        .onChange(of: images.count) { _ in
            selectedIndex = min(selectedIndex, max(images.count - 1, 0))
        }
    }
}

private struct TrainerDedicatedCard: View {
    let trainer: PersonalTrainer

    var body: some View {
        VStack(spacing: 14) {
            if let image = trainer.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 160, height: 160)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(AoiOnboardingTheme.accent, lineWidth: 4)
                    )
            } else {
                Circle()
                    .fill(AoiOnboardingTheme.accentSoft)
                    .frame(width: 160, height: 160)
                    .overlay(
                        Text("No Image")
                            .font(.caption)
                            .foregroundColor(AoiOnboardingTheme.textSecondary)
                    )
            }

            Text(trainer.name)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AoiOnboardingTheme.textPrimary)

            Text(trainer.preferences.personality.description)
                .font(.subheadline)
                .foregroundColor(AoiOnboardingTheme.textSecondary)
                .multilineTextAlignment(.center)

            Text("「\(trainer.getTodaysMessage())」")
                .font(.subheadline)
                .foregroundColor(AoiOnboardingTheme.accent)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AoiOnboardingTheme.accentSoft)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AoiOnboardingTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AoiOnboardingTheme.border, lineWidth: 1)
                )
        )
        .shadow(color: AoiOnboardingTheme.shadow, radius: 12, x: 0, y: 6)
    }
}


