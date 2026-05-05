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
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.98, green: 0.98, blue: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if let trainer = user.personalTrainer {
                    TrainerConversationSection(
                        trainer: trainer,
                        isFirstOpenToday: isFirstHomeOpenToday,
                        userMessage: $userMessage,
                        isMessageFieldFocused: $isMessageFieldFocused,
                        recordViewModel: recordViewModel
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                } else {
                    ContentUnavailableView(
                        "トレーナーが未設定です",
                        systemImage: "message.badge",
                        description: Text("オンボーディングでトレーナーを選ぶと、ここがチャット画面になります")
                    )
                    .padding(.horizontal, 24)
                }
            }
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
    @State private var chatValidationMessage: String?
    @State private var messages: [HomeChatMessage] = []
    @State private var selectedChatInputMode: ChatInputMode = .none
    @StateObject private var coachMessageViewModel = CoachMessageViewModel()

    private var trainerMessage: String {
        trainer.getHomeMessage(isFirstOpenToday: isFirstOpenToday)
    }

    private var trainerDisplayName: String {
        trainer.name.isEmpty ? "トレーナー" : trainer.name
    }

    private var trainerSmileImage: UIImage? {
        trainer.avatarImage(for: .smile) ?? trainer.image
    }

    private func appendTrainerMessage(
        _ message: String,
        expression: TrainerAvatarExpression = .smile,
        completion: (() -> Void)? = nil
    ) {
        messages.append(
            HomeChatMessage(
                sender: .trainer,
                text: message,
                expression: expression
            )
        )
        completion?()
    }

    private func appendUserMessage(_ message: String) {
        messages.append(
            HomeChatMessage(
                sender: .user,
                text: message,
                expression: nil
            )
        )
    }

    private func ensureInitialGreetingIfNeeded() {
        guard messages.isEmpty else { return }
        appendTrainerMessage(trainerMessage)
    }

    private func handleFoodReportTap() {
        if selectedChatInputMode == .food, user.isPremiumUser {
            isMessageFieldFocused = true
            return
        }

        isMessageFieldFocused = false
        selectedChatInputMode = .food

        if user.isPremiumUser {
            appendTrainerMessage(ChatInputMode.food.promptMessage) {
                userMessage = ""
                isMessageFieldFocused = true
            }
            return
        }

        appendTrainerMessage("何を食べたか教えてね！") {
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
            appendTrainerMessage(ChatInputMode.weight.promptMessage) {
                userMessage = ""
                isMessageFieldFocused = true
            }
            return
        }

        appendTrainerMessage("今日の体重を教えてね！") {
            showingWeightInput = true
        }
    }

    private func handleDailyChatTap() {
        if selectedChatInputMode == .dailyChat {
            isMessageFieldFocused = true
            return
        }

        selectedChatInputMode = .dailyChat
        appendTrainerMessage(ChatInputMode.dailyChat.promptMessage) {
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

    private var selectedModeTitle: String? {
        switch selectedChatInputMode {
        case .none:
            return nil
        case .weight:
            return "体重報告モード"
        case .food:
            return "食事報告モード"
        case .dailyChat:
            return "日常会話モード"
        }
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
        appendUserMessage(sanitized)
        userMessage = sanitized
        selectedChatInputMode = .none

        recordViewModel.addWeightEntry(weight: weightValue)
        user.registerWeightRecord()
        appendTrainerMessage("体重\(String(format: "%.1f", weightValue))kgを記録したよ！", expression: .smile)
        userMessage = ""
    }

    private func handleValidatedChatSend(_ message: String) {
        isMessageFieldFocused = false
        chatValidationMessage = nil
        appendUserMessage(message)
        userMessage = ""
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
                    appendTrainerMessage(response.comment, expression: .smile)

                case .chat:
                    appendTrainerMessage(response.comment, expression: .smile)
                }
            } else if let errorMessage = coachMessageViewModel.errorMessage {
                chatValidationMessage = errorMessage
                appendTrainerMessage(errorMessage, expression: .sad)
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
        VStack(spacing: 0) {
            chatHeader

            Divider()
                .overlay(Color.black.opacity(0.05))

            VStack(spacing: 18) {
                chatTimeline
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                quickActionButtons

                composerSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
        .sheet(isPresented: $showingWeightInput) {
            WeightInputView(recordViewModel: recordViewModel)
        }
        .sheet(isPresented: $showingFoodAdd) {
            FoodAddView(recordViewModel: recordViewModel, selectedMeal: .breakfast)
        }
        .onAppear {
            ensureInitialGreetingIfNeeded()
        }
        .onChange(of: isFirstOpenToday) { _ in
            if messages.isEmpty {
                ensureInitialGreetingIfNeeded()
            }
        }
        .onChange(of: userMessage) { _ in
            if chatValidationMessage != nil {
                chatValidationMessage = TrainerChatInputValidator.validate(userMessage).errorMessage
            }
        }
    }

    private var chatHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(trainerDisplayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(isFirstOpenToday ? "今日のあいさつ" : "トレーナーチャット")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 12)

            TrainerIntimacyMeter(
                level: intimacyLevel,
                title: intimacyTitle,
                progress: intimacyProgress,
                gainAmount: intimacyGainAmount,
                gainTrigger: intimacyGainTrigger
            )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.96),
                    Color(red: 0.96, green: 0.97, blue: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var chatTimeline: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Spacer(minLength: 0)

                        Text("Today")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.05), in: Capsule())

                        Spacer(minLength: 0)
                    }

                    ForEach(messages) { message in
                        HomeChatBubbleRow(
                            message: message,
                            trainerName: trainerDisplayName,
                            trainerImage: trainerSmileImage
                        )
                        .id(message.id)
                    }

                    if coachMessageViewModel.isLoading {
                        HomeTypingIndicatorRow(
                            trainerName: trainerDisplayName,
                            trainerImage: trainerSmileImage
                        )
                        .id("typing-indicator")
                    }
                }
                .padding(.bottom, 6)
            }
            .onAppear {
                ensureInitialGreetingIfNeeded()
            }
            .onChange(of: messages.count) { _ in
                guard let lastID = messages.last?.id else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
            .onChange(of: coachMessageViewModel.isLoading) { isLoading in
                guard isLoading else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("typing-indicator", anchor: .bottom)
                }
            }
        }
    }

    private var quickActionButtons: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("クイックアクション")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
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
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var composerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let selectedModeTitle {
                Text(selectedModeTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(red: 0.28, green: 0.47, blue: 0.88))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.90, green: 0.94, blue: 1.0), in: Capsule())
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField(inputPlaceholder, text: $userMessage, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .focused($isMessageFieldFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.97, green: 0.97, blue: 0.98), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                Button(action: {
                    handleChatSendTap()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 44, height: 44)

                        if coachMessageViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.75)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
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
    }
}

private struct HomeChatMessage: Identifiable {
    enum Sender {
        case trainer
        case user
    }

    let id = UUID()
    let sender: Sender
    let text: String
    let expression: TrainerAvatarExpression?
}

private struct HomeChatBubbleRow: View {
    let message: HomeChatMessage
    let trainerName: String
    let trainerImage: UIImage?

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.sender == .trainer {
                trainerAvatar

                VStack(alignment: .leading, spacing: 4) {
                    Text(trainerName)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    trainerBubble
                }

                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)

                userBubble
            }
        }
    }

    private var trainerBubble: some View {
        Text(message.text)
            .font(.subheadline)
            .foregroundColor(.primary)
            .lineSpacing(4)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
    }

    private var userBubble: some View {
        Text(message.text)
            .font(.subheadline)
            .foregroundColor(.primary)
            .lineSpacing(4)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.78, green: 0.96, blue: 0.45))
            )
    }

    @ViewBuilder
    private var trainerAvatar: some View {
        if let trainerImage {
            Image(uiImage: trainerImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 34, height: 34)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                )
        }
    }
}

private struct HomeTypingIndicatorRow: View {
    let trainerName: String
    let trainerImage: UIImage?

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if let trainerImage {
                Image(uiImage: trainerImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 34, height: 34)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(trainerName)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(Color.gray.opacity(0.55))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
            }

            Spacer(minLength: 40)
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
                        .fill(Color.pink.opacity(0.2))
                        .frame(width: 38, height: 38)
                        .blur(radius: isPulsing ? 7 : 2)

                    Heart()
                        .stroke(Color.pink, lineWidth: 2)
                        .frame(width: 32, height: 32)
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
                        .frame(width: 22, height: 22)
                        .scaleEffect(shouldBounceHeart ? 1.12 : 1.0)

                    if showGainBadge, gainAmount > 0 {
                        Text("+\(gainAmount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color(red: 1.0, green: 0.34, blue: 0.55))
                            )
                            .shadow(color: Color.black.opacity(0.16), radius: 6, x: 0, y: 3)
                            .offset(x: 16, y: gainBadgeOffset)
                            .opacity(gainBadgeOpacity)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("親密度 Lv.\(displayedLevel)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(title)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.black.opacity(0.08))
                    .frame(width: 112, height: 6)

                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.pink, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 112 * animatedProgress, height: 6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.03), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(background, in: Capsule())
            .saturation(isSelected ? 1.15 : 0.88)
            .brightness(isSelected ? -0.03 : 0)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isSelected ? 0.34 : 0.18), lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.12 : 0.08), radius: isSelected ? 10 : 6, x: 0, y: isSelected ? 4 : 2)
        }
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        .buttonStyle(.plain)
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

