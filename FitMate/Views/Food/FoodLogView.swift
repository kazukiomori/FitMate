//
//  FoodLogView.swift
//  FitMate
//

import SwiftUI

struct FoodLogView: View {
    @EnvironmentObject var recordViewModel: RecordViewModel
    @EnvironmentObject var user: User

    @State private var selectedMeal: MealType = .breakfast
    @State private var showingFoodAdd = false
    @State private var showingWeightInput = false
    @State private var showingDatePicker = false
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var pendingDeleteEntry: FoodEntry?
    @State private var showingDeleteAlert = false

    private let calendar = Calendar.current

    private var selectedRecord: DailyRecord? {
        recordViewModel.dailyRecords.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var entriesForSelectedDate: [FoodEntry] {
        selectedRecord?.foodEntries.sorted { $0.time < $1.time } ?? []
    }

    private var selectedMealEntries: [FoodEntry] {
        entriesForSelectedDate.filter { $0.mealType == selectedMeal }
    }

    private var totalCalories: Int {
        entriesForSelectedDate.reduce(0) { $0 + $1.calories }
    }

    private var targetCalories: Int {
        max(user.calculateDailyCalories(maintenanceCalories: user.calculateTDEEMifflinStJeor()), 1200)
    }

    private var calorieDifference: Int {
        totalCalories - targetCalories
    }

    private var calorieProgress: Double {
        guard targetCalories > 0 else { return 0 }
        return min(Double(totalCalories) / Double(targetCalories), 1.0)
    }

    private var currentWeightEntry: WeightEntry? {
        selectedRecord?.weightEntry
    }

    private var previousWeightEntry: WeightEntry? {
        recordViewModel.weightEntries
            .filter { calendar.startOfDay(for: $0.date) < selectedDate }
            .sorted { $0.date < $1.date }
            .last
    }

    private var weightChange: Double? {
        guard let currentWeight = currentWeightEntry?.weight,
              let previousWeight = previousWeightEntry?.weight else {
            return nil
        }
        return currentWeight - previousWeight
    }

    private var weightTrendEntries: [WeightEntry] {
        recordViewModel.weightEntries
            .filter { calendar.startOfDay(for: $0.date) <= selectedDate }
            .sorted { $0.date < $1.date }
            .suffix(7)
            .map { $0 }
    }

    private var mealCalories: [MealType: Int] {
        Dictionary(uniqueKeysWithValues: MealType.allCases.map { meal in
            (meal, entriesForSelectedDate.filter { $0.mealType == meal }.reduce(0) { $0 + $1.calories })
        })
    }

    private var mealTargets: [MealType: Int] {
        let ratios: [MealType: Double] = [
            .breakfast: 0.25,
            .lunch: 0.39,
            .dinner: 0.33,
            .snack: 0.08
        ]

        return Dictionary(uniqueKeysWithValues: MealType.allCases.map { meal in
            let target = Int((Double(targetCalories) * (ratios[meal] ?? 0.25)).rounded())
            return (meal, max(target, 1))
        })
    }

    private var totalProtein: Double {
        entriesForSelectedDate.reduce(0) { $0 + $1.protein }
    }

    private var proteinTarget: Double {
        max((user.targetWeight * 1.8).rounded(), 80)
    }

    private var missionCompletionCount: Int {
        [isCalorieMissionComplete, isProteinMissionComplete, isWeightMissionComplete]
            .filter { $0 }
            .count
    }

    private var isCalorieMissionComplete: Bool {
        totalCalories <= targetCalories
    }

    private var isProteinMissionComplete: Bool {
        totalProtein >= proteinTarget
    }

    private var isWeightMissionComplete: Bool {
        currentWeightEntry != nil
    }

    private var trainerDisplayName: String {
        user.personalTrainer?.resolvedDisplayName ?? "トレーナー"
    }

    private var trainerImage: UIImage? {
       user.personalTrainer?.avatarImage(for: .smile)
            ?? user.personalTrainer?.image
    }

    private var dailyGoalLines: [String] {
        var lines = ["今日は \(targetCalories)kcal 以内を目標に、"]

        if totalCalories > targetCalories {
            lines.append("脂質を控えめにして整えましょう。")
        } else {
            lines.append("バランスよく食べて進めましょう。")
        }

        if currentWeightEntry == nil {
            lines.append("体重も記録してください。")
        } else {
            lines.append("体重の記録もできています。")
        }

        return lines
    }

    private var recentHistoryEntries: [FoodEntry] {
        Array(recordViewModel.foodEntries.sorted { $0.time > $1.time }.prefix(10))
    }

    private var navigationTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日（E）"
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.97, green: 0.97, blue: 0.99)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        headerSection
                        trainerGoalCard
                        metricsSection
                        mealBreakdownSection
                        missionSection
                        actionSection
                        selectedMealEntriesSection
                        recentHistorySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 120)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingFoodAdd) {
                FoodAddView(recordViewModel: recordViewModel, selectedMeal: selectedMeal)
            }
            .sheet(isPresented: $showingWeightInput) {
                WeightInputView(recordViewModel: recordViewModel)
                    .environmentObject(user)
            }
            .sheet(isPresented: $showingDatePicker) {
                FoodLogDatePickerSheet(selectedDate: $selectedDate)
            }
            .alert("削除しますか？", isPresented: $showingDeleteAlert) {
                Button("削除", role: .destructive) {
                    if let entry = pendingDeleteEntry {
                        recordViewModel.deleteFoodEntry(id: entry.id)
                    }
                    pendingDeleteEntry = nil
                }
                Button("キャンセル", role: .cancel) {
                    pendingDeleteEntry = nil
                }
            } message: {
                if let entry = pendingDeleteEntry {
                    Text("\(entry.name) を削除します")
                } else {
                    Text("この記録を削除します")
                }
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Button {
                moveDate(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 42, height: 42)
                    .background(Color.white, in: Circle())
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(navigationTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            Button {
                showingDatePicker = true
            } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 42, height: 42)
                    .background(Color.white, in: Circle())
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 2)
    }

    private var trainerGoalCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Group {
                    if let trainerImage {
                        Image(uiImage: trainerImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.12))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.secondary)
                            )
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                
                
                Text(trainerDisplayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
            }
            .frame(width: 112, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 10) {
                Label("今日の目標", systemImage: "flag")
                    .font(.headline.weight(.bold))
                    .foregroundColor(Color(red: 1.0, green: 0.32, blue: 0.42))
                
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(dailyGoalLines, id: \.self) { line in
                        Text(line)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 17)
        .background(FoodDashboardCardBackground())
    }

    private var metricsSection: some View {
        VStack(spacing: 12) {
            calorieCard
            weightCard
        }
        .frame(maxWidth: .infinity)
    }

    private var calorieCard: some View {
        FoodMetricCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("今日の摂取カロリー")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.secondary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(totalCalories)")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.21, blue: 0.29))

                    Text("/ \(targetCalories) kcal")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    Text(calorieDifferenceBadgeText)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(calorieDifference <= 0 ? Color(red: 0.14, green: 0.62, blue: 0.34) : Color(red: 1.0, green: 0.21, blue: 0.29))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background((calorieDifference <= 0 ? Color.green : Color.red).opacity(0.10), in: Capsule())
                }

                VStack(spacing: 6) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.red.opacity(0.12))

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.26, blue: 0.36),
                                            Color(red: 1.0, green: 0.18, blue: 0.28)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(geometry.size.width * calorieProgress, 6))
                        }
                    }
                    .frame(height: 14)

                    HStack {
                        Text("0")
                        Spacer()
                        Text("\(targetCalories / 2)")
                        Spacer()
                        Text("\(targetCalories)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                HStack(spacing: 10) {
                    Image(systemName: calorieDifference <= 0 ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                        .foregroundColor(calorieDifference <= 0 ? .green : .red)

                    Text(calorieMessage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(calorieDifference <= 0 ? .green : .red)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 10)
                .background((calorieDifference <= 0 ? Color.green : Color.red).opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var weightCard: some View {
        FoodMetricCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("今日の体重")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.secondary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(currentWeightText)
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.10, green: 0.49, blue: 0.97))

                    Text("kg")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    Text(weightDifferenceBadgeText)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.49, blue: 0.97))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(Color.blue.opacity(0.10), in: Capsule())
                }

                Text("目標体重 \(String(format: "%.1f", user.targetWeight)) kg")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)

                WeightSparkline(entries: weightTrendEntries)
                    .frame(height: 52)
            }
        }
    }

    private var mealBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("食事の内訳")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MealType.allCases, id: \.self) { meal in
                        MealSummaryCard(
                            meal: meal,
                            calories: mealCalories[meal] ?? 0,
                            targetCalories: mealTargets[meal] ?? 1,
                            isSelected: selectedMeal == meal
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedMeal = meal
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .background(FoodDashboardCardBackground())
    }

    private var missionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("今日のミッション")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(missionCompletionCount)")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(Color.blue)
                + Text(" / 3 達成")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.secondary)
            }

            MissionRow(
                title: "\(targetCalories)kcal以内",
                isCompleted: isCalorieMissionComplete,
                trailing: calorieDifference <= 0 ? "達成中" : "+\(calorieDifference) kcal"
            )

            Divider()

            MissionRow(
                title: "たんぱく質 \(Int(proteinTarget))g",
                isCompleted: isProteinMissionComplete,
                trailing: "\(Int(totalProtein.rounded())) / \(Int(proteinTarget)) g"
            )

            Divider()

            MissionRow(
                title: "体重を記録",
                isCompleted: isWeightMissionComplete,
                trailing: isWeightMissionComplete ? "記録済み" : "未記録"
            )
        }
        .padding(18)
        .background(FoodDashboardCardBackground())
    }

    private var actionSection: some View {
        HStack(spacing: 14) {
            DashboardActionButton(
                title: "食事を追加",
                subtitle: "食べたものを記録する",
                icon: "fork.knife",
                tint: Color.orange
            ) {
                showingFoodAdd = true
            }

            DashboardActionButton(
                title: "体重を記録",
                subtitle: "体重を入力する",
                icon: "scalemass.fill",
                tint: Color.green
            ) {
                showingWeightInput = true
            }
        }
    }

    private var selectedMealEntriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(selectedMeal.title)の記録")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\((mealCalories[selectedMeal] ?? 0)) kcal")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(selectedMeal.themeColor)
            }

            if selectedMealEntries.isEmpty {
                EmptyStateCard(message: "まだ記録がありません")
            } else {
                VStack(spacing: 12) {
                    ForEach(selectedMealEntries.sorted { $0.time > $1.time }) { entry in
                        SelectedMealEntryRow(entry: entry) {
                            pendingDeleteEntry = entry
                            showingDeleteAlert = true
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(FoodDashboardCardBackground())
    }

    private var recentHistorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("最近の記録")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            if recentHistoryEntries.isEmpty {
                EmptyStateCard(message: "履歴がありません")
            } else {
                VStack(spacing: 12) {
                    ForEach(recentHistoryEntries) { entry in
                        FoodHistoryEntryRow(entry: entry)
                    }
                }
            }
        }
        .padding(20)
        .background(FoodDashboardCardBackground())
    }

    private var calorieDifferenceBadgeText: String {
        if calorieDifference <= 0 {
            return "\(abs(calorieDifference)) kcal 余裕あり"
        }
        return "+\(calorieDifference) kcal オーバー"
    }

    private var calorieMessage: String {
        if calorieDifference <= 0 {
            return "目標範囲内です"
        }
        return "目標を \(calorieDifference)kcal オーバーしています"
    }

    private var currentWeightText: String {
        guard let weight = currentWeightEntry?.weight else { return "--.-" }
        return String(format: "%.1f", weight)
    }

    private var weightDifferenceBadgeText: String {
        guard let weightChange else { return "前日比 -- kg" }
        let symbol = weightChange >= 0 ? "+" : ""
        let arrow = weightChange > 0 ? "↑" : (weightChange < 0 ? "↓" : "→")
        return "前日比  \(symbol)\(String(format: "%.1f", weightChange)) kg  \(arrow)"
    }

    private func moveDate(by days: Int) {
        guard let newDate = calendar.date(byAdding: .day, value: days, to: selectedDate) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDate = calendar.startOfDay(for: newDate)
        }
    }
}

private struct FoodMetricCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 224, alignment: .top)
        .background(FoodDashboardCardBackground())
    }
}

private struct FoodDashboardCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white)
            .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 10)
    }
}

private struct MealSummaryCard: View {
    let meal: MealType
    let calories: Int
    let targetCalories: Int
    let isSelected: Bool
    let action: () -> Void

    private var progress: Double {
        min(Double(calories) / Double(max(targetCalories, 1)), 1.0)
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: meal.iconName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(meal.themeColor)

                    Text(meal.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(calories)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                    Text("kcal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(meal.themeColor.opacity(0.14))

                        Capsule()
                            .fill(meal.themeColor)
                            .frame(width: max(geometry.size.width * progress, 6))
                    }
                }
                .frame(height: 8)

                Text("目標 \(targetCalories) kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(14)
            .frame(width: 124, alignment: .leading)
            .frame(minHeight: 176, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? meal.themeColor.opacity(0.10) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isSelected ? meal.themeColor.opacity(0.65) : Color.black.opacity(0.06), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MissionRow: View {
    let title: String
    let isCompleted: Bool
    let trailing: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(isCompleted ? Color.green : Color.secondary.opacity(0.8))

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            Text(trailing)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(isCompleted ? Color.blue : Color.secondary)
        }
    }
}

private struct DashboardActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(tint)
                        .frame(width: 48, height: 48)
                        .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(tint)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 136, alignment: .topLeading)
            .background(FoodDashboardCardBackground())
        }
        .buttonStyle(.plain)
    }
}

private struct SelectedMealEntryRow: View {
    let entry: FoodEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    Text("\(entry.calories) kcal")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)

                    Text(foodTimeFormatter.string(from: entry.time))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color(red: 0.98, green: 0.98, blue: 0.99), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct EmptyStateCard: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color(red: 0.98, green: 0.98, blue: 0.99), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct WeightSparkline: View {
    let entries: [WeightEntry]

    var body: some View {
        GeometryReader { geometry in
            let points = chartPoints(in: geometry.size)

            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.08), Color.blue.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                if points.count >= 2 {
                    WeightAreaShape(points: points)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.20), Color.blue.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    WeightLineShape(points: points)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                        Circle()
                            .fill(index == points.count - 1 ? Color.white : Color.blue)
                            .frame(width: index == points.count - 1 ? 13 : 8, height: index == points.count - 1 ? 13 : 8)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: index == points.count - 1 ? 3 : 0)
                            )
                            .position(point)
                    }
                } else {
                    Text("体重データが少ないです")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    private func chartPoints(in size: CGSize) -> [CGPoint] {
        guard !entries.isEmpty else { return [] }

        let weights = entries.map(\.weight)
        let minWeight = weights.min() ?? 0
        let maxWeight = weights.max() ?? 0
        let range = max(maxWeight - minWeight, 0.4)
        let usableHeight = max(size.height - 12, 1)
        let stepX = entries.count > 1 ? size.width / CGFloat(entries.count - 1) : 0

        return entries.enumerated().map { index, entry in
            let normalized = (entry.weight - minWeight) / range
            let x = CGFloat(index) * stepX
            let y = usableHeight - (CGFloat(normalized) * usableHeight) + 4
            return CGPoint(x: x, y: y)
        }
    }
}

private struct WeightLineShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        return path
    }
}

private struct WeightAreaShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first, let last = points.last else { return path }

        path.move(to: CGPoint(x: first.x, y: rect.maxY))
        path.addLine(to: first)

        for point in points.dropFirst() {
            path.addLine(to: point)
        }

        path.addLine(to: CGPoint(x: last.x, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct FoodLogDatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "日付を選択",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .environment(\.locale, Locale(identifier: "ja_JP"))
                .padding()

                Spacer()
            }
            .navigationTitle("日付を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FoodHistoryEntryRow: View {
    let entry: FoodEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(entry.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)

                    Text(entry.mealType.title)
                        .font(.caption.weight(.bold))
                        .foregroundColor(entry.mealType.themeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(entry.mealType.themeColor.opacity(0.12), in: Capsule())
                }

                Text("\(entry.calories)kcal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 12)

            Text(historyDateTimeFormatter.string(from: entry.time))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color(red: 0.98, green: 0.98, blue: 0.99), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private var historyDateTimeFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ja_JP")
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}

private var foodTimeFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ja_JP")
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return formatter
}

private extension MealType {
    var iconName: String {
        switch self {
        case .breakfast:
            return "sun.max.fill"
        case .lunch:
            return "sun.max.circle.fill"
        case .dinner:
            return "moon.stars.fill"
        case .snack:
            return "cup.and.saucer.fill"
        }
    }

    var themeColor: Color {
        switch self {
        case .breakfast:
            return Color(red: 1.00, green: 0.74, blue: 0.10)
        case .lunch:
            return Color(red: 1.00, green: 0.43, blue: 0.08)
        case .dinner:
            return Color(red: 0.53, green: 0.29, blue: 0.86)
        case .snack:
            return Color(red: 0.41, green: 0.72, blue: 0.14)
        }
    }
}
