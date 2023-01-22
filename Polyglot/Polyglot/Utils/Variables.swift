//
//  Variables.swift
//  Polyglot
//
//  Created by Sola on 2023/1/12.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation
import NaturalLanguage

// TODO: - Wrap as a struct?
struct LangCodes {
    
    // MARK: - Language codes.
    
    static let zh: String = "zh"
    
    static let en: String = "en"
    static let ja: String = "ja"
    static let es: String = "es"
    
    static let codes: [String] = [
        LangCodes.en,
        LangCodes.ja,
        LangCodes.es
    ]
    
    static func toNLLanguage(langCode: String) -> NLLanguage {
        switch langCode {
        case LangCodes.zh: return .simplifiedChinese
        case LangCodes.en: return .english
        case LangCodes.ja: return .japanese
        case LangCodes.es: return .spanish
        default: return .english
        }
    }
}

struct Variables {
    
    static var lang: String = LangCodes.en
    
    private static let _pairedLang: [String : String] = [
        LangCodes.en: LangCodes.zh,
        LangCodes.ja: LangCodes.zh,
        LangCodes.es: LangCodes.en
    ]
    static var pairedLang: String = Variables._pairedLang[Variables.lang]!
}

struct Constants {
    
    // MARK: - Timing.
    
    static let practiceDuration: TimeInterval = TimeInterval.minute * 10
    static let maxPracticeDuration: TimeInterval = Constants.practiceDuration * 3
    
}
