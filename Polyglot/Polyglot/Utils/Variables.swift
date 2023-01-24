//
//  Variables.swift
//  Polyglot
//
//  Created by Sola on 2023/1/12.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct Variables {
    
    static var lang: String = LangCode.en
    
    private static let _pairedLang: [String : String] = [
        LangCode.en: LangCode.zh,
        LangCode.ja: LangCode.zh,
        LangCode.es: LangCode.en
    ]
    static var pairedLang: String = Variables._pairedLang[Variables.lang]!
}

struct Constants {
    
    // MARK: - Timing.
    
    static let practiceDuration: TimeInterval = TimeInterval.minute * 10
    static let maxPracticeDuration: TimeInterval = Constants.practiceDuration * 3
    
}
