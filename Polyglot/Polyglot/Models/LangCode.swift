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
        
    case undetermined
    
    case zh
    case en
    case ja
    case es
    case ru
    case ko
    case de
    
}

extension LangCode {
    
    static var currentLanguage: LangCode = .en
    static var pairedLanguage: LangCode {
        switch LangCode.currentLanguage {
        case .zh: return .zh
        case .en: return .zh
        case .ja: return .zh
        case .es: return .en
        case .ru: return .es
        case .ko: return .ja
        case .de: return .ru
        case .undetermined: return .undetermined
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
        case .undetermined: return .undetermined
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
        case .undetermined: return ""
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
        case .undetermined: return ""
        }
    }
    
    var voiceRate: Float {
        switch self {
        case .zh: return 0.5
        case .en: return 0.55
        case .ja: return 0.55
        case .es: return 0.5
        case .ru: return 0.5
        case .ko: return 0.5
        case .de: return 0.5
        case .undetermined: return 0.5
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
        case .undetermined: return Locale(identifier: "")
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
    
    init(detectedFrom text: String) {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let languageCode = recognizer.dominantLanguage else {
            self = .undetermined  // Default val.
            return
        }
        switch languageCode {
        case .simplifiedChinese, .traditionalChinese: self = .zh
        case .english: self = .en
        case .japanese: self = .ja
        case .spanish: self = .es
        case .russian: self = .ru
        case .korean: self = .ko
        case .german: self = .de
        default: self = .undetermined  // Default val.
        }
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
            ) as? [LangCode] ?? [.en, .ja, .es, .ru, .ko, .de]
            return langCodes
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
