//
//  AppConfig.swift
//  FitMate
//

import Foundation

struct AppConfig {
    static var clientToken: String {
        Bundle.main.object(forInfoDictionaryKey: "CLIENT_TOKEN") as? String ?? ""
    }
}
