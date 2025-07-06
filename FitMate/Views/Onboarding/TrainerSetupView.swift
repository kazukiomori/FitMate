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
                
                if isGeneratingImage {
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("あなた専用のトレーナーを生成中...")
                            .font(.headline)
                        Text("少々お待ちください")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
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
                Button("トレーナーを生成") {
                    generateTrainer()
                }
                .disabled(trainerName.isEmpty || isGeneratingImage)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(trainerName.isEmpty || isGeneratingImage ? Color.gray : Color.green)
                .cornerRadius(10)
                .padding(.horizontal)
                
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
        isGeneratingImage = true
        
        let preferences = TrainerPreferences(
            gender: selectedGender,
            age: selectedAge,
            style: selectedStyle,
            personality: selectedPersonality,
            specialization: selectedSpecialization
        )
        
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
    
    private func generateDefaultTrainerName() -> String {
        let names = ["さくら先生", "健太コーチ", "みゆき先生", "たけし先生", "あやか先生", "りょう先生"]
        return names.randomElement() ?? ""
    }
}


