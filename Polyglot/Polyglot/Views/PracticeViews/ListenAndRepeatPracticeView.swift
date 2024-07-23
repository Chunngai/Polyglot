//
//  ListenAndRepeatPracticeView.swift
//  Polyglot
//
//  Created by Ho on 2/7/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

struct BiGram: Codable, Hashable {
    var leftToken: String = ""
    var rightToken: String = ""
}

struct BiRange: Codable {
    var leftRange: NSRange = NSRange()
    var rightRange: NSRange = NSRange()
}

class ListenAndRepeatPracticeView: TextMeaningPracticeView {
    
    var clozeRanges: [NSRange]!
    private var matchedClozeRanges: Set<NSRange> = []
    private var unmatchedClozeRanges: Set<NSRange> {
        Set(clozeRanges).subtracting(matchedClozeRanges)
    }
    
    private var clozeBiGram2BiRanges: [BiGram: [BiRange]] = [:]  // A bi-gram may correspond to multiple bi-ranges.
    
    private var shouldProcessRecognizedSpeech: Bool = true
    
    // MARK: - Controllers
    
    var delegate: ListeningPracticeViewController!
    
    // MARK: - Init
    
    init(
        frame: CGRect = .zero,
        text: String,
        meaning: String,
        textLang: LangCode,
        meaningLang: LangCode,
        textSource: TextSource,
        isTextMachineTranslated: Bool,
        clozeRanges: [NSRange],
        existingPhraseRanges: [NSRange],
        existingPhraseMeanings: [String]
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
            existingPhraseMeanings: existingPhraseMeanings
        )
        
        self.clozeRanges = clozeRanges
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func updateSetups() {
        super.updateSetups()
        
        var updatedText = text ?? ""
        if LangCode.currentLanguage == .ko {  // Handle inconsistent word splitting. E.g., 인공지능/인공 지능.
            let koTokens = text.tokenized(with: LangCode.currentLanguage.wordTokenizer)
            for i in 0..<koTokens.count - 1 {
                updatedText += " " + koTokens[i] + koTokens[i + 1]
            }
        }
        clozeBiGram2BiRanges = generateBiGram2BiRanges(
//            from: clozeRanges,
            for: updatedText
//            of: updatedText
        )
    }
    
    override func updateViews() {
        super.updateViews()
        
        displayText()
        makeClozes()
    }
    
    // MARK: - Methods from the Super Class
    
    override func displayText() {
        let attributedText = NSMutableAttributedString(string: "")
        if textSource == .chatGpt {
            let iconRange = NSRange(
                location: attributedText.length,
                length: 2  // Icon + space.
            )
            unselectableRanges.append(iconRange)
            
            let imageAttrString = makeImageAttributedString(with: Icons.chatgptIcon)
            attributedText.append(imageAttrString)
            attributedText.append(NSAttributedString(string: " "))
            
            for i in 0..<clozeRanges.count {
                clozeRanges[i].location += 2  // One for the icon and one for the space.
            }
            for (biGram, biRanges) in clozeBiGram2BiRanges {
                for i in 0..<biRanges.count {
                    clozeBiGram2BiRanges[biGram]![i].leftRange.location += 2
                    clozeBiGram2BiRanges[biGram]![i].rightRange.location += 2
                }
            }
            for i in 0..<existingPhraseRanges.count {
                existingPhraseRanges[i].location += 2
            }
        }
        attributedText.append(NSAttributedString(string: text))
        // Without this the text attributes are cleared after attaching the icon.
        attributedText.addAttributes(
            Attributes.leftAlignedLongTextAttributes,
            range: NSRange(
                location: 0,
                length: attributedText.length
            )
        )
        
        textView.attributedText = attributedText
    }
    
    override func displayMeaning() {  // TODO: - Merge with the translation counterpart.
        let attributedText = NSMutableAttributedString(attributedString: textView.attributedText!)

        attributedText.append(NSAttributedString(string: "\n"))
        if isTextMachineTranslated {
            let iconRange = NSRange(
                location: attributedText.length,
                length: 2  // Icon + space.
            )
            unselectableRanges.append(iconRange)
            
            let imageAttrString = makeImageAttributedString(with: Icons.googleTranslateIcon)
            attributedText.append(imageAttrString)
            attributedText.append(NSAttributedString(string: " "))
            attributedText.addAttributes(
                Attributes.leftAlignedLongTextAttributes,
                range: NSRange(
                    location: attributedText.length - 2,
                    length: 2
                )
            )
        }
        attributedText.append(NSAttributedString(
            string: meaning,
            attributes: Attributes.leftAlignedLongTextAttributes
        ))
        
        textView.attributedText = attributedText
    }
    
    override func submit() -> Any {
        return Array<NSRange>(matchedClozeRanges)
    }
    
    override func updateViewsAfterSubmission() {
        
        super.updateViewsAfterSubmission()
        
        // If the practice is submitted without turning off the mic,
        // the processRecognizedSpeech() func will still be called where
        // recognized clozes are set with background colors,
        // leading to invalid new phrase highlighting.
        shouldProcessRecognizedSpeech = false
        
        displayUnmatchedText()
        displayMeaning()
        highlightExistingPhrases(
            existingPhraseRanges: existingPhraseRanges,
            existingPhraseMeanings: existingPhraseMeanings
        )
    }
}

extension ListenAndRepeatPracticeView: ListeningPracticeViewControllerDelegate {
    
//    private func generateBiGram2BiRanges(from ranges: [NSRange], of text: String) -> [BiGram: [BiRange]] {
    private func generateBiGram2BiRanges(for text: String) -> [BiGram: [BiRange]] {
        let ranges = text.tokenRanges
        guard ranges.count > 1 else {
            if ranges.count == 0 {
                return [BiGram(): []]
            } else {  // ranges.count == 1
                let range = ranges[0]
                let token = (text as NSString).substring(with: range)
                return [BiGram(leftToken: preprocess(token)): [BiRange(leftRange: range)]]
            }
        }
        
        var biGram2BiRanges: [BiGram: [BiRange]] = [:]
        for i in 0..<ranges.count - 1 {
            let leftRange = ranges[i]
            let rightRange = ranges[i + 1]
            guard clozeRanges.contains(leftRange) || clozeRanges.contains(rightRange) else {
                continue
            }
            
            var leftToken = (text as NSString).substring(with: leftRange)
            leftToken = preprocess(leftToken)
            var rightToken = (text as NSString).substring(with: rightRange)
            rightToken = preprocess(rightToken)
            
            let biGram = BiGram(
                leftToken: leftToken,
                rightToken: rightToken
            )
            let biRange = BiRange(
                leftRange: leftRange,
                rightRange: rightRange
            )
            
            if biGram2BiRanges.keys.contains(biGram) {
                biGram2BiRanges[biGram]!.append(biRange)
            } else {
                biGram2BiRanges[biGram] = [biRange]
            }
        }
        
        return biGram2BiRanges
    }
    
    private func generateBiGrams(from tokens: [String]) -> Set<BiGram> {
        guard tokens.count > 1 else {
            if tokens.count == 0 {
                return [BiGram()]
            } else {  // tokens.count == 1
                return [BiGram(leftToken: preprocess(tokens[0]))]
            }
        }
        
        var biGrams: Set<BiGram> = []
        for i in 0..<tokens.count - 1 {
            var leftToken = tokens[i]
            leftToken = preprocess(leftToken)
            var rightToken = tokens[i + 1]
            rightToken = preprocess(rightToken)
            
            let biGram = BiGram(
                leftToken: leftToken,
                rightToken: rightToken
            )
            biGrams.insert(biGram)
        }
        
        return biGrams
    }
    
    private func preprocess(_ text: String) -> String {
        var text = text
        if textLang == LangCode.ja {
            text = convertJapaneseToRomaji(text: text)
        }
        if textLang == LangCode.en {
            text = convertUSSpellingToUKSpelling(text: text)
        }
        text = text.lowercased()
        return text
    }
    
    // MARK: - ListeningPracticeViewController Delegate
    
    func processRecognizedSpeech(_ text: String) {
        guard shouldProcessRecognizedSpeech else {
            return
        }
        
        var speechTokens = text.tokenized(with: LangCode.currentLanguage.wordTokenizer)
        if LangCode.currentLanguage == .ko {  // Handle inconsistent word splitting.
            let nKoTokens = speechTokens.count
            for i in 0..<nKoTokens - 1 {
                speechTokens.append(speechTokens[i] + speechTokens[i + 1])
            }
        }
        let speechBiGrams = generateBiGrams(from: speechTokens)
        
        let newAttributes = NSMutableAttributedString(attributedString: textView.attributedText!)
        let biGramOverlaps = Set(clozeBiGram2BiRanges.keys).intersection(speechBiGrams)
        for biGramOverlap in biGramOverlaps {
            guard let biRangeOverlaps = clozeBiGram2BiRanges[biGramOverlap] else {
                continue
            }
            for biRangeOverlap in biRangeOverlaps {
                for range in [biRangeOverlap.leftRange, biRangeOverlap.rightRange] {
                    newAttributes.setTextColor(
                        for: range,
                        with: Attributes.leftAlignedLongTextAttributes[.foregroundColor] as! UIColor
                    )
                    newAttributes.setBackgroundColor(
                        for: range,
                        with: mainView.backgroundColor!
                    )
                    matchedClozeRanges.insert(range)
                }
            }
        }
        textView.attributedText = newAttributes
        
        if matchedClozeRanges.count == clozeRanges.count {
            delegate.canSubmit()
        }
    }
    
}

extension ListenAndRepeatPracticeView {
    
    private func makeClozes() {
        let attributedText = NSMutableAttributedString(attributedString: textView.attributedText!)
        for clozeRange in clozeRanges {
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
    
    private func displayUnmatchedText() {
        let newAttributes = NSMutableAttributedString(attributedString: textView.attributedText!)
        for clozeRange in unmatchedClozeRanges {
            newAttributes.setTextColor(
                for: clozeRange,
                with: Colors.incorrectColor
            )
            newAttributes.setBackgroundColor(
                for: clozeRange,
                with: mainView.backgroundColor!
            )
        }
        textView.attributedText = newAttributes
    }
}

protocol ListenAndRepeatPracticeViewDelegate {
    
    func canSubmit()
    
}
