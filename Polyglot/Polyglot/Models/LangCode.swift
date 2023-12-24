//
//  LangCode.swift
//  Polyglot
//
//  Created by Sola on 2023/1/24.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation
import NaturalLanguage

struct LangCode {
        
    static let zh: String = "zh"
    static let en: String = "en"
    static let ja: String = "ja"
    static let es: String = "es"
    static let ru: String = "ru"
    static let ko: String = "ko"
    static let de: String = "de"
    
}

extension LangCode {
    
    static func toNLLanguage(langCode: String) -> NLLanguage {
        switch langCode {
        case LangCode.zh: return .simplifiedChinese
        case LangCode.en: return .english
        case LangCode.ja: return .japanese
        case LangCode.es: return .spanish
        case LangCode.ru: return .russian
        case LangCode.ko: return .korean
        case LangCode.de: return .german
        default: return .english
        }
    }
    
    static func toFlagIcon(langCode: String) -> String {
        switch langCode {
        case LangCode.zh: return "🇨🇳"
        case LangCode.en: return "🇬🇧"
        case LangCode.ja: return "🇯🇵"
        case LangCode.es: return "🇪🇸"
        case LangCode.ru: return "🇷🇺"
        case LangCode.ko: return "🇰🇷"
        case LangCode.de: return "🇩🇪"
        default: return ""
        }
    }
    
    static func toVoiceIdentifier(langCode: String) -> String {
        switch langCode {
        case LangCode.zh: return "com.apple.ttsbundle.siri_Li-mu_zh-CN_compact"
        case LangCode.en: return "com.apple.voice.compact.en-GB.Daniel"
        case LangCode.ja: return "com.apple.ttsbundle.siri_Hattori_ja-JP_compact"
        case LangCode.es: return "com.apple.voice.compact.es-ES.Monica"
        case LangCode.ru: return "com.apple.voice.compact.ru-RU.Milena"
        case LangCode.ko: return "com.apple.voice.enhanced.ko-KR.Yuna"
        case LangCode.de: return "com.apple.ttsbundle.siri_Martin_de-DE_compact"
        default: return LangCode.toVoiceIdentifier(langCode: LangCode.en)
        }
    }
}

extension LangCode {
    
    // MARK: - IO
    
    static var fileName: String {
        return "learningLanguages.json"
    }
    
    static func loadLearningLanguages() -> [String] {
        do {
            let langCodes = try readDataFromJson(
                fileName: LangCode.fileName,
                type: [String].self
            ) as! [String]
            return langCodes
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static func saveLearningLanguages(_ langCodes: inout [String]) {
        do {
            try writeDataToJson(
                fileName: LangCode.fileName,
                data: langCodes
            )
        } catch {
            print(error)
            exit(1)
        }
    }
}
