import SwiftUI
import Vision
import Foundation
import UIKit

enum RecognitionMode { case ocr, api }

struct FoodAddView: View {
    @StateObject private var ocrViewModel = FoodOCRViewModel()
    @ObservedObject var recordViewModel: RecordViewModel
    let selectedMeal: MealType
    @State private var foodName = ""
    @State private var calories = ""
    @State private var selectedDate = Date()
    
    @State private var showingImagePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var imageRecognitionMode: RecognitionMode?
    @State private var selectedImage: UIImage?
    @State private var showingLiveCameraOCR = false
    @State private var showingRecognitionActionSheet = false
    @State private var isShowingRecognitionResults = false
    @Environment(\.presentationMode) var presentationMode

    // 栄養素自動取得用
    @StateObject private var nutritionVM = NutritionViewModel()
    @State private var fetchedNutrition: NutritionResponse?
    
    @StateObject private var visionMenuVM = VisionMenuViewModel()

    private let foodRecognitionService = FoodRecognitionService()
    
    private var actionSheetConfig: ActionSheet {
        ActionSheet(
            title: Text("認識方法を選択"),
            buttons: [
                .default(Text("カロリー自動読取 (OCR)")) {
                    imageRecognitionMode = .ocr
                    showingLiveCameraOCR = true
                },
                .default(Text("写真認識 (AI)")) {
                    imageRecognitionMode = .api
                    imageSourceType = .camera
                    showingImagePicker = true
                },
                .cancel()
            ]
        )
    }

    @ViewBuilder
    private func recognitionResultsSheet() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("認識結果").font(.headline).padding()
            Divider()
            ForEach(Array(visionMenuVM.recognitionResults.enumerated()), id: \.offset) { index, result in
                Button(action: {
                    selectRecognizedFood(result)
                    isShowingRecognitionResults = false
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(result.label)
                                .font(.body)
                            Text("信頼度: \(Int(result.confidence * 100))%")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                }
                if index < visionMenuVM.recognitionResults.count - 1 {
                    Divider()
                }
            }
            Spacer()
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private func formSection() -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                TextField("食品名", text: $foodName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    Task { await autoFillNutrition() }
                }) {
                    if nutritionVM.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("自動入力")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.18))
                            .cornerRadius(6)
                    }
                }
                .disabled(foodName.trimmingCharacters(in: .whitespaces).isEmpty || nutritionVM.isLoading)
            }
            if let error = nutritionVM.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            TextField("カロリー (kcal)", text: $calories)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)

            if let n = fetchedNutrition {
                HStack {
                    Label("\(String(format: "%.1f", n.protein_g))g", systemImage: "bolt.fill")
                        .foregroundColor(.orange)
                    Label("\(String(format: "%.1f", n.fat_g))g", systemImage: "drop.fill")
                        .foregroundColor(.blue)
                    Label("\(String(format: "%.1f", n.carbs_g))g", systemImage: "leaf.fill")
                        .foregroundColor(.green)
                }
                .font(.caption)
                .padding(.top, 2)
            }

            DatePicker("日時", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ja_JP"))
        }
        .padding(.horizontal)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 画像選択 & 認識ボタン
                Button(action: {
                    showingRecognitionActionSheet = true
                }) {
                    HStack {
                        Image(systemName: "camera.metering.matrix")
                            .font(.system(size: 24, weight: .bold))
                        Text("画像から入力")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(12)
                }
                .actionSheet(isPresented: $showingRecognitionActionSheet) { actionSheetConfig }
                
                // 画像プレビュー
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 140)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                // isRecognizing
                if visionMenuVM.isRecognizing {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("認識中...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // フォーム
                formSection()
                
                Spacer()
                
                // 追加ボタン
                Button(action: {
                    if !foodName.isEmpty, let cal = Int(calories) {
                        let newEntry = FoodEntry(
                            name: foodName,
                            calories: cal,
                            time: selectedDate,
                            mealType: selectedMeal
                        )
                        recordViewModel.addFoodEntry(newEntry)
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("追加")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(foodName.isEmpty || Int(calories) == nil ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(foodName.isEmpty || Int(calories) == nil)
            }
            .padding(.top)
            .navigationTitle("食事を追加")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading:
                Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            // 認識結果シート
            .sheet(isPresented: $isShowingRecognitionResults) {
                recognitionResultsSheet()
            }
            // カメラOCR
            .sheet(isPresented: $showingLiveCameraOCR) {
                LiveCameraOCRView(viewModel: ocrViewModel)
            }
            // OCR/ラベル認識反映
            .onChange(of: ocrViewModel.calorieValue) { newValue in
                if let kcal = newValue {
                    calories = String(kcal)
                }
            }
            .onChange(of: ocrViewModel.recognizedText) { newText in
                if foodName.isEmpty {
                    if let firstLine = newText.split(separator: "\n").first {
                        foodName = String(firstLine)
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(
                sourceType: imageSourceType,
                selectedImage: $selectedImage,
                onImageSelected: {
                    guard let mode = imageRecognitionMode, let img = selectedImage else { return }
                    if mode == .ocr {
                        recognizeText(from: img)
                    } else if mode == .api {
                        Task {
                            await visionMenuVM.recognizeFood(from: img)
                            // Prefer first recognition result if available
                            if let first = visionMenuVM.recognitionResults.first {
                                self.foodName = first.label
                                let estimated = visionMenuVM.estimateCalories(for: first.label)
                                self.calories = String(estimated)
                            }
                            // If the view model happens to provide nutrition estimation, keep it if already set
                            // Otherwise try to auto-fill nutrition in background if we have a name
                            if self.fetchedNutrition == nil, !self.foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                await autoFillNutrition()
                            }
                            // Show results sheet to let user pick a different candidate
                            self.isShowingRecognitionResults = !visionMenuVM.recognitionResults.isEmpty
                        }
                    }
                }
            )
        }
    }
    
    // 栄養素自動入力機能
    private func autoFillNutrition() async {
        let query = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        await nutritionVM.search(query: query)
        if let response = nutritionVM.result {
            calories = String(Int(response.calories_kcal.rounded()))
            fetchedNutrition = response
        }
    }
    
    // 認識された食事を選択
    private func selectRecognizedFood(_ result: FoodRecognitionService.FoodRecognitionResult) {
        foodName = result.label
        let estimatedCalories = visionMenuVM.estimateCalories(for: result.label)
        calories = String(estimatedCalories)
    }
    
    @MainActor
    private func recognizeText(from image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let texts = observations.compactMap { $0.topCandidates(1).first?.string }
            guard let firstLine = texts.first else { return }
            
            if !firstLine.contains("kcal"),
               !firstLine.trimmingCharacters(in: .whitespaces).isEmpty,
               Int(firstLine) == nil {
                DispatchQueue.main.async {
                    self.foodName = firstLine
                }
            }
            for text in texts {
                if let cal = extractCalories(from: text) {
                    DispatchQueue.main.async {
                        self.calories = String(cal)
                    }
                    break
                }
            }
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ja", "en"]
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("OCRエラー: \(error)")
            }
        }
    }
    
    private func extractCalories(from text: String) -> Int? {
        let pattern = #"(\d+)\s*kcal"#
        if let match = text.range(of: pattern, options: .regularExpression) {
            let value = text[match]
                .replacingOccurrences(of: "kcal", with: "")
                .trimmingCharacters(in: .whitespaces)
            return Int(value)
        }
        return nil
    }
}

// 画像Pickerはそのまま

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    let onImageSelected: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImageSelected()
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

