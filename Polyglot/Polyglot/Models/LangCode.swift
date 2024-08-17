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
    
    static var currentLanguage: LangCode = .en

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
    
    static let learningLanguages: [LangCode] = LangCode.loadLearningLanguages()

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
