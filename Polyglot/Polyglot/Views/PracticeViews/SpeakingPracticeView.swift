//
//  TranslationPracticeView.swift
//  Polyglot
//
//  Created by Sola on 2023/1/9.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class TranslationPracticeView: TextMeaningPracticeView {
    
    // MARK: - Init
    
    override init(
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
            textAccentLocs: textAccentLocs
        )
        
        upperString = meaning
        lowerString = text
        if isTextMachineTranslated {
            upperIcon = translatorIcon
        }
        if textSource == .chatGpt {
            lowerIcon = Icons.chatgptIcon
        }
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods from the Super Class
    
    override func displayUpper() {
        super.displayUpper()
        
        textView.markAccents(at: textAccentLocs)
    }
    
    override func displayLower() {
        
        super.displayLower()
        
        let upperAttrStr = NSAttributedString(
            string: (self.upperIcon != nil ? "  " : "") + meaning + "\n" + (self.lowerIcon != nil ? "  " : ""),
            attributes: Attributes.leftAlignedLongTextAttributes
        )
        for i in 0..<existingPhraseRanges.count {
            existingPhraseRanges[i].location += upperAttrStr.length
        }
        for i in 0..<textAccentLocs.count {
            textAccentLocs[i] += upperAttrStr.length
        }
        
        textView.markAccents(at: textAccentLocs)
        
    }
    
    override func submit() -> Any {
        return []
    }
    
    override func updateViewsAfterSubmission() {
        
        super.updateViewsAfterSubmission()
        
        highlightExistingPhrases(
            existingPhraseRanges: existingPhraseRanges,
            existingPhraseMeanings: existingPhraseMeanings
        )
    }

}
