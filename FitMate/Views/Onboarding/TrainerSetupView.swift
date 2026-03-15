//
//  TrainerSetupView.swift
//  FitMate
//

import SwiftUI

struct TrainerSetupView: View {
    @EnvironmentObject var user: User
    @State private var selectedGender: TrainerGender = .female
    @State private var selectedAge: TrainerAge = .middle
    @State private var selectedStyle: TrainerStyle = .friendly
    @State private var selectedPersonality: TrainerPersonality = .supportive
    @State private var selectedSpecialization: TrainerSpecialization = .weightLoss
    @State private var trainerName: String = ""
    @State private var isGeneratingImage = false
    @State private var generatedTrainer: PersonalTrainer?
    
    private let imageGenerationService = TrainerImageGenerationService()

    private var preferences: TrainerPreferences {
        TrainerPreferences(
            gender: selectedGender,
            age: selectedAge,
            style: selectedStyle,
            personality: selectedPersonality,
            specialization: selectedSpecialization
        )
    }

    private var genderOptions: [TrainerGender] {
        // 既存enumは nonBinary を含むが、UIではまず男女のみを提示
        [.female, .male]
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                OnboardingHeader(
                    title: "あなた専用のトレーナー",
                    subtitle: "好みを選んで、アバターを生成しましょう。\nあとでいつでも作り直せます。"
                )

                trainerPreviewCard

                if isGeneratingImage {
                    generatingCard
                }

                editorCard

                HStack(spacing: 12) {
                    Button("おまかせ") {
                        randomizeAll()
                    }
                    .buttonStyle(AoiSecondaryButtonStyle())

                    Button("この内容で生成") {
                        generateTrainer()
                    }
                    .buttonStyle(AoiPrimaryButtonStyle())
                    .disabled(trainerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGeneratingImage)
                }

                Spacer(minLength: 80)
            }
            .onboardingPagePadding()
        }
        .onAppear {
            // デフォルト名を設定
            if trainerName.isEmpty {
                trainerName = generateDefaultTrainerName()
            }
        }
    }

    private var trainerPreviewCard: some View {
        Group {
            if let trainer = generatedTrainer {
                VStack(spacing: 14) {
                    if let image = trainer.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 160, height: 160)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AoiOnboardingTheme.accent, lineWidth: 4)
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
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("プレビュー")
                            .font(.headline)
                            .foregroundColor(AoiOnboardingTheme.textPrimary)
                        Spacer()
                        Text(trainerName.isEmpty ? "（名前未設定）" : trainerName)
                            .font(.subheadline)
                            .foregroundColor(AoiOnboardingTheme.textSecondary)
                    }

                    Text("性別: \(selectedGender.rawValue) / 年代: \(selectedAge.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(AoiOnboardingTheme.textSecondary)
                    Text("スタイル: \(selectedStyle.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(AoiOnboardingTheme.textSecondary)
                    Text("指導: \(selectedPersonality.rawValue) / 専門: \(selectedSpecialization.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(AoiOnboardingTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
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

    private var generatingCard: some View {
        HStack(spacing: 14) {
            ProgressView()
                .tint(AoiOnboardingTheme.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text("トレーナーを生成中…")
                    .font(.headline)
                    .foregroundColor(AoiOnboardingTheme.textPrimary)
                Text("少々お待ちください")
                    .font(.caption)
                    .foregroundColor(AoiOnboardingTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AoiOnboardingTheme.accentSoft)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AoiOnboardingTheme.border, lineWidth: 1)
                )
        )
    }

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("好みを選ぶ")
                .font(.headline)
                .foregroundColor(AoiOnboardingTheme.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("トレーナーの名前")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AoiOnboardingTheme.textPrimary)
                TextField("例: さくら先生", text: $trainerName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            optionSection(title: "性別") {
                FlexibleTagLayout {
                    ForEach(genderOptions, id: \.self) { gender in
                        SelectableChip(
                            title: gender.rawValue,
                            isSelected: selectedGender == gender
                        ) {
                            selectedGender = gender
                            generatedTrainer = nil
                        }
                    }
                }
            }

            optionSection(title: "年代") {
                FlexibleTagLayout {
                    ForEach(TrainerAge.allCases, id: \.self) { age in
                        SelectableChip(
                            title: age.rawValue,
                            isSelected: selectedAge == age
                        ) {
                            selectedAge = age
                            generatedTrainer = nil
                        }
                    }
                }
            }

            optionSection(title: "スタイル") {
                FlexibleTagLayout {
                    ForEach(TrainerStyle.allCases, id: \.self) { style in
                        SelectableChip(
                            title: style.rawValue,
                            isSelected: selectedStyle == style
                        ) {
                            selectedStyle = style
                            generatedTrainer = nil
                        }
                    }
                }
            }

            optionSection(title: "指導") {
                FlexibleTagLayout {
                    ForEach(TrainerPersonality.allCases, id: \.self) { personality in
                        SelectableChip(
                            title: personality.rawValue,
                            isSelected: selectedPersonality == personality
                        ) {
                            selectedPersonality = personality
                            generatedTrainer = nil
                        }
                    }
                }
            }

            optionSection(title: "専門") {
                FlexibleTagLayout {
                    ForEach(TrainerSpecialization.allCases, id: \.self) { specialization in
                        SelectableChip(
                            title: specialization.rawValue,
                            isSelected: selectedSpecialization == specialization
                        ) {
                            selectedSpecialization = specialization
                            generatedTrainer = nil
                        }
                    }
                }
            }
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

    private func optionSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AoiOnboardingTheme.textPrimary)
            content()
        }
    }
    
    private func generateTrainer() {
        isGeneratingImage = true

        imageGenerationService.generateTrainerImage(preferences: preferences) { result in
            isGeneratingImage = false
            
            switch result {
            case .success(let imageResult):
                let trainer = PersonalTrainer(
                    name: trainerName,
                    preferences: preferences,
                    image: imageResult.image
                )
                generatedTrainer = trainer
                user.setPersonalTrainer(trainer)
                
            case .failure(let error):
                print("トレーナー画像生成エラー: \(error.localizedDescription)")
                // エラーの場合もデフォルト画像でトレーナーを作成
                let trainer = PersonalTrainer(
                    name: trainerName,
                    preferences: preferences,
                    image: nil
                )
                generatedTrainer = trainer
                user.setPersonalTrainer(trainer)
            }
        }
    }

    private func randomizeAll() {
        trainerName = generateDefaultTrainerName()
        selectedGender = genderOptions.randomElement() ?? .female
        selectedAge = TrainerAge.allCases.randomElement() ?? .middle
        selectedStyle = TrainerStyle.allCases.randomElement() ?? .friendly
        selectedPersonality = TrainerPersonality.allCases.randomElement() ?? .supportive
        selectedSpecialization = TrainerSpecialization.allCases.randomElement() ?? .weightLoss
        generatedTrainer = nil
    }
    
    private func generateDefaultTrainerName() -> String {
        let names = ["さくら先生", "健太コーチ", "みゆき先生", "たけし先生", "あやか先生", "りょう先生"]
        return names.randomElement() ?? ""
    }
}


