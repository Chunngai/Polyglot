//
//  ListenAndRepeatPracticeView.swift
//  Polyglot
//
//  Created by Ho on 2/7/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class ListenAndRepeatPracticeView: PracticeViewWithNewWordAddingTextView {
    
    var practice: ListeningPracticeProducer.Item!
    
    var matchedClozeRanges: Set<NSRange> = []
    
    // MARK: - Init
    
    init(frame: CGRect = .zero, practice: ListeningPracticeProducer.Item!) {
        super.init(frame: frame)
        
        self.practice = practice
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func updateViews() {
        super.updateViews()
        
        let attributedText = NSMutableAttributedString(
            string: practice.text,
            attributes: Attributes.leftAlignedLongTextAttributes
        )
        for clozeRange in practice.clozeRanges {
            attributedText.setTextColor(
                for: clozeRange,
                with: Colors.clozeMaskColor
            )
            attributedText.setBackgroundColor(
                for: clozeRange,
                with: Colors.clozeMaskColor
            )
        }
        textView.attributedText = attributedText
    }
}



extension ListenAndRepeatPracticeView: ListeningPracticeViewDelegate {
    
    func submit() {
        
    }
    
    func updateViewsAfterSubmission() {
        let unmatchedClozeRanges = Set(practice.clozeRanges).subtracting(matchedClozeRanges)
        
        let newAttributes = NSMutableAttributedString(attributedString: textView.attributedText!)
        for clozeRange in unmatchedClozeRanges {
            newAttributes.setTextColor(
                for: clozeRange,
                with: Colors.strongIncorrectColor
            )
            newAttributes.setBackgroundColor(
                for: clozeRange,
                with: mainView.backgroundColor!
            )
        }
        textView.attributedText = newAttributes
        
        displayTranslation()
    }
}

extension ListenAndRepeatPracticeView: ListeningPracticeViewControllerDelegate {
    
    func languageSpecificProcess(for text: String) -> String {
        var text = text
        if practice.textLang == LangCode.ja {
            text = convertJapaneseToRomaji(text: text)
        }
        if practice.textLang == LangCode.en {
            text = convertUSSpellingToUKSpelling(text: text)
        }
        return text
    }
    
    // MARK: - ListeningPracticeViewController Delegate
    
    func processRecognizedText(text: String) {  // TODO: - May consume too much resource. Improve here.
        var tokens = text.tokenized(with: Variables.tokenizerOfLang())  // TODO: - Provice textLang for the tokenizer.
        
        let newAttributes = NSMutableAttributedString(attributedString: textView.attributedText!)
        for (clozeIndex, clozeRange) in practice.clozeRanges.enumerated() {
            if matchedClozeRanges.contains(clozeRange) {
                continue
            }
            
            var clozeToken = (textView.text! as NSString).substring(with: clozeRange)
            clozeToken = languageSpecificProcess(for: clozeToken)
            
            // Bi-gram.
            var previousClozeToken: String?
            var previousClozeRange: NSRange?
            let previousClozeIndex: Int = clozeIndex - 1
            if previousClozeIndex >= 0 {
                previousClozeRange = practice.clozeRanges[previousClozeIndex]
                previousClozeToken = (textView.text! as NSString).substring(with: previousClozeRange!)
                previousClozeToken = languageSpecificProcess(for: previousClozeToken!)
            }
            
            for (tokenIndex, token) in tokens.enumerated() {
                var token = token
                token = languageSpecificProcess(for: token)
                
                // Bi-gram.
                var previousToken: String?
                let previousTokenIndex: Int = tokenIndex - 1
                if previousTokenIndex >= 0 {
                    previousToken = tokens[previousTokenIndex]
                    previousToken = languageSpecificProcess(for: previousToken!)
                }
                
                print("previousClozeToken:", previousClozeToken, "clozeToken:", clozeToken)
                print("previousToken:", previousToken, "token:", token)
                
                guard clozeToken.lowercased() == token.lowercased() else {
                    continue
                }
                guard let previousClozeToken = previousClozeToken,
                    let previousToken = previousToken,
                    previousClozeToken == previousToken else {
                    continue
                }
                print("previousClozeToken:", previousClozeToken, "clozeToken:", clozeToken)
                print("previousToken:", previousToken, "token:", token)
                newAttributes.setTextColor(
                    for: clozeRange,
                    with: Attributes.leftAlignedLongTextAttributes[.foregroundColor] as! UIColor
                )
                newAttributes.setBackgroundColor(
                    for: clozeRange,
                    with: mainView.backgroundColor!
                )
                matchedClozeRanges.insert(clozeRange)
                
                guard let previousClozeRange = previousClozeRange else {
                    continue
                }
                print("previousClozeToken:", previousClozeToken, "clozeToken:", clozeToken)
                print("previousToken:", previousToken, "token:", token)
                newAttributes.setTextColor(
                    for: previousClozeRange,
                    with: Attributes.leftAlignedLongTextAttributes[.foregroundColor] as! UIColor
                )
                newAttributes.setBackgroundColor(
                    for: previousClozeRange,
                    with: mainView.backgroundColor!
                )
                matchedClozeRanges.insert(previousClozeRange)
                
                print("hit")
                print()
            }
        }
        textView.attributedText = newAttributes
    }
    
}

extension ListenAndRepeatPracticeView {
    
    func displayTranslation() {  // TODO: - Merge with the translation counterpart.
        
        if let meaning = practice.meaning {
            let attributedText = NSMutableAttributedString(attributedString: textView.attributedText!)
            attributedText.append(NSAttributedString(
                string: "\n\n" + meaning,
                attributes: Attributes.leftAlignedLongTextAttributes
            ))
            textView.attributedText = attributedText
        } else {
            GoogleTranslator(
                srcLang: practice.textLang,
                trgLang: practice.meaningLang
            ).translate(query: practice.text) { (res) in
                var meaningToDisplay: String
                if let translation = res.first {
                    meaningToDisplay = "(\(Strings.machineTranslationToken)) \(translation)"
                } else {
                    meaningToDisplay = Strings.machineTranslationErrorToken
                }
                DispatchQueue.main.async {
                    let attributedText = NSMutableAttributedString(attributedString: self.textView.attributedText!)
                    attributedText.append(NSAttributedString(
                        string: "\n\n" + meaningToDisplay,
                        attributes: Attributes.leftAlignedLongTextAttributes
                    ))
                    self.textView.attributedText = attributedText
                }
            }
        }
        
        // Restore the highlights.
        textView.highlightAll()
    }
}
