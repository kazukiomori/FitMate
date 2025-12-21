//
//  AppConfig.swift
//  FitMate
//

import Foundation

struct AppConfig {
    static var clientToken: String {
        Bundle.main.object(forInfoDictionaryKey: "CLIENT_TOKEN") as? String ?? ""
    }
    
    static let baseURL = "https://et40lsliki.execute-api.ap-northeast-1.amazonaws.com"
    
    static let visionURL = "https://79the260tg.execute-api.ap-northeast-1.amazonaws.com"
}
