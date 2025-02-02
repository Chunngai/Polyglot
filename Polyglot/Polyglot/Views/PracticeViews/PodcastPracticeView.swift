//
//  PodcastPracticeView.swift
//  Polyglot
//
//  Created by Ho on 1/19/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import Foundation

class PodcastPracticeView: TextMeaningPracticeView {
    
    // MARK: - Init
    
    init(
        frame: CGRect = .zero,
        text: String,
        meaning: String,
        textLang: LangCode,
        meaningLang: LangCode,
        textSource: TextSource,
        isTextMachineTranslated: Bool,
        machineTranslatorType: MachineTranslatorType,
        existingPhraseRanges: [NSRange],
        existingPhraseMeanings: [String],
        totalRepetitions: Int = 1,
        currentRepetition: Int = 1,
        textAccentLocs: [Int]
    ) {
        super.init(
            frame: frame,
            text: text,
            meaning: meaning,
            textLang: textLang,
            meaningLang: meaningLang,
            textSource: textSource,
            isTextMachineTranslated: isTextMachineTranslated,
            machineTranslatorType: machineTranslatorType,
            existingPhraseRanges: existingPhraseRanges,
            existingPhraseMeanings: existingPhraseMeanings,
            totalRepetitions: totalRepetitions,
            currentRepetition: currentRepetition,
            textAccentLocs: textAccentLocs,
            repetitionIncrement: 1
        )
        
        upperString = text
        lowerString = meaning
        if textSource == .chatGpt {
            upperIcon = Icons.chatgptIcon
        }
        if isTextMachineTranslated {
            lowerIcon = translatorIcon
        }
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateSetups() {
        super.updateSetups()
        
        textView.isUserInteractionEnabled = false
    }
    
    override func updateViews() {
        super.updateViews()
        displayLower()        
    }
    
    // MARK: - Methods from the Super Class
    
    override func displayUpper() {
        super.displayUpper()
        
        markAccents(at: textAccentLocs)
    }

    override func displayLower() {
        super.displayLower()
        
        markAccents(at: textAccentLocs)
    }
    
}
