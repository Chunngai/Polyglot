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
    
}

extension LangCode {
    
    static func toNLLanguage(langCode: String) -> NLLanguage {
        switch langCode {
        case LangCode.zh: return .simplifiedChinese
        case LangCode.en: return .english
        case LangCode.ja: return .japanese
        case LangCode.es: return .spanish
        case LangCode.ru: return .russian
        default: return .english
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
            let langCodes = try readSequenceDataFromJson(fileName: LangCode.fileName, type: String.self) as! [String]
            return langCodes
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static func saveLearningLanguages(_ langCodes: inout [String]) {
        do {
            try writeSequenceDataFromJson(fileName: LangCode.fileName, data: langCodes)
        } catch {
            print(error)
            exit(1)
        }
    }
}
