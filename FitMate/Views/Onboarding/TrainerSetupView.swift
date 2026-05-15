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
    private let allowsReplacingExistingTrainer: Bool

    private let selectablePersonalities: [TrainerPersonality] = [.encouraging, .strict, .logical]

    init(
        pendingTrainer: Binding<PersonalTrainer?>,
        allowsReplacingExistingTrainer: Bool = false
    ) {
        self._pendingTrainer = pendingTrainer
        self.allowsReplacingExistingTrainer = allowsReplacingExistingTrainer
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                OnboardingHeader(
                    title: "トレーナーを選ぶ",
                    subtitle: "カードを左右にスワイプして選びましょう。\n右スワイプでLikeすると専属トレーナーに設定されます。"
                )

                if user.personalTrainer != nil && !allowsReplacingExistingTrainer {
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

                    TrainerSelectionIdentityBlock(
                        name: trainer.selectionDisplayName, reading: trainer.selectionReading,
                        ageText: trainer.selectionAgeText,
                        genderText: trainer.selectionGenderText
                    )

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
                name: candidate.displayName,
                preferences: candidate.preferences,
                images: candidate.images,
                assetNamespace: candidate.assetNamespace
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
    let assetNamespace: String?
    var images: [UIImage]
    var hasRequestedImages: Bool

    static let targetImageCount = 2

    static func generateDefaults(count: Int, genderFilter: TrainerGenderFilter) -> [TrainerCandidate] {
        struct AssetTrainer {
            let name: String
            let gender: TrainerGender
            let assetNamespace: String?
            let imageNames: [String]
        }

        let assetTrainers: [AssetTrainer] = [
            AssetTrainer(name: "", gender: .female, assetNamespace: "trainer1", imageNames: ["trainer1/first", "trainer1/second"]),
            AssetTrainer(name: "", gender: .female, assetNamespace: "trainer2", imageNames: ["trainer2/first", "trainer2/second"]),
            AssetTrainer(name: "", gender: .female, assetNamespace: "trainer3", imageNames: ["trainer3/first", "trainer3/second"]),
            AssetTrainer(name: "", gender: .female, assetNamespace: "trainer4", imageNames: ["trainer4/first", "trainer4/second"]),
            AssetTrainer(name: "", gender: .female, assetNamespace: "trainer5", imageNames: ["trainer5/first", "trainer5/second"]),
            AssetTrainer(name: "", gender: .female, assetNamespace: "trainer6", imageNames: ["trainer6/first", "trainer6/second"]),
            AssetTrainer(name: "", gender: .female, assetNamespace: "trainer7", imageNames: ["trainer7/first", "trainer7/second"]),
            AssetTrainer(name: "", gender: .female, assetNamespace: "trainer8", imageNames: ["trainer8/first", "trainer8/second"]),
            AssetTrainer(name: "", gender: .female, assetNamespace: "trainer9", imageNames: ["trainer9/first", "trainer9/second"]),
            AssetTrainer(name: "", gender: .female, assetNamespace: "trainer10", imageNames: ["trainer10/first", "trainer10/second"]),
            AssetTrainer(name: "", gender: .female, assetNamespace: "trainer11", imageNames: ["trainer11/first", "trainer11/second"]),
            AssetTrainer(name: "", gender: .female, assetNamespace: "trainer12", imageNames: ["trainer12/first", "trainer12/second"]),
            AssetTrainer(name: "", gender: .female, assetNamespace: "trainer13", imageNames: ["trainer13/first", "trainer13/second"]),
            AssetTrainer(name: "", gender: .female, assetNamespace: nil, imageNames: ["trainer3_first", "trainer3_second"])
        ]

        func loadTrainerImage(named name: String) -> UIImage? {
            UIImage(named: name) ?? UIImage(named: name.replacingOccurrences(of: "/", with: "_"))
        }

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
                    assetNamespace: nil,
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

            let images = trainer.imageNames.compactMap(loadTrainerImage(named:))

            return TrainerCandidate(
                id: UUID(),
                name: trainer.name,
                preferences: randomPreferences(fixedGender: trainer.gender),
                assetNamespace: trainer.assetNamespace,
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

            TrainerSelectionIdentityBlock(
                name: candidate.displayName,
                reading: candidate.displayReading,
                ageText: candidate.displayAgeText,
                genderText: candidate.displayGenderText
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
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

            TrainerSelectionIdentityBlock(
                name: trainer.selectionDisplayName,
                reading: trainer.selectionReading,
                ageText: trainer.selectionAgeText,
                genderText: trainer.selectionGenderText,
                alignment: .center
            )

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

private struct TrainerSelectionIdentityBlock: View {
    let name: String
    let reading: String?
    let ageText: String?
    let genderText: String
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 10) {
            VStack(alignment: alignment, spacing: 4) {
                Text(name)
                    .font(.title3.weight(.bold))
                    .foregroundColor(AoiOnboardingTheme.textPrimary)
                    .multilineTextAlignment(alignment == .center ? .center : .leading)

                if let reading, !reading.isEmpty {
                    Text(reading)
                        .font(.subheadline)
                        .foregroundColor(AoiOnboardingTheme.textSecondary)
                        .multilineTextAlignment(alignment == .center ? .center : .leading)
                }
            }

            HStack(spacing: 8) {
                if let ageText, !ageText.isEmpty {
                    TrainerInfoChip(icon: "calendar", text: ageText)
                }

                TrainerInfoChip(icon: "person.fill", text: genderText)
            }
            .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
    }
}

private struct TrainerInfoChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))

            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(AoiOnboardingTheme.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(AoiOnboardingTheme.accentSoft)
        )
    }
}

private extension TrainerCandidate {
    var profile: TrainerProfile? {
        guard let assetNamespace else { return nil }
        return TrainerProfileCatalog.profile(for: assetNamespace)
    }

    var displayReading: String? {
        guard let reading = profile?.name.reading, !reading.isEmpty else {
            return nil
        }

        return reading
    }

    var displayName: String {
        if let fullName = profile?.name.full, !fullName.isEmpty {
            return fullName
        }

        if !name.isEmpty {
            return name
        }

        return "トレーナー"
    }

    var displayAgeText: String? {
        if let age = profile?.age {
            return "\(age)歳"
        }

        if assetNamespace != nil {
            return nil
        }

        return preferences.age.rawValue
    }

    var displayGenderText: String {
        preferences.gender.rawValue
    }
}

private extension PersonalTrainer {
    var selectionReading: String? {
        guard let reading = profile?.name.reading, !reading.isEmpty else {
            return nil
        }

        return reading
    }

    var selectionDisplayName: String {
        if let fullName = profile?.name.full, !fullName.isEmpty {
            return fullName
        }

        if !name.isEmpty {
            return name
        }

        return "トレーナー"
    }

    var selectionAgeText: String? {
        if let age = profile?.age {
            return "\(age)歳"
        }

        if assetNamespace != nil {
            return nil
        }

        return preferences.age.rawValue
    }

    var selectionGenderText: String {
        preferences.gender.rawValue
    }
}

