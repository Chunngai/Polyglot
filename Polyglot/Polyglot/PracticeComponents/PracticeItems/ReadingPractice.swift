//
//  ReadingPractice.swift
//  Polyglot
//
//  Created by Ho on 8/25/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation

class ReadingPractice: TextMeaningPractice {
    
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
    
    convenience init(from another: ReadingPractice) {
        self.init(
            text: another.text,
            meaning: another.meaning,
            textLang: another.textLang,
            meaningLang: another.meaningLang,
            textSource: another.textSource,
            isTextMachineTranslated: another.isTextMachineTranslated,
            machineTranslatorType: another.machineTranslatorType,
            existingPhraseRanges: another.existingPhraseRanges,
            existingPhraseMeanings: another.existingPhraseMeanings,
            textAccentLocs: another.textAccentLocs
        )
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
}
