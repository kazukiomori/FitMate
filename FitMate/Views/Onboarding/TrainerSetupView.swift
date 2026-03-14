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
    @State private var isGeneratingCandidates = false
    @State private var isFinalizing = false
    @State private var generatedTrainer: PersonalTrainer?
    @State private var generationId: String?
    @State private var candidates: [GeneratedAvatarCandidate] = []
    @State private var selectedCandidateId: String?
    
    private let avatarService = TrainerAvatarGenerationService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("あなた専用のトレーナーを作成")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // 生成されたトレーナー画像表示
                if let trainer = generatedTrainer {
                    VStack(spacing: 15) {
                        if let image = trainer.image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200, height: 200)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue, lineWidth: 4))
                        }
                        
                        Text(trainer.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(trainer.preferences.personality.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Text("「\(trainer.getTodaysMessage())」")
                            .font(.body)
                            .italic()
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                }
                
                if isGeneratingCandidates || isFinalizing {
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(isFinalizing ? "最終版を生成中..." : "候補を生成中...")
                            .font(.headline)
                        Text("少々お待ちください")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
                }

                if !candidates.isEmpty && generatedTrainer == nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("候補から1枚選んでください（6枚）")
                            .font(.headline)

                        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(candidates) { candidate in
                                Image(uiImage: candidate.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedCandidateId == candidate.id ? Color.blue : Color.clear, lineWidth: 3)
                                    )
                                    .onTapGesture {
                                        selectedCandidateId = candidate.id
                                    }
                                    .accessibilityLabel("候補アバター")
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                }
                
                // トレーナー設定フォーム
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("トレーナーの名前")
                            .font(.headline)
                        TextField("例: さくら先生", text: $trainerName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("性別")
                            .font(.headline)
                        Picker("性別", selection: $selectedGender) {
                            ForEach(TrainerGender.allCases, id: \.self) { gender in
                                Text(gender.rawValue).tag(gender)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("年代")
                            .font(.headline)
                        Picker("年代", selection: $selectedAge) {
                            ForEach(TrainerAge.allCases, id: \.self) { age in
                                Text(age.rawValue).tag(age)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("スタイル")
                            .font(.headline)
                        Picker("スタイル", selection: $selectedStyle) {
                            ForEach(TrainerStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("指導方法")
                            .font(.headline)
                        ForEach(TrainerPersonality.allCases, id: \.self) { personality in
                            Button(action: {
                                selectedPersonality = personality
                            }) {
                                HStack {
                                    Image(systemName: selectedPersonality == personality ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedPersonality == personality ? .blue : .gray)
                                    
                                    VStack(alignment: .leading) {
                                        Text(personality.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Text(personality.description)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(selectedPersonality == personality ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("専門分野")
                            .font(.headline)
                        Picker("専門分野", selection: $selectedSpecialization) {
                            ForEach(TrainerSpecialization.allCases, id: \.self) { spec in
                                Text(spec.rawValue).tag(spec)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                .padding()
                
                // トレーナー生成ボタン
                Button(candidates.isEmpty ? "候補を生成" : "候補を生成し直す") {
                    generateCandidates()
                }
                .disabled(trainerName.isEmpty || isGeneratingCandidates || isFinalizing)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(trainerName.isEmpty || isGeneratingCandidates || isFinalizing ? Color.gray : Color.green)
                .cornerRadius(10)
                .padding(.horizontal)

                if !candidates.isEmpty && generatedTrainer == nil {
                    Button("この候補で決定") {
                        finalizeTrainer()
                    }
                    .disabled(selectedCandidateId == nil || isGeneratingCandidates || isFinalizing)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedCandidateId == nil || isGeneratingCandidates || isFinalizing ? Color.gray : Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            // デフォルト名を設定
            if trainerName.isEmpty {
                trainerName = generateDefaultTrainerName()
            }
        }
    }
    
    private func generateTrainer() {
        // 互換のため残しています（旧1枚生成フロー）
        // 新フローは generateCandidates() -> finalizeTrainer() を使用
    }

    private func currentPreferences() -> TrainerPreferences {
        TrainerPreferences(
            gender: selectedGender,
            age: selectedAge,
            style: selectedStyle,
            personality: selectedPersonality,
            specialization: selectedSpecialization
        )
    }

    private func generateCandidates() {
        isGeneratingCandidates = true
        generatedTrainer = nil
        candidates = []
        selectedCandidateId = nil

        let preferences = currentPreferences()
        Task { @MainActor in
            let result = await avatarService.generateCandidates(preferences: preferences, count: 6)
            generationId = result.generationId
            candidates = result.candidates
            isGeneratingCandidates = false
        }
    }

    private func finalizeTrainer() {
        guard let generationId, let selectedCandidateId else { return }

        isFinalizing = true
        let preferences = currentPreferences()

        Task { @MainActor in
            let image = await avatarService.finalize(
                generationId: generationId,
                selectedCandidateId: selectedCandidateId,
                preferences: preferences
            )

            let trainer = PersonalTrainer(
                name: trainerName,
                preferences: preferences,
                image: image
            )
            generatedTrainer = trainer
            user.setPersonalTrainer(trainer)

            // 候補は確定後にクリア
            candidates = []
            self.selectedCandidateId = nil
            isFinalizing = false
        }
    }
    
    private func generateDefaultTrainerName() -> String {
        let names = ["さくら先生", "健太コーチ", "みゆき先生", "たけし先生", "あやか先生", "りょう先生"]
        return names.randomElement() ?? ""
    }
}


