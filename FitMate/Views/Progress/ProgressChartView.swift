//
//  ProgressChartView.swift
//  FitMate
//

import SwiftUI
import UIKit
import Charts

struct ProgressChartView: View {
    @EnvironmentObject var recordViewModel: RecordViewModel
    @EnvironmentObject var user: User
    @State private var showingWeightInput = false
    @State private var selectedTimeRange = TimeRange.month

    enum TimeRange: String, CaseIterable {
        case week = "1週間"
        case month = "1ヶ月"
        case threeMonths = "3ヶ月"

        var days: Int {
            switch self {
            case .week:
                return 7
            case .month:
                return 30
            case .threeMonths:
                return 90
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.97, blue: 1.0),
                        Color(red: 0.98, green: 0.98, blue: 0.99)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ProgressHeader(showingWeightInput: $showingWeightInput)

                        ProgressSummaryCard(
                            recordViewModel: recordViewModel,
                            selectedTimeRange: selectedTimeRange
                        )

                        ProgressRangePicker(selectedTimeRange: $selectedTimeRange)

                        WeightTrendDashboardCard(
                            weightEntries: recordViewModel.weightEntries,
                            timeRange: selectedTimeRange,
                            targetWeight: user.targetWeight
                        )

                        MonthlyNutritionProgressCard(
                            dailyRecords: recordViewModel.dailyRecords,
                            targetCalories: max(user.calculateDailyCalories(maintenanceCalories: user.calculateTDEEMifflinStJeor()), 1200)
                        )

                        CoachReflectionCard(
                            trainer: user.personalTrainer,
                            reflection: ProgressInsightBuilder.reflection(
                                trainer: user.personalTrainer,
                                user: user,
                                records: recordViewModel.dailyRecords,
                                weightEntries: recordViewModel.weightEntries
                            )
                        )

                        NextActionCard(
                            steps: ProgressInsightBuilder.nextSteps(
                                user: user,
                                records: recordViewModel.dailyRecords,
                                weightEntries: recordViewModel.weightEntries
                            )
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 120)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingWeightInput) {
                WeightInputView(recordViewModel: recordViewModel)
                    .environmentObject(user)
            }
        }
    }
}

private struct ProgressHeader: View {
    @Binding var showingWeightInput: Bool

    var body: some View {
        HStack(alignment: .top) {
            Text("進捗")
                .font(.system(size: 30, weight: .heavy))
                .foregroundColor(.primary)

            Spacer()

            Button {
                showingWeightInput = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 66, height: 66)
                    .background(Color.white.opacity(0.96), in: Circle())
                    .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 10)
            }
            .buttonStyle(.plain)
        }
    }
}

struct ProgressRangePicker: View {
    @Binding var selectedTimeRange: ProgressChartView.TimeRange

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProgressChartView.TimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        selectedTimeRange = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(selectedTimeRange == range ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(selectedTimeRange == range ? Color(red: 0.12, green: 0.50, blue: 0.96) : .clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(Color.white, in: Capsule())
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
    }
}

struct ProgressSummaryCard: View {
    @ObservedObject var recordViewModel: RecordViewModel
    let selectedTimeRange: ProgressChartView.TimeRange
    @EnvironmentObject var user: User

    private var calendar: Calendar {
        var value = Calendar.current
        value.locale = Locale(identifier: "ja_JP")
        return value
    }

    private var currentMonthInterval: DateInterval? {
        calendar.dateInterval(of: .month, for: Date())
    }

    private var displayedCurrentWeight: Double {
        recordViewModel.getLatestWeight() ?? user.currentWeight
    }

    private var previousMonthLatestWeight: Double? {
        guard let monthInterval = currentMonthInterval,
              let previousMonthDate = calendar.date(byAdding: .day, value: -1, to: monthInterval.start) else {
            return nil
        }

        guard let previousMonthRange = calendar.dateInterval(of: .month, for: previousMonthDate) else {
            return nil
        }

        return recordViewModel.weightEntries
            .filter { previousMonthRange.contains($0.date) }
            .sorted { $0.date < $1.date }
            .last?
            .weight
    }

    private var monthlyRecords: [DailyRecord] {
        guard let monthInterval = currentMonthInterval else { return [] }
        return recordViewModel.dailyRecords.filter { monthInterval.contains($0.date) }
    }

    private var recordDays: Int {
        monthlyRecords.count
    }

    private var targetAchievedDays: Int {
        let targetCalories = max(user.calculateDailyCalories(maintenanceCalories: user.calculateTDEEMifflinStJeor()), 1200)
        return monthlyRecords.filter { !$0.foodEntries.isEmpty && $0.totalCalories <= targetCalories }.count
    }

    private var achievementRate: Int {
        guard recordDays > 0 else { return 0 }
        return Int((Double(targetAchievedDays) / Double(recordDays) * 100).rounded())
    }

    private var currentMonthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: Date()) + "の結果"
    }

    private var weightDeltaFromPreviousMonth: Double? {
        guard let previousMonthLatestWeight else { return nil }
        return displayedCurrentWeight - previousMonthLatestWeight
    }

    private var remainingToTarget: Double {
        user.targetWeight - displayedCurrentWeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(currentMonthTitle)
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.primary)

            HStack(spacing: 0) {
                ProgressMetricColumn(
                    title: "現在の体重",
                    value: String(format: "%.1fkg", displayedCurrentWeight),
                    detail: weightDeltaFromPreviousMonth.map { "前月比 \(String(format: "%+.1f", $0))kg" } ?? "前月比 --.-kg",
                    valueColor: Color(red: 0.10, green: 0.49, blue: 0.97)
                )

                ProgressMetricColumn(
                    title: "目標まで",
                    value: String(format: "%+.1fkg", remainingToTarget),
                    detail: "目標 \(String(format: "%.1f", user.targetWeight))kg",
                    valueColor: remainingToTarget <= 0 ? Color.green : Color(red: 0.17, green: 0.76, blue: 0.35)
                )

                ProgressMetricColumn(
                    title: "記録日数",
                    value: "\(recordDays)日",
                    detail: "今月の記録",
                    valueColor: Color.orange
                )

                ProgressMetricColumn(
                    title: "目標達成率",
                    value: "\(achievementRate)%",
                    detail: "今月の達成度",
                    valueColor: Color.orange
                )
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(ProgressCardBackground())
    }
}

private struct ProgressMetricColumn: View {
    let title: String
    let value: String
    let detail: String
    let valueColor: Color

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(valueColor)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(detail)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 96)
        .contentShape(Rectangle())
    }
}

private struct WeightTrendDashboardCard: View {
    let weightEntries: [WeightEntry]
    let timeRange: ProgressChartView.TimeRange
    let targetWeight: Double

    private struct ChartPoint: Identifiable {
        let date: Date
        let weight: Double

        var id: Date { date }
    }

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.locale = Locale(identifier: "ja_JP")
        return cal
    }

    private var referenceDate: Date {
        calendar.startOfDay(for: Date())
    }

    private var chartDateRange: ClosedRange<Date> {
        let end = referenceDate
        let start: Date

        switch timeRange {
        case .week:
            start = calendar.date(byAdding: .day, value: -6, to: end) ?? end
        case .month:
            start = calendar.date(byAdding: .day, value: -29, to: end) ?? end
        case .threeMonths:
            start = calendar.date(byAdding: .day, value: -89, to: end) ?? end
        }

        return calendar.startOfDay(for: start)...end
    }

    private var filteredEntries: [WeightEntry] {
        weightEntries
            .filter { chartDateRange.contains(calendar.startOfDay(for: $0.date)) }
            .sorted { $0.date < $1.date }
    }

    private var chartPoints: [ChartPoint] {
        Dictionary(grouping: filteredEntries) { calendar.startOfDay(for: $0.date) }
            .compactMapValues { entries in entries.max { $0.date < $1.date } }
            .sorted { $0.key < $1.key }
            .map { ChartPoint(date: $0.key, weight: $0.value.weight) }
    }

    private var latestDisplayedWeight: Double? {
        chartPoints.last?.weight
    }

    private var yDomain: ClosedRange<Double> {
        let values = chartPoints.map(\.weight) + [targetWeight]
        guard let minValue = values.min(), let maxValue = values.max() else {
            return (targetWeight - 4)...(targetWeight + 4)
        }

        let lower = floor((minValue - 1.5) * 2) / 2
        let upper = ceil((maxValue + 1.5) * 2) / 2
        return lower...upper
    }

    private var xAxisDates: [Date] {
        let dates = chartPoints.map(\.date)
        guard !dates.isEmpty else { return [] }

        switch timeRange {
        case .week:
            return dates
        case .month:
            let indices = [0, max(dates.count / 4, 1), max(dates.count / 2, 1), max((dates.count * 3) / 4, 1), max(dates.count - 1, 0)]
            return uniqueDates(from: indices.compactMap { dates.indices.contains($0) ? dates[$0] : nil })
        case .threeMonths:
            let indices = [0, max(dates.count / 3, 1), max((dates.count * 2) / 3, 1), max(dates.count - 1, 0)]
            return uniqueDates(from: indices.compactMap { dates.indices.contains($0) ? dates[$0] : nil })
        }
    }

    private func uniqueDates(from dates: [Date]) -> [Date] {
        var seen = Set<Date>()
        return dates.filter { seen.insert($0).inserted }
    }

    private var yAxisValues: [Double] {
        let step = max(((yDomain.upperBound - yDomain.lowerBound) / 4).rounded(.up), 1)
        return stride(from: yDomain.lowerBound, through: yDomain.upperBound, by: step).map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                Text("体重推移")
                    .font(.system(size: 18, weight: .heavy))

                Spacer()

                VStack(alignment: .leading, spacing: 10) {
                    ProgressLegendItem(color: Color(red: 0.11, green: 0.49, blue: 0.98), title: "現在の体重", value: latestDisplayedWeight.map { String(format: "%.1fkg", $0) } ?? "--.-kg")
                    ProgressLegendItem(color: Color.gray.opacity(0.6), title: "目標体重", value: String(format: "%.1fkg", targetWeight), isDashed: true)
                }
            }

            if chartPoints.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 38, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("体重データがまだありません")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 260)
            } else {
                Chart {
                    RuleMark(y: .value("目標体重", targetWeight))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 5]))
                        .foregroundStyle(Color.gray.opacity(0.7))
                        .annotation(position: .trailing) {
                            Text(String(format: "%.1f", targetWeight))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color.gray.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }

                    ForEach(chartPoints) { point in
                        AreaMark(
                            x: .value("日付", point.date),
                            yStart: .value("下限", yDomain.lowerBound),
                            yEnd: .value("体重", point.weight)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.11, green: 0.49, blue: 0.98).opacity(0.18),
                                    Color(red: 0.11, green: 0.49, blue: 0.98).opacity(0.04)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        LineMark(
                            x: .value("日付", point.date),
                            y: .value("体重", point.weight)
                        )
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        .foregroundStyle(Color(red: 0.11, green: 0.49, blue: 0.98))
                    }

                    if let latestDisplayedWeight, let latestDate = chartPoints.last?.date {
                        PointMark(
                            x: .value("最新日付", latestDate),
                            y: .value("最新体重", latestDisplayedWeight)
                        )
                        .symbolSize(55)
                        .foregroundStyle(Color(red: 0.11, green: 0.49, blue: 0.98))
                        .annotation(position: .trailing, spacing: 8) {
                            Text(String(format: "%.1f", latestDisplayedWeight))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(red: 0.11, green: 0.49, blue: 0.98), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                }
                .chartXScale(domain: chartDateRange)
                .chartYScale(domain: yDomain)
                .chartLegend(.hidden)
                .chartXAxis {
                    AxisMarks(values: xAxisDates) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0))
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(axisLabel(for: date))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: yAxisValues) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(Color.gray.opacity(0.14))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0))
                        AxisValueLabel {
                            if let number = value.as(Double.self) {
                                Text(number, format: .number.precision(.fractionLength(0)))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea.background(Color.clear)
                }
                .frame(height: 320)

                Text("(kg)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.top, -8)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 22)
        .background(ProgressCardBackground())
    }

    private func axisLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = timeRange == .threeMonths ? "M月" : "M/d"
        return formatter.string(from: date)
    }
}

private struct ProgressLegendItem: View {
    let color: Color
    let title: String
    let value: String
    var isDashed: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            if isDashed {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 14, height: 2)
                    .overlay(
                        Rectangle()
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                            .foregroundColor(color)
                    )
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 14, height: 14)
            }

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.primary)
        }
    }
}

private struct MonthlyNutritionProgressCard: View {
    let dailyRecords: [DailyRecord]
    let targetCalories: Int

    private var calendar: Calendar {
        var value = Calendar.current
        value.locale = Locale(identifier: "ja_JP")
        return value
    }

    private var currentMonthRecords: [DailyRecord] {
        guard let interval = calendar.dateInterval(of: .month, for: Date()) else { return [] }
        return dailyRecords.filter { interval.contains($0.date) }
    }

    private var recordsWithMeals: [DailyRecord] {
        currentMonthRecords.filter { !$0.foodEntries.isEmpty }
    }

    private var averageCalories: Int {
        guard !recordsWithMeals.isEmpty else { return 0 }
        let total = recordsWithMeals.reduce(0) { $0 + $1.totalCalories }
        return Int((Double(total) / Double(recordsWithMeals.count)).rounded())
    }

    private var withinTargetDays: Int {
        recordsWithMeals.filter { $0.totalCalories <= targetCalories }.count
    }

    private var overDays: Int {
        max(recordsWithMeals.count - withinTargetDays, 0)
    }

    private var withinTargetRate: Int {
        guard !recordsWithMeals.isEmpty else { return 0 }
        return Int((Double(withinTargetDays) / Double(recordsWithMeals.count) * 100).rounded())
    }

    private var overRate: Int {
        guard !recordsWithMeals.isEmpty else { return 0 }
        return Int((Double(overDays) / Double(recordsWithMeals.count) * 100).rounded())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 6) {
                Text("食事の進歩")
                    .font(.system(size: 18, weight: .heavy))
                Text("(今月)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 0) {
                NutritionMetricColumn(
                    title: "平均摂取",
                    value: "\(averageCalories)kcal",
                    detail: "目標 \(targetCalories)kcal",
                    accent: Color(red: 0.11, green: 0.49, blue: 0.98)
                )

                Divider()
                    .frame(height: 72)

                NutritionMetricColumn(
                    title: "目標内",
                    value: "\(withinTargetDays)日",
                    detail: "\(withinTargetRate)%",
                    accent: Color.green
                )

                Divider()
                    .frame(height: 72)

                NutritionMetricColumn(
                    title: "オーバー",
                    value: "\(overDays)日",
                    detail: "\(overRate)%",
                    accent: Color.orange
                )
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 22)
        .background(ProgressCardBackground())
    }
}

private struct NutritionMetricColumn: View {
    let title: String
    let value: String
    let detail: String
    let accent: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(accent)

            Text(detail)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CoachReflectionCard: View {
    let trainer: PersonalTrainer?
    let reflection: String

    private var trainerImage: UIImage? {
        trainer?.profileImage(named: "first") ?? trainer?.avatarImage(for: .smile) ?? trainer?.image
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Group {
                if let trainerImage {
                    Image(uiImage: trainerImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.15))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                Text("トレーナーの振り返り")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(.primary)

                Text(reflection)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .background(ProgressCardBackground())
    }
}

private struct NextActionCard: View {
    let steps: [ProgressNextStep]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("次の一歩")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.primary)

            VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 12) {
                        Image(systemName: step.icon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(step.tint, in: Circle())

                        Text(step.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)

                    if index < steps.count - 1 {
                        Divider()
                            .padding(.leading, 50)
                    }
                }
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .background(ProgressCardBackground())
    }
}

private struct ProgressNextStep {
    let title: String
    let icon: String
    let tint: Color
}

private enum ProgressInsightBuilder {
    static func reflection(
        trainer: PersonalTrainer?,
        user: User,
        records: [DailyRecord],
        weightEntries: [WeightEntry]
    ) -> String {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: Date())
        let monthRecords = records.filter { record in
            guard let interval else { return false }
            return interval.contains(record.date)
        }
        let recordsWithMeals = monthRecords.filter { !$0.foodEntries.isEmpty }
        let targetCalories = max(user.calculateDailyCalories(maintenanceCalories: user.calculateTDEEMifflinStJeor()), 1200)
        let successDays = recordsWithMeals.filter { $0.totalCalories <= targetCalories }.count

        let monthlyWeights = weightEntries
            .filter { entry in
                guard let interval else { return false }
                return interval.contains(entry.date)
            }
            .sorted { $0.date < $1.date }

        let weightChange: Double
        if let first = monthlyWeights.first?.weight, let last = monthlyWeights.last?.weight {
            weightChange = last - first
        } else {
            weightChange = 0
        }

        if successDays >= max(recordsWithMeals.count - 2, 1) {
            return "今月は記録が安定しています。今のペースなら、体重も着実に整っていきそうです。"
        }

        if weightChange < 0 {
            return "体重は少しずつ下がっています。夕食のカロリーを意識できると、さらに変化が出やすいです。"
        }

        switch trainer?.preferences.personality {
        case .strict:
            return "記録は続いています。次はオーバーした日を減らして、結果につなげていきましょう。"
        case .logical:
            return "数字を見る限り、夜の摂取量を少し整えるだけでも今月の結果は変わります。"
        default:
            return "今月もちゃんと積み重ねられています。あと少しだけ夕食を整えると、さらに安定します。"
        }
    }

    static func nextSteps(
        user: User,
        records: [DailyRecord],
        weightEntries: [WeightEntry]
    ) -> [ProgressNextStep] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: Date())
        let monthRecords = records.filter { record in
            guard let interval else { return false }
            return interval.contains(record.date)
        }
        let recordsWithMeals = monthRecords.filter { !$0.foodEntries.isEmpty }
        let targetCalories = max(user.calculateDailyCalories(maintenanceCalories: user.calculateTDEEMifflinStJeor()), 1200)
        let averageCalories = recordsWithMeals.isEmpty ? 0 : Int((Double(recordsWithMeals.reduce(0) { $0 + $1.totalCalories }) / Double(recordsWithMeals.count)).rounded())
        let averageOver = max(averageCalories - targetCalories, 0)
        let hasWeightLogsThisWeek = weightEntries.contains { entry in
            guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: Date()) else { return false }
            return entry.date >= weekAgo
        }
        let proteinAverage = recordsWithMeals.isEmpty ? 0 : Int((recordsWithMeals.reduce(0.0) { total, record in
            total + record.foodEntries.reduce(0.0) { $0 + $1.protein }
        } / Double(recordsWithMeals.count)).rounded())

        return [
            ProgressNextStep(
                title: averageOver > 80 ? "夜の摂取カロリーを平均\(averageOver)kcal下げる" : "夕食を今のまま維持する",
                icon: "checkmark",
                tint: Color.green
            ),
            ProgressNextStep(
                title: hasWeightLogsThisWeek ? "体重を毎朝記録する" : "まずは今週3回体重を記録する",
                icon: "checkmark",
                tint: Color(red: 0.20, green: 0.53, blue: 0.98)
            ),
            ProgressNextStep(
                title: proteinAverage < 80 ? "たんぱく質をあと20g増やす" : "たんぱく質の維持を続ける",
                icon: "checkmark",
                tint: Color.orange
            )
        ]
    }
}

private struct ProgressCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white)
            .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 8)
    }
}

struct WeightInputView: View {
    @ObservedObject var recordViewModel: RecordViewModel
    @EnvironmentObject var user: User
    @State private var weightText = ""
    @State private var selectedDate = Date()
    @State private var note = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("体重 (kg)")
                            .font(.headline)
                        TextField("例: 65.5", text: $weightText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("日付")
                            .font(.headline)
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("メモ（任意）")
                            .font(.headline)
                        TextField("例: 朝食後", text: $note)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding()

                Button("記録する") {
                    if let weight = Double(weightText) {
                        recordViewModel.addWeightEntry(
                            weight: weight,
                            date: selectedDate,
                            note: note.isEmpty ? nil : note
                        )
                        user.registerWeightRecord()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .disabled(weightText.isEmpty || Double(weightText) == nil)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(weightText.isEmpty || Double(weightText) == nil ? Color.gray : Color.blue)
                .cornerRadius(10)
                .padding()
            }
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            )
            .navigationTitle("体重を記録")
            .navigationBarItems(leading:
                Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
