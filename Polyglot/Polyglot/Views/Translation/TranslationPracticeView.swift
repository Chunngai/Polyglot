//
//  TranslationPracticeView.swift
//  Polyglot
//
//  Created by Sola on 2023/1/9.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class TranslationPracticeView: PracticeViewWithNewWordAddingTextView {
    
    var text: String!
    var meaning: String!
    var textLang: LangCode!
    var meaningLang: LangCode!
    var textSource: TextSource!
    var isTextMachineTranslated: Bool!
    var existingPhraseRanges: [NSRange]!
    var existingPhraseMeanings: [String]!
    
    // MARK: - Init
    
    init(
        frame: CGRect = .zero,
        text: String,
        meaning: String,
        textLang: LangCode,
        meaningLang: LangCode,
        textSource: TextSource,
        isTextMachineTranslated: Bool,
        existingPhraseRanges: [NSRange],
        existingPhraseMeanings: [String]
    ) {
        super.init(frame: frame)
        
        self.text = text
        self.meaning = meaning
        self.textLang = textLang
        self.meaningLang = meaningLang
        self.textSource = textSource
        self.isTextMachineTranslated = isTextMachineTranslated
        self.existingPhraseRanges = existingPhraseRanges
        self.existingPhraseMeanings = existingPhraseMeanings
        
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
    
    override func displayMeaning() {
        let attributedText = NSMutableAttributedString(
            string: "",
            attributes: Attributes.leftAlignedLongTextAttributes
        )
        if isTextMachineTranslated {
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
    
}

extension TranslationPracticeView {
  
    func updateViewsAfterSubmission() {
        displayText()
        highlightExistingPhrases(
            existingPhraseRanges: existingPhraseRanges,
            existingPhraseMeanings: existingPhraseMeanings
        )
    }
    
}
