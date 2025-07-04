//
//  GoalSettingView.swift
//  FitMate
//

import SwiftUI

struct GoalSettingView: View {
    @EnvironmentObject var user: User
    @State private var showingDatePicker = false
    
    // 日本語の日付フォーマッター
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("目標を設定")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 20) {
                    // 目標体重設定
                    VStack(alignment: .leading, spacing: 10) {
                        Text("目標体重: \(String(format: "%.1f", user.targetWeight))kg")
                            .font(.headline)
                        Slider(value: $user.targetWeight, in: 40...120, step: 0.1)
                        
                        Text("現在より \(String(format: "%.1f", user.currentWeight - user.targetWeight))kg の減量")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // 目標期限設定
                    VStack(alignment: .leading, spacing: 10) {
                        Text("目標達成期限")
                            .font(.headline)
                        
                        Button(action: { showingDatePicker = true }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                Text(dateFormatter.string(from: user.targetDate))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        // 期間表示
                        let daysDifference = Calendar.current.dateComponents([.day], from: Date(), to: user.targetDate).day ?? 0
                        Text("目標まで \(daysDifference)日間")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // 活動レベル
                    VStack(alignment: .leading, spacing: 10) {
                        Text("活動レベル")
                            .font(.headline)
                        Picker("活動レベル", selection: $user.activityLevel) {
                            ForEach(ActivityLevel.allCases, id: \.self) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // 推奨設定とアドバイス
                    VStack(alignment: .leading, spacing: 15) {
                        Text("推奨設定")
                            .font(.headline)
                        
                        // 基本情報
                        VStack(spacing: 12) {
                            HStack {
                                Text("1日の目標カロリー:")
                                Spacer()
                                Text("\(user.calculateDailyCalories())kcal")
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("週の減量目標:")
                                Spacer()
                                Text("\(String(format: "%.1f", user.calculateWeeklyWeightLoss()))kg")
                                    .fontWeight(.semibold)
                                    .foregroundColor(user.isGoalRealistic() ? .green : .orange)
                            }
                        }
                        
                        // アドバイス表示
                        if !user.isGoalRealistic() {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("健康的なペースについて")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                
                                Text("週1kg以上の減量は健康に良くありません。より長期的な目標期間を設定することをお勧めします。")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Button("推奨期間に変更") {
                                    let recommendedDays = Int((user.currentWeight - user.targetWeight) * 7)
                                    user.targetDate = Calendar.current.date(byAdding: .day, value: max(recommendedDays, 28), to: Date()) ?? user.targetDate
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(10)
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("健康的なペースです！")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        // 簡単な期間設定ボタン
                        VStack(alignment: .leading, spacing: 8) {
                            Text("よく選ばれる期間")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack(spacing: 10) {
                                QuickDateButton(title: "1ヶ月", months: 1, user: user)
                                QuickDateButton(title: "3ヶ月", months: 3, user: user)
                                QuickDateButton(title: "6ヶ月", months: 6, user: user)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(15)
                }
                .padding()
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            CalendarPickerView(selectedDate: $user.targetDate, isPresented: $showingDatePicker)
        }
    }
}

struct CalendarPickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    @State private var displayedDate = Date()
    
    // 日本語の月フォーマッター
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }
    
    // 曜日ヘッダー
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    
    // 今日からの日数計算
    private var daysFromToday: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: selectedDate)).day ?? 0
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 選択された日付の情報表示
                VStack(spacing: 8) {
                    Text("選択された日付")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text(selectedDate, formatter: DateFormatter.japaneseDate)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if daysFromToday > 0 {
                        Text("今日から\(daysFromToday)日後")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    } else if daysFromToday == 0 {
                        Text("今日")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // クイック選択ボタン
                VStack(alignment: .leading, spacing: 8) {
                    Text("クイック選択")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack(spacing: 10) {
                        QuickSelectButton(title: "1ヶ月後", months: 1, selectedDate: $selectedDate, displayedDate: $displayedDate)
                        QuickSelectButton(title: "3ヶ月後", months: 3, selectedDate: $selectedDate, displayedDate: $displayedDate)
                        QuickSelectButton(title: "6ヶ月後", months: 6, selectedDate: $selectedDate, displayedDate: $displayedDate)
                    }
                    .padding(.horizontal)
                }
                
                // 月切り替えヘッダー
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    Text(monthFormatter.string(from: displayedDate))
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                
                // 曜日ヘッダー
                HStack {
                    ForEach(weekdays, id: \.self) { weekday in
                        Text(weekday)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                // カレンダーグリッド
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(generateCalendarDays(), id: \.self) { date in
                        CalendarDayView(
                            date: date,
                            selectedDate: $selectedDate,
                            displayedMonth: displayedDate,
                            isPresented: $isPresented
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 今日ボタン
                Button("今日に戻る") {
                    displayedDate = Date()
                    selectedDate = Date()
                }
                .foregroundColor(.blue)
                .padding()
            }
            .navigationTitle("目標達成日を選択")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("キャンセル") { isPresented = false },
                trailing: Button("完了") { isPresented = false }
            )
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
        let endOfMonth = calendar.dateInterval(of: .month, for: displayedDate)?.end ?? displayedDate
        
        // 月の最初の週の日曜日を取得
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
        
        var days: [Date] = []
        var currentDate = startOfWeek
        
        // 6週間分のカレンダーを生成
        for _ in 0..<42 {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
}

struct QuickSelectButton: View {
    let title: String
    let months: Int
    @Binding var selectedDate: Date
    @Binding var displayedDate: Date
    
    var body: some View {
        Button(title) {
            let newDate = Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? selectedDate
            selectedDate = newDate
            displayedDate = newDate
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(15)
    }
}

extension DateFormatter {
    static let japaneseDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()
}

struct CalendarDayView: View {
    let date: Date
    @Binding var selectedDate: Date
    let displayedMonth: Date
    @Binding var isPresented: Bool
    
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
                selectedDate = date
            }
        }) {
            Text(dayFormatter.string(from: date))
                .font(.system(size: 16))
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(foregroundColor)
                .frame(width: 40, height: 40)
                .background(backgroundColor)
                .cornerRadius(20)
        }
        .disabled(isPastDate)
    }
    
    private var foregroundColor: Color {
        if isPastDate {
            return .gray.opacity(0.3)
        } else if isSelected {
            return .white
        } else if isToday {
            return .blue
        } else if isInCurrentMonth {
            return .primary
        } else {
            return .gray.opacity(0.5)
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .blue.opacity(0.1)
        } else {
            return .clear
        }
    }
}

struct QuickDateButton: View {
    let title: String
    let months: Int
    let user: User
    
    var body: some View {
        Button(title) {
            user.targetDate = Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? user.targetDate
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(15)
    }
}
