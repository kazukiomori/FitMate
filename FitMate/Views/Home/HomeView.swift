//
//  HomeView.swift
//  FitMate
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var user: User
    @EnvironmentObject var recordViewModel: RecordViewModel
    @AppStorage("lastHomeOpenedDayKey") private var lastHomeOpenedDayKey: String = ""
    @State private var isFirstHomeOpenToday = false
    @State private var userMessage: String = ""
    @FocusState private var isMessageFieldFocused: Bool

    private var dayKeyFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private var todayDayKey: String {
        dayKeyFormatter.string(from: Date())
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let trainer = user.personalTrainer {
                        TrainerConversationSection(
                            trainer: trainer,
                            isFirstOpenToday: isFirstHomeOpenToday,
                            userMessage: $userMessage,
                            isMessageFieldFocused: $isMessageFieldFocused,
                            recordViewModel: recordViewModel
                        )
                    }
                }
                .padding()
            }
            .background(Color.gray.opacity(0.1))
            .simultaneousGesture(
                TapGesture().onEnded {
                    isMessageFieldFocused = false
                }
            )
        }
        .onAppear {
            updateHomeOpenState()
        }
    }

    private func updateHomeOpenState() {
        isFirstHomeOpenToday = lastHomeOpenedDayKey != todayDayKey

        if isFirstHomeOpenToday {
            user.registerAppLaunchRewardOnHomeArrival()
            lastHomeOpenedDayKey = todayDayKey
        }
    }
}

private struct TrainerConversationSection: View {
    private enum ChatInputMode {
        case none
        case weight
        case food
        case dailyChat

        var promptMessage: String {
            switch self {
            case .none:
                return ""
            case .weight:
                return "体重をこのままチャットで送ってね！ 例: 52.4kg"
            case .food:
                return "食べたものをこのままチャットで送ってね！ 例: 朝ごはんにおにぎりと味噌汁"
            case .dailyChat:
                return "今日はどんなことを話そうか？気軽に送ってね！"
            }
        }

        var inputPlaceholder: String {
            switch self {
            case .none:
                return "今日の相談や気持ちを入力してください"
            case .weight:
                return "体重を入力してください"
            case .food:
                return "食事内容を入力してください"
            case .dailyChat:
                return "日常会話を入力してください"
            }
        }

        var apiPrefix: String {
            switch self {
            case .none:
                return ""
            case .weight:
                return "体重報告: "
            case .food:
                return "食事報告: "
            case .dailyChat:
                return "日常会話: "
            }
        }
    }

    @EnvironmentObject var user: User
    let trainer: PersonalTrainer
    let isFirstOpenToday: Bool
    @Binding var userMessage: String
    @FocusState.Binding var isMessageFieldFocused: Bool
    @ObservedObject var recordViewModel: RecordViewModel

    @State private var showingWeightInput = false
    @State private var showingFoodAdd = false
    @State private var trainerAvatarExpression: TrainerAvatarExpression = .smile
    @State private var chatValidationMessage: String?
    @State private var selectedChatInputMode: ChatInputMode = .none
    @StateObject private var trainerMessageAnimator = TypewriterMessageAnimator()
    @StateObject private var coachMessageViewModel = CoachMessageViewModel()

    private var trainerMessage: String {
        trainer.getHomeMessage(isFirstOpenToday: isFirstOpenToday)
    }

    private var displayedTrainerMessage: String {
        trainerMessageAnimator.displayedText.isEmpty ? trainerMessage : trainerMessageAnimator.displayedText
    }

    private func setTrainerAvatarExpression(_ expression: TrainerAvatarExpression) {
        trainerAvatarExpression = expression
    }

    private func playTrainerMessage(
        _ message: String,
        expression: TrainerAvatarExpression = .smile,
        characterInterval: UInt64 = 45_000_000,
        completion: (() -> Void)? = nil
    ) {
        setTrainerAvatarExpression(expression)
        trainerMessageAnimator.play(message, characterInterval: characterInterval, completion: completion)
    }

    private func handleFoodReportTap() {
        if selectedChatInputMode == .food, user.isPremiumUser {
            isMessageFieldFocused = true
            return
        }

        isMessageFieldFocused = false
        selectedChatInputMode = .food

        if user.isPremiumUser {
            playTrainerMessage(ChatInputMode.food.promptMessage) {
                userMessage = ""
                isMessageFieldFocused = true
            }
            return
        }

        playTrainerMessage("何を食べたか教えてね！") {
            showingFoodAdd = true
        }
    }

    private func handleWeightReportTap() {
        if selectedChatInputMode == .weight, user.isPremiumUser {
            isMessageFieldFocused = true
            return
        }

        isMessageFieldFocused = false
        selectedChatInputMode = .weight

        if user.isPremiumUser {
            playTrainerMessage(ChatInputMode.weight.promptMessage) {
                userMessage = ""
                isMessageFieldFocused = true
            }
            return
        }

        playTrainerMessage("今日の体重を教えてね！") {
            showingWeightInput = true
        }
    }

    private func handleDailyChatTap() {
        if selectedChatInputMode == .dailyChat {
            isMessageFieldFocused = true
            return
        }

        selectedChatInputMode = .dailyChat
        playTrainerMessage(ChatInputMode.dailyChat.promptMessage) {
            isMessageFieldFocused = true
        }
    }

    private var sanitizedUserMessage: String {
        userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var currentMessageCount: Int {
        sanitizedUserMessage.count
    }

    private var intimacyLevel: Int {
        user.intimacyLevel
    }

    private var intimacyTitle: String {
        user.intimacyTitle
    }

    private var intimacyProgress: Double {
        user.intimacyProgressToNextLevel
    }

    private var intimacyGainAmount: Int {
        user.latestIntimacyGain
    }

    private var intimacyGainTrigger: Int {
        user.intimacyGainEventCount
    }

    private var inputPlaceholder: String {
        selectedChatInputMode.inputPlaceholder
    }

    private var helperText: String {
        switch selectedChatInputMode {
        case .none:
            return "\(TrainerChatInputValidator.minimumLength)〜\(TrainerChatInputValidator.maximumLength)文字で入力"
        case .weight:
            return "プレミアム: 数字を含めて送信すると体重記録できます"
        case .food:
            return "プレミアム: チャットで食事報告できます"
        case .dailyChat:
            return "プレミアム/通常どちらでも日常会話できます"
        }
    }

    private func extractedWeight(from input: String) -> Double? {
        let normalized = input
            .folding(options: [.widthInsensitive], locale: Locale(identifier: "ja_JP"))
            .replacingOccurrences(of: ",", with: ".")

        guard let regex = try? NSRegularExpression(pattern: #"\d+(?:\.\d+)?"#) else {
            return nil
        }

        let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
        guard let match = regex.firstMatch(in: normalized, options: [], range: range),
              let matchRange = Range(match.range, in: normalized) else {
            return nil
        }

        let value = String(normalized[matchRange])
        return Double(value)
    }

    private func handleWeightMessageSend(_ message: String) {
        let sanitized = message.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !sanitized.isEmpty else {
            chatValidationMessage = "体重を入力してください"
            return
        }

        guard let weightValue = extractedWeight(from: sanitized) else {
            chatValidationMessage = "体重の数字を含めて入力してください"
            return
        }

        guard weightValue > 0 else {
            chatValidationMessage = "正しい体重を入力してください"
            return
        }

        isMessageFieldFocused = false
        chatValidationMessage = nil
        userMessage = sanitized
        selectedChatInputMode = .none

        recordViewModel.addWeightEntry(weight: weightValue)
        user.registerWeightRecord()
        playTrainerMessage("体重\(String(format: "%.1f", weightValue))kgを記録したよ！", expression: .smile)
        userMessage = ""
    }

    private func handleValidatedChatSend(_ message: String) {
        isMessageFieldFocused = false
        chatValidationMessage = nil
        userMessage = message
        let entryMode = selectedChatInputMode
        let apiMessage = entryMode.apiPrefix + message
        selectedChatInputMode = .none

        Task {
            await coachMessageViewModel.send(
                inputText: apiMessage,
                trainerGender: trainer.preferences.gender,
                trainerPersonality: trainer.preferences.personality,
                intimacyLevel: intimacyLevel
            )

            if let response = coachMessageViewModel.response {
                switch entryMode {
                case .weight:
                    user.registerWeightRecord()
                case .food:
                    user.registerFoodRecord()
                case .dailyChat:
                    break
                case .none:
                    break
                }

                switch response.type {
                case .nutrition:
                    playTrainerMessage(response.comment, expression: .smile)

                case .chat:
                    playTrainerMessage(response.comment, expression: .smile)
                }
            } else if let errorMessage = coachMessageViewModel.errorMessage {
                chatValidationMessage = errorMessage
                setTrainerAvatarExpression(.sad)
            }
        }
    }

    private func handleChatSendTap() {
        if selectedChatInputMode == .weight {
            handleWeightMessageSend(userMessage)
            return
        }

        let validationResult = TrainerChatInputValidator.validate(userMessage)

        guard validationResult.isValid else {
            chatValidationMessage = validationResult.errorMessage
            return
        }

        handleValidatedChatSend(validationResult.sanitizedMessage)
    }

    var body: some View {
        VStack(spacing: 18) {
            trainerHeroImage

            VStack(spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    trainerAvatar

                    VStack(alignment: .leading, spacing: 8) {
                        Text(trainer.name.isEmpty ? "あなたのトレーナー" : trainer.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(displayedTrainerMessage)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineSpacing(5)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.white)

                            TrainerSpeechBubbleTail()
                                .fill(Color.white)
                                .frame(width: 14, height: 18)
                                .offset(x: -8, y: 10)
                        }
                    )

                    Spacer(minLength: 0)
                }

                quickActionButtons

                HStack(alignment: .bottom, spacing: 12) {
                    Spacer(minLength: 32)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            TextField(inputPlaceholder, text: $userMessage, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(2...4)
                                .focused($isMessageFieldFocused)

                            Button(action: {
                                handleChatSendTap()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.black)
                                        .frame(width: 38, height: 38)

                                    if coachMessageViewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "paperplane.fill")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .disabled(coachMessageViewModel.isLoading)
                        }

                        HStack(spacing: 8) {
                            if let chatValidationMessage {
                                Text(chatValidationMessage)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            } else {
                                Text(helperText)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer(minLength: 0)

                            Text("\(currentMessageCount)/\(TrainerChatInputValidator.maximumLength)")
                                .font(.caption2)
                                .foregroundColor(currentMessageCount > TrainerChatInputValidator.maximumLength ? .red : .secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.97, green: 0.97, blue: 0.98))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                }
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.97, blue: 0.95),
                    Color(red: 0.95, green: 0.96, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
        .sheet(isPresented: $showingWeightInput) {
            WeightInputView(recordViewModel: recordViewModel)
        }
        .sheet(isPresented: $showingFoodAdd) {
            FoodAddView(recordViewModel: recordViewModel, selectedMeal: .breakfast)
        }
        .onAppear {
            trainerMessageAnimator.setImmediately(trainerMessage)
        }
        .onChange(of: isFirstOpenToday) { _ in
            trainerMessageAnimator.setImmediately(trainerMessage)
        }
        .onChange(of: userMessage) { _ in
            if chatValidationMessage != nil {
                chatValidationMessage = TrainerChatInputValidator.validate(userMessage).errorMessage
            }
        }
    }

    private var quickActionButtons: some View {
        HStack(spacing: 10) {
            HomeQuickActionButton(
                title: "体重を報告",
                icon: "scalemass.fill",
                isSelected: selectedChatInputMode == .weight,
                foregroundColor: .white,
                iconForegroundColor: Color(red: 0.31, green: 0.74, blue: 0.47),
                background: LinearGradient(
                    colors: [
                        Color(red: 0.40, green: 0.84, blue: 0.55),
                        Color(red: 0.30, green: 0.74, blue: 0.46)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ) {
                handleWeightReportTap()
            }

            HomeQuickActionButton(
                title: "食事を報告",
                icon: "fork.knife",
                isSelected: selectedChatInputMode == .food,
                foregroundColor: .black,
                iconForegroundColor: .black,
                background: LinearGradient(
                    colors: [
                        Color(red: 1.00, green: 0.86, blue: 0.30),
                        Color(red: 1.00, green: 0.78, blue: 0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ) {
                handleFoodReportTap()
            }

            HomeQuickActionButton(
                title: "日常会話",
                icon: "ellipsis.message.fill",
                isSelected: selectedChatInputMode == .dailyChat,
                foregroundColor: .white,
                iconForegroundColor: Color(red: 0.36, green: 0.58, blue: 0.93),
                background: LinearGradient(
                    colors: [
                        Color(red: 0.63, green: 0.81, blue: 1.00),
                        Color(red: 0.46, green: 0.68, blue: 0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ) {
                handleDailyChatTap()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var trainerHeroImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.90, blue: 0.90),
                            Color(red: 0.96, green: 0.95, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let image = trainer.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.rectangle")
                        .font(.system(size: 42))
                        .foregroundColor(.pink.opacity(0.7))

                    Text("Trainer")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.2)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
        )
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 4) {
                Text(isFirstOpenToday ? "今日のあいさつ" : "トレーナーチャット")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))

                Text(trainer.name.isEmpty ? "あなたのトレーナー" : trainer.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(18)
        }
        .overlay(alignment: .topLeading) {
            TrainerIntimacyMeter(
                level: intimacyLevel,
                title: intimacyTitle,
                progress: intimacyProgress,
                gainAmount: intimacyGainAmount,
                gainTrigger: intimacyGainTrigger
            )
            .padding(.top, 18)
            .padding(.leading, 18)
        }
    }

    private var trainerAvatar: some View {
        Group {
            if let image = trainer.avatarImage(for: trainerAvatarExpression) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .foregroundColor(.pink.opacity(0.8))
                    .background(Color.white)
            }
        }
        .frame(width: 48, height: 48)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 2)
        )
        .onAppear {
            setTrainerAvatarExpression(.smile)
        }
    }
}

private struct TrainerIntimacyMeter: View {
    let level: Int
    let title: String
    let progress: Double
    let gainAmount: Int
    let gainTrigger: Int
    @State private var isPulsing = false
    @State private var animatedProgress: Double = 0
    @State private var displayedLevel: Int = 1
    @State private var showGainBadge = false
    @State private var gainBadgeOffset: CGFloat = 0
    @State private var gainBadgeOpacity: Double = 0
    @State private var shouldBounceHeart = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                ZStack {
                    Heart()
                        .fill(Color.pink.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .blur(radius: isPulsing ? 9 : 3)

                    Heart()
                        .stroke(Color.pink, lineWidth: 2)
                        .frame(width: 43, height: 43)
                        .scaleEffect(shouldBounceHeart ? 1.18 : (isPulsing ? 1.08 : 1.0))
                        .opacity(isPulsing ? 0.25 : 0.85)

                    Heart()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.pink, .red]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                        .scaleEffect(shouldBounceHeart ? 1.12 : 1.0)

                    if showGainBadge, gainAmount > 0 {
                        Text("+\(gainAmount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(red: 1.0, green: 0.34, blue: 0.55))
                            )
                            .shadow(color: Color.black.opacity(0.16), radius: 6, x: 0, y: 3)
                            .offset(x: 20, y: gainBadgeOffset)
                            .opacity(gainBadgeOpacity)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("親密度 Lv.\(displayedLevel)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("\"\(title)\"")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.95))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.black.opacity(0.45))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                )

                Spacer(minLength: 0)
            }

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 122, height: 7)

                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.pink, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 122 * animatedProgress, height: 7)
            }
            .padding(.leading, 2)
        }
        .onAppear {
            displayedLevel = level
            animatedProgress = progress
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .onChange(of: progress) { newProgress in
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                animatedProgress = newProgress
            }
        }
        .onChange(of: gainTrigger) { _ in
            guard gainAmount > 0 else { return }
            animateGain()
        }
        .onChange(of: level) { newLevel in
            displayedLevel = newLevel
        }
    }

    private func animateGain() {
        showGainBadge = true
        gainBadgeOffset = 8
        gainBadgeOpacity = 0

        let targetLevel = level
        let targetProgress = progress
        let leveledUp = targetLevel > displayedLevel

        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
            shouldBounceHeart = true
        }

        withAnimation(.easeOut(duration: 0.18)) {
            gainBadgeOpacity = 1
            gainBadgeOffset = -8
        }

        if leveledUp {
            withAnimation(.easeOut(duration: 0.28)) {
                animatedProgress = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                displayedLevel = targetLevel
                animatedProgress = 0

                withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                    animatedProgress = targetProgress
                }
            }
        } else {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                animatedProgress = targetProgress
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                shouldBounceHeart = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeIn(duration: 0.25)) {
                gainBadgeOpacity = 0
                gainBadgeOffset = -18
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showGainBadge = false
        }
    }
}

struct Heart: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // ハートの描画開始点（下の尖った部分）
        let bottom = CGPoint(x: rect.width / 2, y: rect.height * 0.95)
        path.move(to: bottom)
        // 左側のカーブ
        // addCurve(to: 終点, control1: 制御点1, control2: 制御点2)
        path.addCurve(to: CGPoint(x: 0, y: rect.height * 0.3),
                      control1: CGPoint(x: rect.width * 0.35, y: rect.height * 0.8),
                      control2: CGPoint(x: 0, y: rect.height * 0.55))
        // 左上の山から中央のくぼみへ
        path.addCurve(to: CGPoint(x: rect.width / 2, y: rect.height * 0.2),
                      control1: CGPoint(x: 0, y: 0),
                      control2: CGPoint(x: rect.width * 0.45, y: 0))
        // 右上の山
        path.addCurve(to: CGPoint(x: rect.width, y: rect.height * 0.3),
                      control1: CGPoint(x: rect.width * 0.55, y: 0),
                      control2: CGPoint(x: rect.width, y: 0))
        // 右側から下の尖った部分へ
        path.addCurve(to: bottom,
                      control1: CGPoint(x: rect.width, y: rect.height * 0.55),
                      control2: CGPoint(x: rect.width * 0.65, y: rect.height * 0.8))
        path.closeSubpath()
        return path
    }
}

private struct HomeQuickActionButton<Background: ShapeStyle>: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let foregroundColor: Color
    let iconForegroundColor: Color
    let background: Background
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                HStack(spacing: 7) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.22))
                            .frame(width: 20, height: 20)

                        Image(systemName: icon)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(iconForegroundColor)
                    }

                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(foregroundColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(background, in: Capsule())
            .saturation(isSelected ? 1.15 : 0.88)
            .brightness(isSelected ? -0.03 : 0)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isSelected ? 0.34 : 0.18), lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.18 : 0.12), radius: isSelected ? 14 : 10, x: 0, y: isSelected ? 7 : 5)
        }
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        .buttonStyle(.plain)
    }
}

private struct TrainerSpeechBubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

struct HealthActivityCard: View {
    @ObservedObject var healthKitManager: HealthKitManager

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("今日の活動")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {
                    healthKitManager.refreshHealthData()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
            }

            if healthKitManager.isAuthorized {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "figure.walk")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                Text("歩数")
                                    .font(.headline)
                            }

                            Text("\(healthKitManager.stepCount)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)

                            let stepGoal = 8000
                            let stepProgress = min(Double(healthKitManager.stepCount) / Double(stepGoal), 1.0)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("目標: \(stepGoal)歩")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                ProgressView(value: stepProgress)
                                    .accentColor(.green)
                                    .frame(height: 6)

                                Text("\(Int(stepProgress * 100))%達成")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            HStack {
                                Text("消費カロリー")
                                    .font(.headline)
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                            }

                            Text("\(Int(healthKitManager.activeEnergyBurned))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.red)

                            Text("kcal")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            Text("活動レベル")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            let activityLevel = getActivityLevel()
                            HStack {
                                Text(activityLevel.title)
                                    .font(.headline)
                                    .foregroundColor(activityLevel.color)

                                Circle()
                                    .fill(activityLevel.color)
                                    .frame(width: 8, height: 8)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("推定距離")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            let distance = Double(healthKitManager.stepCount) * 0.0008
                            Text(String(format: "%.1f km", distance))
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 40))
                        .foregroundColor(.red)

                    Text("HealthKitへのアクセス許可が必要です")
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text("設定 > プライバシーとセキュリティ > ヘルスケアから許可してください")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }

    private func getActivityLevel() -> (title: String, color: Color) {
        let steps = healthKitManager.stepCount
        let calories = healthKitManager.activeEnergyBurned

        if steps >= 10000 || calories >= 400 {
            return ("とても活発", .green)
        } else if steps >= 7000 || calories >= 300 {
            return ("活発", .orange)
        } else if steps >= 5000 || calories >= 200 {
            return ("普通", .yellow)
        } else {
            return ("運動不足", .red)
        }
    }
}

