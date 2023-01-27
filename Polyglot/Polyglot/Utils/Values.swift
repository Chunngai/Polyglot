//
//  Values.swift
//  Polyglot
//
//  Created by Sola on 2023/1/12.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct Variables {
    
    static var lang: String = ""
    
    private static let _pairedLangs: [String : String] = [
        LangCode.en: LangCode.zh,
        LangCode.ja: LangCode.zh,
        LangCode.es: LangCode.en,
        LangCode.ru: LangCode.en,
    ]
    static var pairedLang: String{
        return Variables._pairedLangs[Variables.lang]!
    }
}

struct Constants {
    
    // MARK: - Timing.
    
    static let practiceDuration: TimeInterval = TimeInterval.minute * 10
    static let maxPracticeDuration: TimeInterval = Constants.practiceDuration * 3
    
    // MARK: - Network.
    
    static let requestTimeLimit: TimeInterval = TimeInterval.second * 6
    
}
