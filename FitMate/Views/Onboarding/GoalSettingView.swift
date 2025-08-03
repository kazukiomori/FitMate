//
//  GoalSettingView.swift
//  FitMate
//

import SwiftUI

struct GoalSettingView: View {
    @EnvironmentObject var user: User
    @State private var showingDatePicker = false
    @State private var animateCard = false
    
    // 日本語の日付フォーマッター
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return formatter
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                // タイトル
                VStack(spacing: 12) {
                    Text("目標を設定しましょう")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("健康的で実現可能な目標を一緒に作りましょう")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                LazyVStack(spacing: 20) {
                    // 目標体重設定
                    ModernGoalCard(
                        icon: "target",
                        title: "目標体重",
                        value: String(format: "%.1fkg", user.targetWeight),
                        subtitle: "現在より \(String(format: "%.1f", user.currentWeight - user.targetWeight))kg の減量"
                    ) {
                        VStack(spacing: 15) {
                            HStack {
                                Text("40kg")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                Text("120kg")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Slider(value: $user.targetWeight, in: 40...120, step: 0.1)
                                .accentColor(.white)
                        }
                    }
                    
                    // 目標期限設定
                    ModernGoalCard(
                        icon: "calendar.badge.clock",
                        title: "目標達成期限",
                        value: dateFormatter.string(from: user.targetDate),
                        subtitle: "目標まで \(daysBetween(start: Date(), end: user.targetDate))日間"
                    ) {
                        VStack(spacing: 15) {
                            HStack(spacing: 10) {
                                QuickDateButton(title: "1ヶ月", months: 1, user: user)
                                QuickDateButton(title: "3ヶ月", months: 3, user: user)
                                QuickDateButton(title: "6ヶ月", months: 6, user: user)
                            }
                            
                            Button("詳細な日付を選択") {
                                showingDatePicker = true
                            }
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    
                    // 活動レベル設定
                    ModernGoalCard(
                        icon: "figure.run",
                        title: "活動レベル",
                        value: user.activityLevel.rawValue,
                        subtitle: "日常的な運動量"
                    ) {
                        VStack(spacing: 12) {
                            ForEach(ActivityLevel.allCases, id: \.self) { level in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        user.activityLevel = level
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: user.activityLevel == level ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(user.activityLevel == level ? .white : .white.opacity(0.4))
                                            .font(.title3)
                                        
                                        Text(level.rawValue)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                    
                    // 推奨設定カード
                    GoalSettingRecommendationCard(user: user)
                }
                .opacity(animateCard ? 1 : 0)
                .offset(y: animateCard ? 0 : 50)
                .animation(.easeOut(duration: 0.8).delay(0.2), value: animateCard)
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showingDatePicker) {
            ModernCalendarPickerView(selectedDate: $user.targetDate, isPresented: $showingDatePicker)
        }
        .onAppear {
            animateCard = true
        }
    }
    
    private func daysBetween(start: Date, end: Date) -> Int {
        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
        return max(days, 0)
    }
}

struct ModernGoalCard<Content: View>: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let content: Content
    
    @State private var isExpanded = false
    
    init(icon: String, title: String, value: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 45, height: 45)
                        
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(value)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                }
                .padding(20)
            }
            
            // コンテンツ
            if isExpanded {
                VStack {
                    content
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
    }
}

struct GoalSettingRecommendationCard: View {
    @ObservedObject var user: User

    var body: some View {
        VStack(spacing: 20) {
            headerView()
            contentView()
        }
        .padding(20)
        .background(backgroundStyle())
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    // MARK: - Header

    private func headerView() -> some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.yellow)
            Text("AI推奨設定")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Spacer()
        }
    }

    // MARK: - Main Content

    private func contentView() -> some View {
        VStack(spacing: 15) {
            calorieRow()
            weeklyGoalRow()

            if !user.isGoalRealistic() {
                unrealisticGoalWarning()
            } else {
                realisticGoalConfirmation()
            }
        }
    }

    private func calorieRow() -> some View {
        HStack {
            Text("1日の目標カロリー")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text("\(user.calculateDailyCalories())kcal")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }

    private func weeklyGoalRow() -> some View {
        HStack {
            Text("週の減量目標")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text("\(String(format: "%.1f", user.calculateWeeklyWeightLoss()))kg")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(user.isGoalRealistic() ? .green : .yellow)
        }
    }

    // MARK: - Conditional Views

    private func unrealisticGoalWarning() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                Text("健康的なペースについて")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }

            Text("週1kg以上の減量は健康に良くありません。より長期的な目標期間をお勧めします。")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))

            Button("推奨期間に変更") {
                let recommendedDays = Int((user.currentWeight - user.targetWeight) * 7)
                user.targetDate = Calendar.current.date(byAdding: .day, value: max(recommendedDays, 28), to: Date()) ?? user.targetDate
            }
            .font(.caption)
            .foregroundColor(.yellow)
            .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func realisticGoalConfirmation() -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("健康的なペースです！")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.green)
            Spacer()
        }
        .padding()
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Background

    private func backgroundStyle() -> some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

struct QuickDateButton: View {
    let title: String
    let months: Int
    let user: User
    
    var body: some View {
        Button(title) {
            withAnimation(.easeInOut(duration: 0.3)) {
                user.targetDate = Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? user.targetDate
            }
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ModernCalendarPickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    @State private var displayedDate = Date()
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }
    
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    
    private var daysFromToday: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: selectedDate)).day ?? 0
    }
    
    var body: some View {
        ZStack {
            // グラデーション背景
            LinearGradient(
                colors: [Color.blue, Color.purple, Color.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // ヘッダー
                HStack {
                    Button("キャンセル") {
                        isPresented = false
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("目標達成日を選択")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("完了") {
                        isPresented = false
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // 選択日情報
                VStack(spacing: 12) {
                    Text(selectedDate, formatter: DateFormatter.japaneseDate)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    if daysFromToday > 0 {
                        Text("今日から\(daysFromToday)日後")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    } else if daysFromToday == 0 {
                        Text("今日")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                
                // 月切り替え
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text(monthFormatter.string(from: displayedDate))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 30)
                
                // カレンダー
                VStack(spacing: 15) {
                    // 曜日ヘッダー
                    HStack {
                        ForEach(weekdays, id: \.self) { weekday in
                            Text(weekday)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 日付グリッド
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                        ForEach(generateCalendarDays(), id: \.self) { date in
                            ModernCalendarDayView(
                                date: date,
                                selectedDate: $selectedDate,
                                displayedMonth: displayedDate
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
        }
        .onAppear {
            displayedDate = selectedDate
        }
    }
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            displayedDate = Calendar.current.date(byAdding: .month, value: -1, to: displayedDate) ?? displayedDate
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            displayedDate = Calendar.current.date(byAdding: .month, value: 1, to: displayedDate) ?? displayedDate
        }
    }
    
    private func generateCalendarDays() -> [Date] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: displayedDate)?.start ?? displayedDate
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
        
        var days: [Date] = []
        var currentDate = startOfWeek
        
        for _ in 0..<42 {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
}

struct ModernCalendarDayView: View {
    let date: Date
    @Binding var selectedDate: Date
    let displayedMonth: Date
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
    
    private var isToday: Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    private var isSelected: Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    private var isInCurrentMonth: Bool {
        Calendar.current.isDate(date, equalTo: displayedMonth, toGranularity: .month)
    }
    
    private var isPastDate: Bool {
        date < Calendar.current.startOfDay(for: Date())
    }
    
    var body: some View {
        Button(action: {
            if !isPastDate {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedDate = date
                }
            }
        }) {
            Text(dayFormatter.string(from: date))
                .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                .foregroundColor(foregroundColor)
                .frame(width: 40, height: 40)
                .background(backgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                )
        }
        .disabled(isPastDate)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var foregroundColor: Color {
        if isPastDate {
            return .white.opacity(0.3)
        } else if isSelected {
            return .white
        } else if isToday {
            return .yellow
        } else if isInCurrentMonth {
            return .white.opacity(0.8)
        } else {
            return .white.opacity(0.4)
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.white.opacity(0.3)
        } else if isToday {
            return Color.yellow.opacity(0.2)
        } else {
            return .clear
        }
    }
}

extension DateFormatter {
    static var japaneseDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}
