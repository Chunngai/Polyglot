//
//  Variables.swift
//  Polyglot
//
//  Created by Sola on 2023/1/12.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct LangCodes {
    
    // MARK: - Language codes.
    
    static let en: String = "en"
    static let ja: String = "ja"
    static let es: String = "es"
    
    static let codes: [String] = [
        LangCodes.en,
        LangCodes.ja,
        LangCodes.es
    ]
}

struct Variables {
    
    static var lang: String = LangCodes.en
    
}

struct Constants {
    
    // MARK: - Timing.
    
    static let practiceDuration: TimeInterval = TimeInterval.minute * 10
    static let maxPracticeDuration: TimeInterval = Constants.practiceDuration * 3
    
}
