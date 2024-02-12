//
//  LangCode.swift
//  Polyglot
//
//  Created by Sola on 2023/1/24.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation
import NaturalLanguage

enum LangCode: String, Codable {
        
    case zh
    case en
    case ja
    case es
    case ru
    case ko
    case de
    
}

extension LangCode {
    
    static var currentLanguage: LangCode = .zh
    static var pairedLanguage: LangCode {
        switch LangCode.currentLanguage {
        case .zh: return .zh
        case .en: return .zh
        case .ja: return .zh
        case .es: return .en
        case .ru: return .es
        case .ko: return .ja
        case .de: return .ru
        }
    }
    
    static let learningLanguages: [LangCode] = LangCode.loadLearningLanguages()
    
}

extension LangCode {
    
    var NLLanguage: NLLanguage {
        switch self {
        case .zh: return .simplifiedChinese
        case .en: return .english
        case .ja: return .japanese
        case .es: return .spanish
        case .ru: return .russian
        case .ko: return .korean
        case .de: return .german
        }
    }
    
    var flagIcon: String {
        switch self {
        case .zh: return "🇨🇳"
        case .en: return "🇬🇧"
        case .ja: return "🇯🇵"
        case .es: return "🇪🇸"
        case .ru: return "🇷🇺"
        case .ko: return "🇰🇷"
        case .de: return "🇩🇪"
        }
    }
    
    var voiceIdentifier: String {
        switch self {
        case .zh: return "com.apple.ttsbundle.siri_Li-mu_zh-CN_compact"
        case .en: return "com.apple.voice.compact.en-GB.Daniel"
        case .ja: return "com.apple.ttsbundle.siri_Hattori_ja-JP_compact"
        case .es: return "com.apple.voice.compact.es-ES.Monica"
        case .ru: return "com.apple.voice.compact.ru-RU.Milena"
        case .ko: return "com.apple.voice.enhanced.ko-KR.Yuna"
        case .de: return "com.apple.ttsbundle.siri_Martin_de-DE_compact"
        }
    }
    
    var locale: Locale {
        switch self {
        case .zh: return Locale(identifier: "zh-CN")
        case .en: return Locale(identifier: "en-GB")
        case .ja: return Locale(identifier: "ja-JP")
        case .es: return Locale(identifier: "es-ES")
        case .ru: return Locale(identifier: "ru-RU")
        case .ko: return Locale(identifier: "ko-KR")
        case .de: return Locale(identifier: "de-DE")
        }
    }
}

extension LangCode {
    
    var wordTokenizer: NLTokenizer {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.setLanguage(self.NLLanguage)
        return tokenizer
    }
    
    var sentenceTokenizer: NLTokenizer {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.setLanguage(self.NLLanguage)
        return tokenizer
    }
    
}

extension LangCode {
    
    // MARK: - IO
    
    static var fileName: String {
        return "learningLanguages.json"
    }
    
    static func loadLearningLanguages() -> [LangCode] {
        do {
            let langCodes = try readDataFromJson(
                fileName: LangCode.fileName,
                type: [String].self
            ) as! [String]
            return langCodes.map { langCode in
                LangCode(rawValue: langCode)!
            }
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static func saveLearningLanguages(_ langCodes: inout [LangCode]) {
        do {
            try writeDataToJson(
                fileName: LangCode.fileName,
                data: langCodes.map({ langCode in
                    langCode.rawValue
                })
            )
        } catch {
            print(error)
            exit(1)
        }
    }
}
