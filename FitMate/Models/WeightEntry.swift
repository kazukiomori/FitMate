//
//  WeightEntry.swift
//  FitMate
//

import Foundation

struct WeightEntry: Identifiable {
    let id = UUID()
    let weight: Double
    let date: Date
    let note: String?
    
    init(weight: Double, date: Date = Date(), note: String? = nil) {
        self.weight = weight
        self.date = date
        self.note = note
    }
}

