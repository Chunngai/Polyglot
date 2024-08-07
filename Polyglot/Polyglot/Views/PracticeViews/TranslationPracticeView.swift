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
        existingPhraseRanges: [NSRange],
        existingPhraseMeanings: [String],
        totalRepetitions: Int,
        currentRepetition: Int
    ) {
        super.init(
            frame: frame,
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
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateViews() {
        super.updateViews()
        
        displayMeaning()
    }
    
    // MARK: - Methods from the Super Class
    
    override func displayMeaning() {
        let attributedText = NSMutableAttributedString(
            string: "",
            attributes: Attributes.leftAlignedLongTextAttributes
        )
        if isTextMachineTranslated {
            let iconRange = NSRange(
                location: attributedText.length,
                length: 2  // Icon + space.
            )
            unselectableRanges.append(iconRange)
                        
            let imageAttrString = makeImageAttributedString(with: Icons.googleTranslateIcon)
            attributedText.append(imageAttrString)
            attributedText.append(NSAttributedString(string: " "))
        }
        attributedText.append(NSAttributedString(string: meaning))
        attributedText.addAttributes(
            Attributes.leftAlignedLongTextAttributes,
            range: NSRange(
                location: 0,
                length: attributedText.length
            )
        )
        
        textView.attributedText = attributedText
    }
    
    override func displayText() {
        let attributedText = NSMutableAttributedString(attributedString: textView.attributedText!)
        attributedText.append(NSAttributedString(string: "\n"))
        if textSource == .chatGpt {
            let iconRange = NSRange(
                location: attributedText.length,
                length: 2  // Icon + space.
            )
            unselectableRanges.append(iconRange)
            
            let imageAttrString = makeImageAttributedString(with: Icons.chatgptIcon)
            attributedText.append(imageAttrString)
            attributedText.append(NSAttributedString(string: " "))
        }
        
        for i in 0..<existingPhraseRanges.count {
            existingPhraseRanges[i].location += attributedText.length
        }
        
        attributedText.append(NSAttributedString(string: text))
        attributedText.addAttributes(
            Attributes.leftAlignedLongTextAttributes,
            range: NSRange(
                location: 0,
                length: attributedText.length
            )
        )
        
        textView.attributedText = attributedText
    }
    
    override func submit() -> Any {
        return []
    }
    
    override func updateViewsAfterSubmission() {
        
        super.updateViewsAfterSubmission()
        
        displayText()
        highlightExistingPhrases(
            existingPhraseRanges: existingPhraseRanges,
            existingPhraseMeanings: existingPhraseMeanings
        )
    }

}
