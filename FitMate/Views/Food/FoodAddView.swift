//
//  FoodAddView.swift
//  FitMate
//

import SwiftUI
import Vision

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
    @State private var isRecognizing = false
    @State private var recognitionResults: [FoodRecognitionService.FoodRecognitionResult] = []
    @State private var showingRecognitionResults = false
    @State private var showingLiveCameraOCR = false
    @Environment(\.presentationMode) var presentationMode

    // 栄養素自動取得用
    @StateObject private var nutritionVM = NutritionViewModel()
    
    // 自動取得した栄養素情報（カロリー以外も表示用）
    @State private var fetchedNutrition: NutritionResponse?
    
    private let foodRecognitionService = FoodRecognitionService()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 撮影した画像表示
                    if let image = selectedImage {
                        VStack {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .cornerRadius(10)
                            
                            if isRecognizing {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("食事を認識中...")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    
                    // カメラ・写真選択ボタン（認識モード別）
                    HStack(spacing: 15) {
                        Button(action: {
                            imageRecognitionMode = .ocr
                            showingLiveCameraOCR = true
                        }) {
                            VStack {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 30))
                                Text("カロリー自動読取\n(OCR)")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(10)
                        }
                        Button(action: {
                            imageRecognitionMode = .api
                            imageSourceType = .camera
                            showingImagePicker = true
                        }) {
                            VStack {
                                Image(systemName: "camera.metering.matrix")
                                    .font(.system(size: 30))
                                Text("写真認識\n(AI)")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    
                    // 認識結果表示
                    if !recognitionResults.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("認識結果")
                                .font(.headline)
                            
                            ForEach(Array(recognitionResults.enumerated()), id: \.offset) { index, result in
                                Button(action: {
                                    selectRecognizedFood(result)
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(result.label)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            Text("信頼度: \(Int(result.confidence * 100))%")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("選択")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    Text("または手動で入力")
                        .foregroundColor(.gray)
                    
                    // 手動入力フォーム
                    VStack(alignment: .leading, spacing: 15) {
                        Text("食品名")
                            .font(.headline)
                        HStack {
                            TextField("例: サラダ", text: $foodName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button(action: {
                                Task {
                                    await autoFillNutrition()
                                }
                            }) {
                                if nutritionVM.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Text("自動入力")
                                        .font(.caption)
                                }
                            }
                            .disabled(foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || nutritionVM.isLoading)
                        }
                        if let error = nutritionVM.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Text("カロリー")
                            .font(.headline)
                        TextField("例: 150", text: $calories)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                        if let n = fetchedNutrition {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text("たんぱく質: \(String(format: "%.1f", n.protein_g)) g")
                                    Text("脂質: \(String(format: "%.1f", n.fat_g)) g")
                                    Text("炭水化物: \(String(format: "%.1f", n.carbs_g)) g")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .padding(.top, 2)
                        }
                        
                        Text("日時")
                            .font(.headline)
                        DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                            .environment(\.locale, Locale(identifier: "ja_JP"))
                    }
                    
                    Spacer()
                    
                    // 追加ボタン
                    Button("追加") {
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
                    }
                    .disabled(foodName.isEmpty || Int(calories) == nil)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(foodName.isEmpty || Int(calories) == nil ? Color.gray : Color.blue)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("食事を追加")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading:
                Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(
                    sourceType: imageSourceType,
                    selectedImage: $selectedImage,
                    onImageSelected: {
                        guard let mode = imageRecognitionMode, let img = selectedImage else { return }
                        switch mode {
                        case .ocr:
                            recognizeText(from: img)
                        case .api:
                            recognizeFood()
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingLiveCameraOCR) {
            LiveCameraOCRView(viewModel: ocrViewModel)
        }
        .onChange(of: ocrViewModel.calorieValue) { newValue in
            if let kcal = newValue {
                calories = String(kcal)
            }
        }
        .onChange(of: ocrViewModel.recognizedText) { newText in
            // 一行目を商品名として使うなど
            if foodName.isEmpty {
                if let firstLine = newText.split(separator: "\n").first {
                    foodName = String(firstLine)
                }
            }
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
        let estimatedCalories = foodRecognitionService.estimateCalories(for: result.label)
        calories = String(estimatedCalories)
    }
    
    // 食事認識実行
    private func recognizeFood() {
        guard let image = selectedImage else { return }
        
        isRecognizing = true
        recognitionResults = []
        
        foodRecognitionService.recognizeFood(from: image) { result in
            DispatchQueue.main.async {
                isRecognizing = false
                
                switch result {
                case .success(let results):
                    recognitionResults = Array(results.prefix(3)) // 上位3件を表示
                    if let topResult = results.first {
                        selectRecognizedFood(topResult)
                    }
                case .failure(let error):
                    print("認識エラー: \(error.localizedDescription)")
                    // エラーハンドリング（アラート表示など）
                }
            }
        }
    }
    
    @MainActor
    private func recognizeText(from image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let texts = observations.compactMap { $0.topCandidates(1).first?.string }
            guard let firstLine = texts.first else { return }
            
            // 商品名として最初の行を使う（数値等の場合はスキップ）
            if !firstLine.contains("kcal"),
               !firstLine.trimmingCharacters(in: .whitespaces).isEmpty,
               Int(firstLine) == nil {
                DispatchQueue.main.async {
                    self.foodName = firstLine
                }
            }
            // カロリー抽出
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
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
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
