//
//  TextMeaningPractice.swift
//  Polyglot
//
//  Created by Ho on 2/14/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation

struct CodableRange: Codable {
    var location: Int
    var length: Int
    
    init(from range: NSRange) {
        self.location = range.location
        self.length = range.length
    }
    
    var nsRange: NSRange {
        return NSRange(location: self.location, length: self.length)
    }
}

class TextMeaningPractice: BasePractice, Codable {
    
    var id: UUID = UUID()
    var text: String
    var meaning: String
    var textLang: LangCode
    var meaningLang: LangCode
    var textSource: TextSource
    var isTextMachineTranslated: Bool
    var existingPhraseRanges: [NSRange]
    var existingPhraseMeanings: [String]
    var totalRepetitions: Int
    var currentRepetition: Int
    
    init(
        text: String,
        meaning: String,
        textLang: LangCode,
        meaningLang: LangCode,
        textSource: TextSource,
        isTextMachineTranslated: Bool,
        existingPhraseRanges: [NSRange],
        existingPhraseMeanings: [String],
        totalRepetitions: Int,
        currentRepetition: Int
    ) {
        self.text = text
        self.meaning = meaning
        self.textLang = textLang
        self.meaningLang = meaningLang
        self.textSource = textSource
        self.isTextMachineTranslated = isTextMachineTranslated
        self.existingPhraseRanges = existingPhraseRanges
        self.existingPhraseMeanings = existingPhraseMeanings
        self.totalRepetitions = totalRepetitions
        self.currentRepetition = currentRepetition
    }
    
    convenience init(from another: TextMeaningPractice) {
        self.init(
            text: another.text,
            meaning: another.meaning,
            textLang: another.textLang,
            meaningLang: another.meaningLang,
            textSource: another.textSource,
            isTextMachineTranslated: another.isTextMachineTranslated,
            existingPhraseRanges: another.existingPhraseRanges,
            existingPhraseMeanings: another.existingPhraseMeanings,
            totalRepetitions: another.totalRepetitions,
            currentRepetition: another.currentRepetition
        )
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case text
        case meaning
        case textLang
        case meaningLang
        case textSource
        case isTextMachineTranslated
        case existingPhraseRanges
        case existingPhraseMeanings
        case totalRepetitions
        case currentRepetition
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(meaning, forKey: .meaning)
        try container.encode(textLang, forKey: .textLang)
        try container.encode(meaningLang, forKey: .meaningLang)
        try container.encode(textSource, forKey: .textSource)
        try container.encode(isTextMachineTranslated, forKey: .isTextMachineTranslated)
        try container.encode(existingPhraseRanges.map(CodableRange.init(from:)), forKey: .existingPhraseRanges)
        try container.encode(existingPhraseMeanings, forKey: .existingPhraseMeanings)
        try container.encode(totalRepetitions, forKey: .totalRepetitions)
        try container.encode(currentRepetition, forKey: .currentRepetition)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        meaning = try container.decode(String.self, forKey: .meaning)
        textLang = try container.decode(LangCode.self, forKey: .textLang)
        meaningLang = try container.decode(LangCode.self, forKey: .meaningLang)
        textSource = try container.decode(TextSource.self, forKey: .textSource)
        isTextMachineTranslated = try container.decode(Bool.self, forKey: .isTextMachineTranslated)
        existingPhraseRanges = (try container.decode([CodableRange].self, forKey: .existingPhraseRanges)).map { $0.nsRange }
        existingPhraseMeanings = try container.decode([String].self, forKey: .existingPhraseMeanings)
        totalRepetitions = try container.decode(Int.self, forKey: .totalRepetitions)
        currentRepetition = try container.decode(Int.self, forKey: .currentRepetition)
    }
    
}
