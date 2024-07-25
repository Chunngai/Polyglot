//
//  ListeningPractice.swift
//  Polyglot
//
//  Created by Ho on 2/14/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation

class ListeningPractice: TextMeaningPractice {
    
    enum PracticeType: String, Codable {
        case listenAndRepeat
        case listenAndComplete
    }
    
    var practiceType: PracticeType
    var prompt: String
    var clozeRanges: [NSRange]
    var correctness: Float = 0
    
    init(
        practiceType: PracticeType,
        prompt: String,
        text: String,
        meaning: String,
        textLang: LangCode,
        meaningLang: LangCode,
        textSource: TextSource,
        isTextMachineTranslated: Bool,
        clozeRanges: [NSRange],
        existingPhraseRanges: [NSRange],
        existingPhraseMeanings: [String],
        totalRepetitions: Int,
        currentRepetition: Int
    ) {
        self.practiceType = practiceType
        self.prompt = prompt
        self.clozeRanges = clozeRanges
        
        super.init(
            text: text,
            meaning: meaning,
            textLang: textLang,
            meaningLang: meaningLang,
            textSource: textSource,
            isTextMachineTranslated: isTextMachineTranslated,
            existingPhraseRanges: existingPhraseRanges,
            existingPhraseMeanings: existingPhraseMeanings,
            totalRepetitions: totalRepetitions,
            currentRepetition: currentRepetition
        )
        
    }
    
    convenience init(from another: ListeningPractice) {
        self.init(
            practiceType: another.practiceType,
            prompt: another.prompt,
            text: another.text,
            meaning: another.meaning,
            textLang: another.textLang,
            meaningLang: another.meaningLang,
            textSource: another.textSource,
            isTextMachineTranslated: another.isTextMachineTranslated,
            clozeRanges: another.clozeRanges,
            existingPhraseRanges: another.existingPhraseRanges,
            existingPhraseMeanings: another.existingPhraseMeanings,
            totalRepetitions: another.totalRepetitions,
            currentRepetition: another.currentRepetition
        )
    }
    
    private enum CodingKeys: String, CodingKey {
        case practiceType
        case prompt
        case clozeRanges
        case correctness
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(practiceType, forKey: .practiceType)
        try container.encode(prompt, forKey: .prompt)
        try container.encode(clozeRanges.map(CodableRange.init(from:)), forKey: .clozeRanges)
        try container.encode(correctness, forKey: .correctness)
        
        try super.encode(to: encoder)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        practiceType = try container.decode(PracticeType.self, forKey: .practiceType)
        prompt = try container.decode(String.self, forKey: .prompt)
        clozeRanges = (try container.decode([CodableRange].self, forKey: .clozeRanges)).map { $0.nsRange }
        correctness = try container.decode(Float.self, forKey: .correctness)
        
        try super.init(from: decoder)
    }
}
