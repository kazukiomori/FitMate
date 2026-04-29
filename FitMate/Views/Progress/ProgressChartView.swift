//
//  ProgressChartView.swift
//  FitMate
//

import SwiftUI
import UIKit
import Charts

struct ProgressChartView: View {
    @EnvironmentObject var recordViewModel: RecordViewModel
    @State private var showingWeightInput = false
    @State private var selectedTimeRange = TimeRange.week
    
    enum TimeRange: String, CaseIterable {
        case week = "1週間"
        case month = "1ヶ月"
        case threeMonths = "3ヶ月"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 概要カード
                    ProgressSummaryCard(recordViewModel: recordViewModel)
                    
                    // 期間選択
                    ProgressRangePicker(selectedTimeRange: $selectedTimeRange)
                        .padding(.horizontal)
                    
                    // 体重グラフ
                    WeightChartView(
                        weightEntries: recordViewModel.weightEntries,
                        timeRange: selectedTimeRange
                    )
                    .padding(.horizontal)
                    
                    // 最近の記録
                    RecentRecordsView(recordViewModel: recordViewModel)
                }
                .padding(.vertical)
            }
            .navigationBarItems(trailing:
                Button(action: { showingWeightInput = true }) {
                    Image(systemName: "plus")
                        .font(.title2)
                }
            )
            .sheet(isPresented: $showingWeightInput) {
                WeightInputView(recordViewModel: recordViewModel)
            }
            .background(Color(.systemGray6))
        }
    }
}

struct ProgressRangePicker: View {
    @Binding var selectedTimeRange: ProgressChartView.TimeRange

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProgressChartView.TimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTimeRange = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedTimeRange == range ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(selectedTimeRange == range ? Color(red: 0.12, green: 0.84, blue: 0.80) : .clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
    }
}

struct ProgressSummaryCard: View {
    @ObservedObject var recordViewModel: RecordViewModel
    @EnvironmentObject var user: User

    private var displayedCurrentWeight: Double {
        recordViewModel.getLatestWeight() ?? user.currentWeight
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Text("今月の成果")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 40) {
                VStack {
                    Text(String(format: "%.1f", displayedCurrentWeight))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("現在の体重")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    let change = recordViewModel.getWeightChange()
                    Text(String(format: "%+.1f", change))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(change <= 0 ? .green : .red)
                    Text("体重変化")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Text("\(recordViewModel.weightEntries.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("記録日数")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

struct WeightChartView: View {
    @EnvironmentObject var user: User
    let weightEntries: [WeightEntry]
    let timeRange: ProgressChartView.TimeRange

    private struct ChartPoint: Identifiable {
        let date: Date
        let weight: Double
        let isRecorded: Bool

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
            start = calendar.date(byAdding: .month, value: -3, to: end) ?? end
        }

        return calendar.startOfDay(for: start)...end
    }

    private var dateSlots: [Date] {
        let start = chartDateRange.lowerBound
        let end = chartDateRange.upperBound
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return (0...max(days, 0)).compactMap {
            calendar.date(byAdding: .day, value: $0, to: start)
        }
    }

    private var latestEntryByDay: [Date: WeightEntry] {
        let grouped = Dictionary(grouping: weightEntries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        return grouped.compactMapValues { entries in
            entries.max { $0.date < $1.date }
        }
    }

    private var chartPoints: [ChartPoint] {
        let sortedDays = latestEntryByDay.keys.sorted()
        var lastKnownWeight: Double?

        if let previousDay = sortedDays.last(where: { $0 < chartDateRange.lowerBound }) {
            lastKnownWeight = latestEntryByDay[previousDay]?.weight
        }

        return dateSlots.compactMap { day in
            let normalized = calendar.startOfDay(for: day)

            if let entry = latestEntryByDay[normalized] {
                lastKnownWeight = entry.weight
                return ChartPoint(date: normalized, weight: entry.weight, isRecorded: true)
            }

            guard let lastKnownWeight else { return nil }
            return ChartPoint(date: normalized, weight: lastKnownWeight, isRecorded: false)
        }
    }

    private var recordedPointsInRange: [ChartPoint] {
        chartPoints.filter(\.isRecorded)
    }

    private var xAxisDates: [Date] {
        switch timeRange {
        case .week:
            return dateSlots
        case .month:
            let stride = [0, 5, 10, 15, 20, 25, 29]
            return stride.compactMap { index in
                guard dateSlots.indices.contains(index) else { return nil }
                return dateSlots[index]
            }
        case .threeMonths:
            let monthStarts = dateSlots.filter { calendar.component(.day, from: $0) == 1 }
            let allDates = ([chartDateRange.lowerBound] + monthStarts + [chartDateRange.upperBound]).sorted()
            return Array(NSOrderedSet(array: allDates)) as? [Date] ?? allDates
        }
    }

    private var yDomain: ClosedRange<Double> {
        let values = chartPoints.map(\.weight) + [user.targetWeight]
        guard let minValue = values.min(), let maxValue = values.max() else {
            let center = user.currentWeight
            return (center - 5)...(center + 5)
        }

        let spread = max(maxValue - minValue, 2.0)
        let padding = max(spread * 0.18, 1.0)
        return (minValue - padding)...(maxValue + padding)
    }

    private var yAxisValues: [Double] {
        let lower = yDomain.lowerBound
        let upper = yDomain.upperBound
        let middle = (lower + upper) / 2
        return [upper, middle, lower]
    }

    private var latestDisplayedWeight: Double? {
        chartPoints.last?.weight
    }

    @ViewBuilder
    private func xAxisLabel(for date: Date) -> some View {
        switch timeRange {
        case .week, .month:
            VStack(spacing: 2) {
                Text(date, format: .dateTime.day())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(date, format: .dateTime.month(.defaultDigits).locale(Locale(identifier: "ja_JP")))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        case .threeMonths:
            Text(date, format: .dateTime.month(.abbreviated).locale(Locale(identifier: "ja_JP")))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(spacing: 8) {
                Text("体重")
                    .font(.system(size: 22, weight: .bold))

                if let latestDisplayedWeight {
                    Text("最新 \(latestDisplayedWeight, format: .number.precision(.fractionLength(1)))kg")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            if chartPoints.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("体重データがまだありません")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 260)
            } else {
                Chart {
                    RuleMark(y: .value("目標", user.targetWeight))
                        .foregroundStyle(Color.orange)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 5]))
                        .annotation(position: .leading, spacing: 6) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("目標")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.orange)
                                Text(user.targetWeight, format: .number.precision(.fractionLength(1)))
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.orange)
                                    .clipShape(Capsule())
                            }
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
                                    Color(red: 0.11, green: 0.84, blue: 0.80).opacity(0.35),
                                    Color(red: 0.11, green: 0.84, blue: 0.80).opacity(0.05)
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
                        .foregroundStyle(Color(red: 0.11, green: 0.84, blue: 0.80))
                    }

                    ForEach(recordedPointsInRange) { point in
                        PointMark(
                            x: .value("日付", point.date),
                            y: .value("体重", point.weight)
                        )
                        .foregroundStyle(Color(red: 0.11, green: 0.84, blue: 0.80))
                        .symbolSize(55)
                    }
                }
                .chartXScale(domain: chartDateRange)
                .chartYScale(domain: yDomain)
                .chartXAxis {
                    AxisMarks(values: xAxisDates) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0))
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                xAxisLabel(for: date)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: yAxisValues) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(Color.gray.opacity(0.16))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0))
                        AxisValueLabel {
                            if let number = value.as(Double.self) {
                                Text(number, format: .number.precision(.fractionLength(1)))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 280)
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(Color.clear)
                }
            }

            Text(timeRange == .week ? "直近7日間の推移" : timeRange == .month ? "直近30日間の推移" : "直近3ヶ月の推移")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 18, y: 8)
    }
}

struct RecentRecordsView: View {
    @ObservedObject var recordViewModel: RecordViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("最近の記録")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            LazyVStack(spacing: 10) {
                ForEach(recordViewModel.dailyRecords.suffix(7).reversed(), id: \.id) { record in
                    DailyRecordCard(record: record)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct DailyRecordCard: View {
    let record: DailyRecord
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dateFormatter.string(from: record.date))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let weightEntry = record.weightEntry {
                    Text("\(String(format: "%.1f", weightEntry.weight))kg")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            if !record.foodEntries.isEmpty {
                HStack {
                    Text("食事記録: \(record.foodEntries.count)件")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(record.totalCalories)kcal")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
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
            // 画面のどこかをタップしたらキーボードを閉じる（ボタン操作を邪魔しない）
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
