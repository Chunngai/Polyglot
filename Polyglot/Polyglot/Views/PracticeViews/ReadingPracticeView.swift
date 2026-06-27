//
//  ReadingPracticeView.swift
//  Polyglot
//
//  Created by Ho on 8/25/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation

class ReadingPracticeView: TextMeaningPracticeView {
    
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
        totalRepetitions: Int,
        currentRepetition: Int,
        textAccentLocs: [Int],
        verbAspectAnnotations: [VerbAspectAnnotation] = []
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
            verbAspectAnnotations: verbAspectAnnotations,
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
    
    override func updateViews() {
        super.updateViews()
        
        self.repetitionsLabel.isHidden = true
    }
    
    // MARK: - Methods from the Super Class
    
    override func submit() -> Any {
        return []
    }
    
    override func updateViewsAfterSubmission() {
        
        super.updateViewsAfterSubmission()
        
        highlightExistingPhrases(
            existingPhraseRanges: existingPhraseRanges,
            existingPhraseMeanings: existingPhraseMeanings
        )
        highlightExistingReinforcementWords()
    }
    
    override func displayUpper() {
        super.displayUpper()

        markAccents(at: textAccentLocs)
        markVerbAspects(at: verbAspectAnnotations)
    }

    override func displayLower() {
        super.displayLower()
    }
    
}

extension ReadingPracticeView {
        
    override func completedContentGeneration(wordMarkingTextView: WordMarkingTextView, content: String?) {
        
        super.completedContentGeneration(
            wordMarkingTextView: wordMarkingTextView,
            content: content
        )
        repetitionsLabel.isHidden = true
        
    }
    
}
