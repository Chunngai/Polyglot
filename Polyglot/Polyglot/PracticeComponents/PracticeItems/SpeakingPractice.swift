//
//  TranslationPractice.swift
//  Polyglot
//
//  Created by Ho on 2/15/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation

class SpeakingPractice: TextMeaningPractice {
    
    convenience init(from another: SpeakingPractice) {
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
            totalRepetitions: another.totalRepetitions,
            currentRepetition: another.currentRepetition
        )
    }
    
}
