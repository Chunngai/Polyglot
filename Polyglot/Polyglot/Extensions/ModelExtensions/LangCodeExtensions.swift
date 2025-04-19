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
    
    var accentAnalyzer: AccentAnalyzerProtocol? {
        
        switch self {
        case .zh: return nil
        case .en: return nil
        case .ja: return JapaneseAccentAnalyzer.shared
        case .es: return nil
        case .ru: return RussianAccentAnalyzer.shared
        case .ko: return nil
        case .de: return nil
        case .undetermined: return nil
        }
        
    }
    
    var shouldAddAccentMarksToTextInPractices: Bool {
        
        if self == .ru {
            return true
        }
        return false
        
    }
    
    func processTextForSpeechUtterance(text: String) -> String {
        
        if self == .ru {
            return text
                .replacingOccurrences(of: "«", with: "")
                .replacingOccurrences(of: "»", with: "")
        } else {
            return text
        }
        
    }
    
    var languagesForTranslation: [LangCode] {
        var langs = LangCode.learningLanguages
        if let indexOfCurrentLang = langs.firstIndex(of: self) {
            langs.remove(at: indexOfCurrentLang)
        }
        langs = [LangCode.zh] + langs
        return langs
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
        
    func isEnglishText(_ text: String) -> Bool {
        for char in text.unicodeScalars {
            // Check if character is an English letter (A-Z, a-z)
            if !(char.value >= 0x41 && char.value <= 0x5A) && // A-Z
               !(char.value >= 0x61 && char.value <= 0x7A) {  // a-z
                return false
            }
        }
        return true
    }
    
    func isJapaneseText(_ text: String) -> Bool {
        for char in text.unicodeScalars {
            // Check for Hiragana (3040-309F), Katakana (30A0-30FF), Kanji (4E00-9FAF)
            if !(char.value >= 0x3040 && char.value <= 0x309F) && // Hiragana
               !(char.value >= 0x30A0 && char.value <= 0x30FF) && // Katakana
               !(char.value >= 0x4E00 && char.value <= 0x9FAF) {  // Kanji (common)
                return false
            }
        }
        return true
    }
    
    func isSpanishText(_ text: String) -> Bool {
        for char in text.unicodeScalars {
            // Check if character is a Spanish letter (A-Z, a-z, ñ, Ñ, á, é, í, ó, ú, ü, Á, É, Í, Ó, Ú, Ü)
            if !(char.value >= 0x41 && char.value <= 0x5A) && // A-Z
               !(char.value >= 0x61 && char.value <= 0x7A) && // a-z
               char.value != 0xF1 && char.value != 0xD1 &&    // ñ, Ñ
               !(char.value >= 0xE1 && char.value <= 0xFA) {  // á-ú, Á-Ú
                return false
            }
        }
        return true
    }
    
    func isRussianText(_ text: String) -> Bool {
        for char in text.unicodeScalars {
            // Check for Cyrillic letters (0400-04FF)
            if !(char.value >= 0x0410 && char.value <= 0x044F) && // А-я
               char.value != 0x0401 && char.value != 0x0451 {     // Ё, ё
                return false
            }
        }
        return true
    }
    
    func isKoreanText(_ text: String) -> Bool {
        for char in text.unicodeScalars {
            // Check for Hangul syllables (AC00-D7AF) and Hangul Jamo (1100-11FF, 3130-318F)
            if !(char.value >= 0xAC00 && char.value <= 0xD7AF) && // Hangul syllables
               !(char.value >= 0x3130 && char.value <= 0x318F) {  // Hangul Jamo
                return false
            }
        }
        return true
    }
    
    func isGermanText(_ text: String) -> Bool {
        for char in text.unicodeScalars {
            // Check if character is a German letter (A-Z, a-z, ä, ö, ü, ß, Ä, Ö, Ü)
            if !(char.value >= 0x41 && char.value <= 0x5A) && // A-Z
               !(char.value >= 0x61 && char.value <= 0x7A) && // a-z
               char.value != 0xE4 && char.value != 0xF6 &&    // ä, ö
               char.value != 0xFC && char.value != 0xDF &&    // ü, ß
               char.value != 0xC4 && char.value != 0xD6 &&    // Ä, Ö
               char.value != 0xDC {                           // Ü
                return false
            }
        }
        return true
    }
        
    private func mayBeAbbr(_ text: String) -> Bool {
        return text == text.uppercased()
    }
    
//    private func containsLatinLetters(_ text: String) -> Bool {
//        let range = text.range(of: "[a-zA-Z]", options: .regularExpression)
//        return range != nil
//    }
    
//    private func clozeFilterForZhJaKo(_ text: String) -> Bool {
//        return containsLatinLetters(text) || text.isNumericText
//    }
//    
//    private func clozeFilterForLangsWithLatinLetters(_ text: String) -> Bool {
//        return mayBeAbbr(text) || text.isNumericText
//    }
//    
//    private func clozeFilterForLangsWithSlavicLetters(_ text: String) -> Bool {
//        return mayBeAbbr(text) || text.isNumericText || containsLatinLetters(text)
//    }
    
    private func englishClozeFilter(_ text: String) -> Bool {
        if !isEnglishText(text) {
            return true
        }
        if mayBeAbbr(text) {
            return true
        }
        if text.isNumericText {
            return true
        }
        return false
    }
    
    private func spanishClozeFilter(_ text: String) -> Bool {
        if !isSpanishText(text) {
            return true
        }
        if mayBeAbbr(text) {
            return true
        }
        if text.isNumericText {
            return true
        }
        return false
    }
    
    private func russianClozeFilter(_ text: String) -> Bool {
        if !isRussianText(text) {
            return true
        }
        if mayBeAbbr(text) {
            return true
        }
        if text.isNumericText {
            return true
        }
        return false
    }
    
    private func germanClozeFilter(_ text: String) -> Bool {
        if !isGermanText(text) {
            return true
        }
        if mayBeAbbr(text) {
            return true
        }
        if text.isNumericText {
            return true
        }
        return false
    }
    
    private func japaneseClozeFilter(_ text: String) -> Bool {
        if !isJapaneseText(text) {
            return true
        }
        if text.isNumericText {
            return true
        }
        return false
    }
    
    private func koreanClozeFilter(_ text: String) -> Bool {
        if !isKoreanText(text) {
            return true
        }
        if text.isNumericText {
            return true
        }
        return false
    }
    
    var shouldFilterClozeText: (String) -> Bool {
        switch self {
        case .zh: return { _ in false }
        case .en: return englishClozeFilter
        case .ja: return japaneseClozeFilter
        case .es: return spanishClozeFilter
        case .ru: return russianClozeFilter
        case .ko: return koreanClozeFilter
        case .de: return germanClozeFilter
        case .undetermined: return { _ in false }
        }
    }
    
    var shouldNotFilterPeranthesisText: (String) -> Bool {
        switch self {
        case .zh: return { _ in true }
        case .en: return isEnglishText
        case .ja: return isJapaneseText
        case .es: return isSpanishText
        case .ru: return isRussianText
        case .ko: return isKoreanText
        case .de: return isGermanText
        case .undetermined: return { _ in true }
        }
    }
    
}

extension LangCode {
    
    // MARK: - Lang Configs
    
    private static var lang2configs: [LangCode: LangConfigs] = [:]
    var configs: LangConfigs {
        get {
            if !LangCode.lang2configs.keys.contains(self) {
                LangCode.lang2configs[self] = LangConfigs.load(for: self)
            }
            return LangCode.lang2configs[self]!
        }
        set {
            var newConfigs = newValue
            LangConfigs.save(&newConfigs, for: self)
            LangCode.lang2configs[self] = newConfigs
        }
    }
    
}

struct LangConfigs: Codable {
    
    var languageForTranslation: LangCode
    
    var voiceRate: Float
    var slowVoiceRate: Float
    
    var phraseReviewPracticeDuration: Int
    var listeningPracticeDuration: Int
    var speakingPracticeDuration: Int
    var readingPracticeDuration: Int
    
//    var practiceRepetition: Int
    var wordPracticeRepetition: Int
    var listeningPracticeRepetition: Int
    var speakingPracticeRepetition: Int

    var isDuolingoOnlyForShadowing: Bool
    var isDuolingoOnlyForSpeaking: Bool
    var isDuolingoOnlyForReading: Bool
    var isDuolingoOnlyForPodcast: Bool
    
    var canGenerateTextsWithLLMsForPractices: Bool
    
    var shouldRemindToAddNewArticles: Bool
    
    init(
        languageForTranslation: LangCode,
        voiceRate: Float,
        slowVoiceRate: Float,
        phraseReviewPracticeDuration: Int,
        listeningPracticeDuration: Int,
        speakingPracticeDuration: Int,
        readingPracticeDuration: Int,
        wordPracticeRepetition: Int,
        listeningPracticeRepetition: Int,
        speakingPracticeRepetition: Int,
        isDuolingoOnlyForShadowing: Bool,
        isDuolingoOnlyForSpeaking: Bool,
        isDuolingoOnlyForReading: Bool,
        isDuolingoOnlyForPodcast: Bool,
        canGenerateTextsWithLLMsForPractices: Bool,
        shouldRemindToAddNewArticles: Bool
    ) {
        self.languageForTranslation = languageForTranslation
        self.voiceRate = voiceRate
        self.slowVoiceRate = slowVoiceRate
        self.phraseReviewPracticeDuration = phraseReviewPracticeDuration
        self.listeningPracticeDuration = listeningPracticeDuration
        self.speakingPracticeDuration = speakingPracticeDuration
        self.readingPracticeDuration = readingPracticeDuration
        self.wordPracticeRepetition = wordPracticeRepetition
        self.listeningPracticeRepetition = listeningPracticeRepetition
        self.speakingPracticeRepetition = speakingPracticeRepetition
        self.isDuolingoOnlyForShadowing = isDuolingoOnlyForShadowing
        self.isDuolingoOnlyForSpeaking = isDuolingoOnlyForSpeaking
        self.isDuolingoOnlyForReading = isDuolingoOnlyForReading
        self.isDuolingoOnlyForPodcast = isDuolingoOnlyForPodcast
        self.canGenerateTextsWithLLMsForPractices = canGenerateTextsWithLLMsForPractices
        self.shouldRemindToAddNewArticles = shouldRemindToAddNewArticles
    }
    
    enum CodingKeys: String, CodingKey {
                
        case languageForTranslation
        
        case voiceRate
        case slowVoiceRate
        
        case phraseReviewPracticeDuration
        case listeningPracticeDuration
        case speakingPracticeDuration
        case readingPracticeDuration
        
        case practiceRepetition  // Old.
        case wordPracticeRepetition
        case listeningPracticeRepetition
        case speakingPracticeRepetition

        case isDuolingoOnlyForShadowing
        case isDuolingoOnlyForSpeaking
        case isDuolingoOnlyForReading
        case isDuolingoOnlyForPodcast
        
        case canGenerateTextsWithLLMsForPractices
        
        case shouldRemindToAddNewArticles
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(languageForTranslation, forKey: .languageForTranslation)
        try container.encode(voiceRate, forKey: .voiceRate)
        try container.encode(slowVoiceRate, forKey: .slowVoiceRate)
        try container.encode(phraseReviewPracticeDuration, forKey: .phraseReviewPracticeDuration)
        try container.encode(listeningPracticeDuration, forKey: .listeningPracticeDuration)
        try container.encode(speakingPracticeDuration, forKey: .speakingPracticeDuration)
        try container.encode(readingPracticeDuration, forKey: .readingPracticeDuration)
        try container.encode(wordPracticeRepetition, forKey: .wordPracticeRepetition)
        try container.encode(listeningPracticeRepetition, forKey: .listeningPracticeRepetition)
        try container.encode(speakingPracticeRepetition, forKey: .speakingPracticeRepetition)
        try container.encode(isDuolingoOnlyForShadowing, forKey: .isDuolingoOnlyForShadowing)
        try container.encode(isDuolingoOnlyForSpeaking, forKey: .isDuolingoOnlyForSpeaking)
        try container.encode(isDuolingoOnlyForReading, forKey: .isDuolingoOnlyForReading)
        try container.encode(isDuolingoOnlyForPodcast, forKey: .isDuolingoOnlyForPodcast)
        try container.encode(canGenerateTextsWithLLMsForPractices, forKey: .canGenerateTextsWithLLMsForPractices)
        try container.encode(shouldRemindToAddNewArticles, forKey: .shouldRemindToAddNewArticles)
    
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        languageForTranslation = try values.decode(LangCode.self, forKey: .languageForTranslation)
        voiceRate = try values.decode(Float.self, forKey: .voiceRate)
        do {
            slowVoiceRate = try values.decode(Float.self, forKey: .slowVoiceRate)
        } catch {
            slowVoiceRate = Self.defaultConfigs.slowVoiceRate
        }
        do {
            phraseReviewPracticeDuration = try values.decode(Int.self, forKey: .phraseReviewPracticeDuration)
        } catch {
            phraseReviewPracticeDuration = Self.defaultConfigs.phraseReviewPracticeDuration
        }
        do {
            listeningPracticeDuration = try values.decode(Int.self, forKey: .listeningPracticeDuration)
        } catch {
            listeningPracticeDuration = Self.defaultConfigs.listeningPracticeDuration
        }
        do {
            speakingPracticeDuration = try values.decode(Int.self, forKey: .speakingPracticeDuration)
        } catch {
            speakingPracticeDuration = Self.defaultConfigs.speakingPracticeDuration
        }
        do {
            readingPracticeDuration = try values.decode(Int.self, forKey: .readingPracticeDuration)
        } catch {
            readingPracticeDuration = Self.defaultConfigs.readingPracticeDuration
        }
        do {
            wordPracticeRepetition = try values.decode(Int.self, forKey: .wordPracticeRepetition)
        } catch {
            wordPracticeRepetition = try values.decode(Int.self, forKey: .practiceRepetition)
        }
        do {
            listeningPracticeRepetition = try values.decode(Int.self, forKey: .listeningPracticeRepetition)
        } catch {
            listeningPracticeRepetition = try values.decode(Int.self, forKey: .practiceRepetition)
        }
        do {
            speakingPracticeRepetition = try values.decode(Int.self, forKey: .speakingPracticeRepetition)
        } catch {
            speakingPracticeRepetition = try values.decode(Int.self, forKey: .practiceRepetition)
        }
        do {
            isDuolingoOnlyForShadowing = try values.decode(Bool.self, forKey: .isDuolingoOnlyForShadowing)
        } catch {
            isDuolingoOnlyForShadowing = Self.defaultConfigs.isDuolingoOnlyForShadowing
        }
        do {
            isDuolingoOnlyForSpeaking = try values.decode(Bool.self, forKey: .isDuolingoOnlyForSpeaking)
        } catch {
            isDuolingoOnlyForSpeaking = Self.defaultConfigs.isDuolingoOnlyForSpeaking
        }
        do {
            isDuolingoOnlyForReading = try values.decode(Bool.self, forKey: .isDuolingoOnlyForReading)
        } catch {
            isDuolingoOnlyForReading = Self.defaultConfigs.isDuolingoOnlyForReading
        }
        do {
            isDuolingoOnlyForPodcast = try values.decode(Bool.self, forKey: .isDuolingoOnlyForPodcast)
        } catch {
            isDuolingoOnlyForPodcast = Self.defaultConfigs.isDuolingoOnlyForPodcast
        }
        canGenerateTextsWithLLMsForPractices = try values.decode(Bool.self, forKey: .canGenerateTextsWithLLMsForPractices)
        do {
            shouldRemindToAddNewArticles = try values.decode(Bool.self, forKey: .shouldRemindToAddNewArticles)
        } catch {
            shouldRemindToAddNewArticles = Self.defaultConfigs.shouldRemindToAddNewArticles
        }
        
    }
    
    // MARK: - IO
    
    static func fileName(for lang: LangCode) -> String {
        return "configs.\(lang.rawValue).json"
    }
    
    static func load(for lang: LangCode) -> LangConfigs {
        do {
            let configs = try readDataFromJson(
                fileName: LangConfigs.fileName(for: lang),
                type: LangConfigs.self
            ) as? LangConfigs ?? LangConfigs.defaultConfigs
            return configs
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static func save(_ configs: inout LangConfigs, for lang: LangCode) {
        do {
            try writeDataToJson(
                fileName: LangConfigs.fileName(for: lang),
                data: configs
            )
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static let defaultConfigs = LangConfigs(
        languageForTranslation: LangCode.zh,
        voiceRate: 0.5,
        slowVoiceRate: 0.3,
        phraseReviewPracticeDuration: 5,
        listeningPracticeDuration: 5,
        speakingPracticeDuration: 5,
        readingPracticeDuration: 5,
        wordPracticeRepetition: 2,
        listeningPracticeRepetition: 2,
        speakingPracticeRepetition: 2,
        isDuolingoOnlyForShadowing: false,
        isDuolingoOnlyForSpeaking: false,
        isDuolingoOnlyForReading: false,
        isDuolingoOnlyForPodcast: false,
        canGenerateTextsWithLLMsForPractices: true,
        shouldRemindToAddNewArticles: true
    )
    
}
