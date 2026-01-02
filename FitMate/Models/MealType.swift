//
//  MealType.swift
//  FitMate
//

import Foundation

enum MealType: Int, CaseIterable, Codable {
    case breakfast = 0
    case lunch = 1
    case dinner = 2
    case snack = 3
    
    var title: String {
        switch self {
        case .breakfast:
            return "朝食"
        case .lunch:
            return "昼食"
        case .dinner:
            return "夕食"
        case .snack:
            return "間食"
        }
    }
}
