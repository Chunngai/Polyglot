//
//  Values.swift
//  Polyglot
//
//  Created by Sola on 2023/1/12.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation
import NaturalLanguage

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
    
    static func tokenizerOfLang(of unit: NLTokenUnit = .word) -> NLTokenizer {
        let tokenizer = NLTokenizer(unit: unit)
        tokenizer.setLanguage(LangCode.toNLLanguage(langCode: Variables.lang))
        return tokenizer
    }
    
    static func tokenizerOfPairedLang(of unit: NLTokenUnit = .word) -> NLTokenizer {
        let tokenizer = NLTokenizer(unit: unit)
        tokenizer.setLanguage(LangCode.toNLLanguage(langCode: Variables.pairedLang))
        return tokenizer
    }
    
    private static let _wordSeparators: [String : String] = [
        LangCode.en: " ",
        LangCode.ja: "",
        LangCode.es: " ",
        LangCode.ru: " ",
    ]
    static var wordSeparator: String{
        return Variables._wordSeparators[Variables.lang]!
    }
    
    private static let _subsentenceSeparators: [String : String] = [
        LangCode.en: ",",
        LangCode.ja: "、",
        LangCode.es: ",",
        LangCode.ru: ",",
    ]
    static var subsentenceSeparator: String{
        return Variables._subsentenceSeparators[Variables.lang]!
    }
}

struct Constants {
    
    // MARK: - Timing.
    
    static let practiceDuration: TimeInterval = TimeInterval.minute * 10	
    static let maxPracticeDuration: TimeInterval = Constants.practiceDuration * 3
    
    // MARK: - Network.
    
    static let requestTimeLimit: TimeInterval = TimeInterval.second * 6
    static let userAgent: String = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
    
}
