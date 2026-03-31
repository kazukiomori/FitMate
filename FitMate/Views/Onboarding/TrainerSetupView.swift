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

    @State private var pendingTrainer: PersonalTrainer? = nil

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    @State private var isGeneratingCandidates = false
    @State private var didInitialize = false

    private let imageGenerationService = TrainerImageGenerationService()

    private let swipeThreshold: CGFloat = 120
    private let maxVisibleCards = 3

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
                    OnboardingHintPill(text: "右スワイプでLike / 左でスキップ")

                    deckArea
                        .frame(height: 380)

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
        }
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
                            .gesture(dragGestureForTopCard)
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
        .onChange(of: topIndex) { _ in
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
                    prepareCandidatesIfNeeded()
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
                TrainerDedicatedCard(trainer: trainer)
            }

            HStack(spacing: 12) {
                Button("別のトレーナーを見る") {
                    pendingTrainer = nil
                }
                .buttonStyle(AoiSecondaryButtonStyle())
                .frame(maxWidth: .infinity)

                Button("このトレーナーに決定") {
                    guard let trainer = pendingTrainer else { return }
                    user.setPersonalTrainer(trainer)
                    pendingTrainer = nil
                }
                .buttonStyle(AoiPrimaryButtonStyle())
                .frame(maxWidth: .infinity)
            }

            Text("この画面でいつでも変更できます")
                .font(.caption)
                .foregroundColor(AoiOnboardingTheme.textSecondary)
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
                image: candidate.image
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

        isGeneratingCandidates = true
        candidates = TrainerCandidate.generateDefaults(count: 8)
        topIndex = 0
        isGeneratingCandidates = false

        prefetchCandidateImagesIfNeeded()
    }

    private func prefetchCandidateImagesIfNeeded() {
        guard topIndex < candidates.count else { return }

        let indicesToPrefetch = [topIndex, topIndex + 1, topIndex + 2]
            .filter { $0 >= 0 && $0 < candidates.count }

        for index in indicesToPrefetch {
            if candidates[index].hasRequestedImage {
                continue
            }
            candidates[index].hasRequestedImage = true
            requestImage(for: index)
        }
    }

    private func requestImage(for index: Int) {
        let preferences = candidates[index].preferences
        imageGenerationService.generateTrainerImage(preferences: preferences) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let imageResult):
                    candidates[index].image = imageResult.image
                case .failure:
                    candidates[index].image = nil
                }
            }
        }
    }
}

private struct TrainerCandidate: Identifiable {
    let id: UUID
    let name: String
    let preferences: TrainerPreferences
    var image: UIImage?
    var hasRequestedImage: Bool

    static func generateDefaults(count: Int) -> [TrainerCandidate] {
        let namePool = [
            "さくら先生", "健太コーチ", "みゆき先生", "たけし先生", "あやか先生", "りょう先生",
            "はるか先生", "しゅんコーチ", "ゆう先生", "あおい先生"
        ]

        func randomPreferences() -> TrainerPreferences {
            TrainerPreferences(
                gender: TrainerGender.allCases.randomElement() ?? .female,
                age: TrainerAge.allCases.randomElement() ?? .middle,
                style: TrainerStyle.allCases.randomElement() ?? .friendly,
                personality: TrainerPersonality.allCases.randomElement() ?? .supportive,
                specialization: TrainerSpecialization.allCases.randomElement() ?? .weightLoss
            )
        }

        return (0..<count).map { i in
            TrainerCandidate(
                id: UUID(),
                name: namePool[i % namePool.count],
                preferences: randomPreferences(),
                image: nil,
                hasRequestedImage: false
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
                cardImage
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .clipped()

                swipeLabelOverlay
                    .padding(14)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(candidate.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AoiOnboardingTheme.textPrimary)
                    Spacer()
                    Text(candidate.preferences.specialization.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AoiOnboardingTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(AoiOnboardingTheme.accentSoft)
                        )
                }

                Text("性別: \(candidate.preferences.gender.rawValue) / 年代: \(candidate.preferences.age.rawValue)")
                    .font(.footnote)
                    .foregroundColor(AoiOnboardingTheme.textSecondary)
                Text("スタイル: \(candidate.preferences.style.rawValue)")
                    .font(.footnote)
                    .foregroundColor(AoiOnboardingTheme.textSecondary)
                Text("指導: \(candidate.preferences.personality.rawValue)")
                    .font(.footnote)
                    .foregroundColor(AoiOnboardingTheme.textSecondary)
            }
            .padding(16)
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

    private var cardImage: some View {
        ZStack {
            if let image = candidate.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
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
            }
        }
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


