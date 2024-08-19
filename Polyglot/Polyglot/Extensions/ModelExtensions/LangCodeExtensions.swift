//
//  LangCodeExtensions.swift
//  Polyglot
//
//  Created by Ho on 8/18/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation
import NaturalLanguage

extension LangCode {
    
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
    
    var baiduTranslateLangCode: String {
        
        switch self {
        case .zh: return "zh"
        case .en: return "en"
        case .ja: return "jp"
        case .es: return "spa"
        case .ru: return "ru"
        case .ko: return "kor"
        case .de: return "de"
        case .undetermined: return ""
        }
        
    }
    
}

extension LangCode {
    
    var numberFormatter: NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .spellOut
        numberFormatter.locale = self.locale
        return numberFormatter
    }
    
}

extension LangCode {
    
    private func mayBeAbbr(_ text: String) -> Bool {
        return text == text.uppercased()
    }
    
    private func containsLatinLetters(_ text: String) -> Bool {
        let range = text.range(of: "[a-zA-Z]", options: .regularExpression)
        return range != nil
    }
    
    private func clozeFilterForZhJaKo(_ text: String) -> Bool {
        return containsLatinLetters(text) || text.isNumericText
    }
    
    private func clozeFilterForOtherLangs(_ text: String) -> Bool {
        return mayBeAbbr(text) || text.isNumericText
    }
    
    var clozeFilter: (String) -> Bool {
        switch self {
        case .zh: return clozeFilterForZhJaKo
        case .en: return clozeFilterForOtherLangs
        case .ja: return clozeFilterForZhJaKo
        case .es: return clozeFilterForOtherLangs
        case .ru: return clozeFilterForOtherLangs
        case .ko: return clozeFilterForZhJaKo
        case .de: return clozeFilterForOtherLangs
        case .undetermined: return clozeFilterForOtherLangs
        }
    }
    
}

extension LangCode {
    
    // MARK: - Lang Configs
    
    private static var lang2configs: [LangCode: Configs] = [:]
    var configs: Configs {
        get {
            if !LangCode.lang2configs.keys.contains(self) {
                LangCode.lang2configs[self] = Configs.load(for: self)
            }
            return LangCode.lang2configs[self]!
        }
        set {
            var newConfigs = newValue
            Configs.save(&newConfigs, for: self)
            LangCode.lang2configs[self] = newConfigs
        }
    }
    
}

struct Configs {
    
    var languageForTranslation: LangCode
    var voiceRate: Float
    
    var phraseReviewPracticeDuration: Int
    var listeningPracticeDuration: Int
    var speakingPracticeDuration: Int
    var practiceRepetition: Int
    
    var canGenerateTextsWithLLMsForPractices: Bool
    var ChatGPTAPIURL: String?
    var ChatGPTAPIKey: String?
    
    var baiduTranslateAPPID: String?
    var baiduTranslateAPIKey: String?
    
    var backupEmailAddr: String?
    
}

extension Configs: Codable {
    
    enum CodingKeys: String, CodingKey {
        
        case languageForTranslation
        case voiceRate
        
        case phraseReviewPracticeDuration
        case listeningPracticeDuration
        case speakingPracticeDuration
        case practiceRepetition
        
        case canGenerateTextsWithLLMsForPractices
        case ChatGPTAPIURL
        case ChatGPTAPIKey
        
        case baiduTranslateAPPID
        case baiduTranslateAPIKey
        
        case backupEmailAddr
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(languageForTranslation, forKey: .languageForTranslation)
        try container.encode(voiceRate, forKey: .voiceRate)
        
        try container.encode(phraseReviewPracticeDuration, forKey: .phraseReviewPracticeDuration)
        try container.encode(listeningPracticeDuration, forKey: .listeningPracticeDuration)
        try container.encode(speakingPracticeDuration, forKey: .speakingPracticeDuration)
        try container.encode(practiceRepetition, forKey: .practiceRepetition)
        
        try container.encode(canGenerateTextsWithLLMsForPractices, forKey: .canGenerateTextsWithLLMsForPractices)
        try container.encode(ChatGPTAPIURL, forKey: .ChatGPTAPIURL)
        try container.encode(ChatGPTAPIKey, forKey: .ChatGPTAPIKey)
        
        try container.encode(baiduTranslateAPPID, forKey: .baiduTranslateAPPID)
        try container.encode(baiduTranslateAPIKey, forKey: .baiduTranslateAPIKey)
        
        try container.encode(backupEmailAddr, forKey: .backupEmailAddr)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        languageForTranslation = try values.decode(LangCode.self, forKey: .languageForTranslation)
        voiceRate = try values.decode(Float.self, forKey: .voiceRate)
        
        do {
            phraseReviewPracticeDuration = try values.decode(Int.self, forKey: .phraseReviewPracticeDuration)
        } catch {
            phraseReviewPracticeDuration = 5
        }
        do {
            listeningPracticeDuration = try values.decode(Int.self, forKey: .listeningPracticeDuration)
        } catch {
            listeningPracticeDuration = 5
        }
        do {
            speakingPracticeDuration = try values.decode(Int.self, forKey: .speakingPracticeDuration)
        } catch {
            speakingPracticeDuration = 5
        }
        practiceRepetition = try values.decode(Int.self, forKey: .practiceRepetition)
        
        canGenerateTextsWithLLMsForPractices = try values.decode(Bool.self, forKey: .canGenerateTextsWithLLMsForPractices)
        ChatGPTAPIURL = try values.decode(String?.self, forKey: .ChatGPTAPIURL)
        ChatGPTAPIKey = try values.decode(String?.self, forKey: .ChatGPTAPIKey)
        
        do {
            baiduTranslateAPPID = try values.decode(String?.self, forKey: .baiduTranslateAPPID)
        } catch {
            baiduTranslateAPPID = nil
        }
        do {
            baiduTranslateAPIKey = try values.decode(String?.self, forKey: .baiduTranslateAPIKey)
        } catch {
            baiduTranslateAPIKey = nil
        }
        
        backupEmailAddr = try values.decode(String?.self, forKey: .backupEmailAddr)
    }
}

extension Configs {
    
    // MARK: - IO
    
    static func fileName(for lang: LangCode) -> String {
        return "configs.\(lang.rawValue).json"
    }
    
    static func load(for lang: LangCode) -> Configs {
        do {
            let configs = try readDataFromJson(
                fileName: Configs.fileName(for: lang),
                type: Configs.self
            ) as? Configs ?? Configs.defaultConfigs
            return configs
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static func save(_ configs: inout Configs, for lang: LangCode) {
        do {
            try writeDataToJson(
                fileName: Configs.fileName(for: lang),
                data: configs
            )
        } catch {
            print(error)
            exit(1)
        }
    }
}

extension Configs {
    
    // MARK: - Constants
    
    static let defaultConfigs = Configs(
        languageForTranslation: LangCode.zh,
        voiceRate: 0.5,
        phraseReviewPracticeDuration: 5,
        listeningPracticeDuration: 5,
        speakingPracticeDuration: 5,
        practiceRepetition: 2,
        canGenerateTextsWithLLMsForPractices: true
    )
    
}
