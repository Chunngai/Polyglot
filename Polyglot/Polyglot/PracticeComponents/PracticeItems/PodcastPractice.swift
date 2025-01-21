//
//  PodcastPractice.swift
//  Polyglot
//
//  Created by Ho on 1/19/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import Foundation

class PodcastPractice: TextMeaningPractice {
    
    init(
        text: String,
        meaning: String,
        textLang: LangCode,
        meaningLang: LangCode,
        textSource: TextSource,
        isTextMachineTranslated: Bool,
        machineTranslatorType: MachineTranslatorType,
        existingPhraseRanges: [NSRange],
        existingPhraseMeanings: [String],
        textAccentLocs: [Int]
    ) {
        super.init(
            text: text,
            meaning: meaning,
            textLang: textLang,
            meaningLang: meaningLang,
            textSource: textSource,
            isTextMachineTranslated: isTextMachineTranslated,
            machineTranslatorType: machineTranslatorType,
            existingPhraseRanges: existingPhraseRanges,
            existingPhraseMeanings: existingPhraseMeanings,
            totalRepetitions: 1,
            currentRepetition: 0,
            textAccentLocs: textAccentLocs
        )
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
}
