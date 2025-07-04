//
//  ProgressChartView.swift
//  FitMate
//

import SwiftUI

struct ProgressChartView: View {
    @StateObject private var recordViewModel = RecordViewModel()
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
                        weightEntries: recordViewModel.getRecentWeightEntries(days: selectedTimeRange.days),
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
                    Text(String(format: "%.1f", recordViewModel.weightEntries.last?.weight ?? 0))
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("体重推移")
                .font(.headline)
                .fontWeight(.bold)
            
            if weightEntries.isEmpty {
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("データがありません")
                        .foregroundColor(.gray)
                    Text("体重を記録してグラフを表示しましょう")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // カスタム折れ線グラフ
                GeometryReader { geometry in
                    let sortedEntries = weightEntries.sorted { $0.date < $1.date }
                    let minWeight = sortedEntries.map { $0.weight }.min() ?? 0
                    let maxWeight = sortedEntries.map { $0.weight }.max() ?? 100
                    let weightRange = maxWeight - minWeight
                    let adjustedRange = weightRange < 2 ? 2 : weightRange // 最小レンジを2kgに
                    let adjustedMin = minWeight - (adjustedRange - weightRange) / 2
                    let adjustedMax = maxWeight + (adjustedRange - weightRange) / 2
                    
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
                        
                        // 折れ線グラフ
                        Path { path in
                            for (index, entry) in sortedEntries.enumerated() {
                                let x = 40 + (geometry.size.width - 40) * Double(index) / Double(max(sortedEntries.count - 1, 1))
                                let y = geometry.size.height * (1 - (entry.weight - adjustedMin) / (adjustedMax - adjustedMin))
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
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
                        
                        // データポイント
                        ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { index, entry in
                            let x = 40 + (geometry.size.width - 40) * Double(index) / Double(max(sortedEntries.count - 1, 1))
                            let y = geometry.size.height * (1 - (entry.weight - adjustedMin) / (adjustedMax - adjustedMin))
                            
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                        }
                    }
                }
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
                    Text("体重記録")
                        .font(.title2)
                        .fontWeight(.bold)
                    
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
                
                Spacer()
                
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
            .navigationTitle("体重を記録")
            .navigationBarItems(leading:
                Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
