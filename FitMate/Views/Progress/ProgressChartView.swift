//
//  ProgressChartView.swift
//  FitMate
//

import SwiftUI
import UIKit

struct ProgressChartView: View {
    @EnvironmentObject var recordViewModel: RecordViewModel
    @State private var showingWeightInput = false
    @State private var selectedTimeRange = TimeRange.month
    
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
                    Picker("期間", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // 体重グラフ
                    WeightChartView(
                        weightEntries: recordViewModel.weightEntries,
                        timeRange: selectedTimeRange
                    )
                    .frame(height: 300)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                    
                    // 最近の記録
                    RecentRecordsView(recordViewModel: recordViewModel)
                }
                .padding(.vertical)
            }
            .navigationTitle("進捗")
            .navigationBarItems(trailing:
                Button(action: { showingWeightInput = true }) {
                    Image(systemName: "plus")
                        .font(.title2)
                }
            )
            .sheet(isPresented: $showingWeightInput) {
                WeightInputView(recordViewModel: recordViewModel)
            }
            .background(Color.gray.opacity(0.1))
        }
    }
}

struct ProgressSummaryCard: View {
    @ObservedObject var recordViewModel: RecordViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            Text("今月の成果")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 40) {
                VStack {
                    Text(String(format: "%.1f", recordViewModel.weightEntries.first?.weight ?? 0))
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
    let weightEntries: [WeightEntry]
    let timeRange: ProgressChartView.TimeRange
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.locale = Locale(identifier: "ja_JP")
        // 週の左端を月曜にする
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 1
        return cal
    }
    
    private var referenceDate: Date {
        calendar.startOfDay(for: Date())
    }
    
    private func dateSlots() -> [Date] {
        switch timeRange {
        case .week:
            let start = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start ?? referenceDate
            return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        case .month:
            let interval = calendar.dateInterval(of: .month, for: referenceDate)
            let start = interval?.start ?? referenceDate
            let endExclusive = interval?.end ?? calendar.date(byAdding: .month, value: 1, to: start) ?? start
            let last = calendar.date(byAdding: .day, value: -1, to: endExclusive) ?? start
            let days = calendar.dateComponents([.day], from: start, to: last).day ?? 0
            return (0...max(days, 0)).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        case .threeMonths:
            let end = referenceDate
            let start = calendar.startOfDay(for: calendar.date(byAdding: .month, value: -3, to: end) ?? end)
            let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
            return (0...max(days, 0)).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        }
    }
    
    private func latestEntryByDay() -> [Date: WeightEntry] {
        let grouped = Dictionary(grouping: weightEntries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        return grouped.compactMapValues { entries in
            entries.max { $0.date < $1.date }
        }
    }
    
    private func tickIndices(for slots: [Date]) -> [Int] {
        guard !slots.isEmpty else { return [] }
        let lastIndex = slots.count - 1
        
        switch timeRange {
        case .week:
            return Array(0...lastIndex)
        case .month:
            // 1日/8日/15日/22日/最終日 を基本に、範囲内に丸める
            let candidates = [0, 7, 14, 21, lastIndex]
            return Array(Set(candidates.map { min(max($0, 0), lastIndex) })).sorted()
        case .threeMonths:
            var indices: [Int] = [0, lastIndex]
            for (idx, date) in slots.enumerated() {
                let day = calendar.component(.day, from: date)
                if day == 1 { indices.append(idx) }
            }
            return Array(Set(indices)).sorted()
        }
    }
    
    private func label(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        switch timeRange {
        case .week:
            formatter.dateFormat = "M/d(EEE)"
        case .month:
            formatter.dateFormat = "d"
        case .threeMonths:
            formatter.dateFormat = "M/d"
        }
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("体重推移")
                .font(.headline)
                .fontWeight(.bold)
            
            // カスタム折れ線グラフ（指定期間の全日付スロットを作り、未入力日は空白）
            let slots = dateSlots()
            let byDay = latestEntryByDay()
            let weights: [Double?] = slots.map { day in
                byDay[calendar.startOfDay(for: day)]?.weight
            }
            
            let availableWeights = weights.compactMap { $0 }
            let minWeight = availableWeights.min() ?? 0
            let maxWeight = availableWeights.max() ?? 100
            let weightRange = maxWeight - minWeight
            let adjustedRange = weightRange < 2 ? 2 : weightRange
            let adjustedMin = minWeight - (adjustedRange - weightRange) / 2
            let adjustedMax = maxWeight + (adjustedRange - weightRange) / 2
            
            VStack(spacing: 6) {
                GeometryReader { geometry in
                    ZStack {
                        // グリッドライン
                        VStack {
                            ForEach(0..<5) { i in
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                                if i < 4 { Spacer() }
                            }
                        }
                        
                        // 体重数値ラベル
                        HStack {
                            VStack {
                                ForEach(0..<5) { i in
                                    let weight = adjustedMax - (adjustedMax - adjustedMin) * Double(i) / 4
                                    Text(String(format: "%.1f", weight))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    if i < 4 { Spacer() }
                                }
                            }
                            .frame(width: 30)
                            
                            Spacer()
                        }
                        
                        // 折れ線（未入力日は線を切る）
                        Path { path in
                            var hasPreviousPoint = false
                            for index in slots.indices {
                                guard let weight = weights[index], adjustedMax != adjustedMin else {
                                    hasPreviousPoint = false
                                    continue
                                }
                                let x = 40 + (geometry.size.width - 40) * Double(index) / Double(max(slots.count - 1, 1))
                                let y = geometry.size.height * (1 - (weight - adjustedMin) / (adjustedMax - adjustedMin))
                                
                                if !hasPreviousPoint {
                                    path.move(to: CGPoint(x: x, y: y))
                                    hasPreviousPoint = true
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        
                        // データポイント（入力日だけ表示）
                        ForEach(Array(slots.indices), id: \.self) { index in
                            if let weight = weights[index], adjustedMax != adjustedMin {
                                let x = 40 + (geometry.size.width - 40) * Double(index) / Double(max(slots.count - 1, 1))
                                let y = geometry.size.height * (1 - (weight - adjustedMin) / (adjustedMax - adjustedMin))
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                                    .position(x: x, y: y)
                            }
                        }
                        
                        if availableWeights.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 38))
                                    .foregroundColor(.gray)
                                Text("データがありません")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .padding(.leading, 10)
                
                // X軸（日付）
                GeometryReader { geo in
                    let ticks = tickIndices(for: slots)
                    ZStack(alignment: .topLeading) {
                        ForEach(ticks, id: \.self) { idx in
                            let x = 40 + (geo.size.width - 40) * Double(idx) / Double(max(slots.count - 1, 1))
                            Text(label(for: slots[idx]))
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .frame(width: 60, alignment: idx == 0 ? .leading : (idx == slots.count - 1 ? .trailing : .center))
                                .position(x: x, y: 8)
                        }
                    }
                }
                .frame(height: 16)
                .padding(.leading, 10)
            }
        }
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
