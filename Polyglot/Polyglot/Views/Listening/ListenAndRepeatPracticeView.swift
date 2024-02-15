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

class ListenAndRepeatPracticeView: PracticeViewWithNewWordAddingTextView {
    
    var text: String!
    var meaning: String!
    var textLang: LangCode!
    var meaningLang: LangCode!
    var textSource: TextSource!
    var isTextMachineTranslated: Bool!
    var clozeRanges: [NSRange]!
    var existingPhraseRanges: [NSRange]!
    var existingPhraseMeanings: [String]!
    
    private var clozeBiGram2BiRanges: [BiGram: [BiRange]] = [:]  // A bi-gram may correspond to multiple bi-ranges.
    
    private var matchedClozeRanges: Set<NSRange> = []
    private var unmatchedClozeRanges: Set<NSRange> {
        Set(clozeRanges).subtracting(matchedClozeRanges)
    }
    
    private var shouldProcessRecognizedSpeech: Bool = true
    
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
        super.init(frame: frame)
        
        self.text = text
        self.meaning = meaning
        self.textLang = textLang
        self.meaningLang = meaningLang
        self.textSource = textSource
        self.isTextMachineTranslated = isTextMachineTranslated
        self.clozeRanges = clozeRanges
        self.existingPhraseRanges = existingPhraseRanges
        self.existingPhraseMeanings = existingPhraseMeanings
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func updateSetups() {
        super.updateSetups()
        
        clozeBiGram2BiRanges = generateBiGram2BiRanges(
            from: clozeRanges,
            of: text
        )
    }
    
    override func updateViews() {
        super.updateViews()
        
        displayText()
        makeClozes()
    }
    
    override func displayText() {
        let attributedText = NSMutableAttributedString(string: "")
        if textSource == .chatGpt {
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
                length: attributedText.string.count
            )
        )
        
        textView.attributedText = attributedText
    }
    
    override func displayMeaning() {  // TODO: - Merge with the translation counterpart.
        let attributedText = NSMutableAttributedString(attributedString: textView.attributedText!)

        attributedText.append(NSAttributedString(string: "\n"))
        if isTextMachineTranslated {
            let imageAttrString = makeImageAttributedString(with: Icons.googleTranslateIcon)
            attributedText.append(imageAttrString)
            attributedText.append(NSAttributedString(
                string: " ",
                attributes: Attributes.leftAlignedLongTextAttributes
            ))
        }
        attributedText.append(NSAttributedString(
            string: meaning,
            attributes: Attributes.leftAlignedLongTextAttributes
        ))
        attributedText.addAttributes(
            Attributes.leftAlignedLongTextAttributes,
            range: NSRange(
                location: 0,
                length: attributedText.string.count
            )
        )
        
        textView.attributedText = attributedText
    }
}

extension ListenAndRepeatPracticeView: ListeningPracticeViewDelegate {
    
    func submit() -> Any {
        return Array<NSRange>(matchedClozeRanges)
    }
    
    func updateViewsAfterSubmission() {
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
    
    private func generateBiGram2BiRanges(from ranges: [NSRange], of text: String) -> [BiGram: [BiRange]] {
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
        
        let speechTokens = text.tokenized(with: LangCode.currentLanguage.wordTokenizer)
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
