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
    
    var practice: ListeningPracticeProducer.Item!
    
    var clozeBiGram2BiRanges: [BiGram: [BiRange]] = [:]  // A bi-gram may correspond to multiple bi-ranges.
    
    var matchedClozeRanges: Set<NSRange> = []
    var unmatchedClozeRanges: Set<NSRange> {
        Set(practice.clozeRanges).subtracting(matchedClozeRanges)
    }
    
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
    
    override func updateSetups() {
        super.updateSetups()
        
        clozeBiGram2BiRanges = generateBiGram2BiRanges(
            from: practice.clozeRanges,
            of: practice.text
        )
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
    
    func generateBiGram2BiRanges(from ranges: [NSRange], of text: String) -> [BiGram: [BiRange]] {
        guard ranges.count > 1 else {
            if ranges.count == 0 {
                return [BiGram(): []]
            } else {  // ranges.count == 1
                let range = ranges[0]
                let token = (text as NSString).substring(with: range)
                return [BiGram(leftToken: token): [BiRange(leftRange: range)]]
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
    
    func generateBiGrams(from tokens: [String]) -> Set<BiGram> {
        guard tokens.count > 1 else {
            if tokens.count == 0 {
                return [BiGram()]
            } else {  // tokens.count == 1
                return [BiGram(leftToken: tokens[0])]
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
    
    func preprocess(_ text: String) -> String {
        var text = text
        if practice.textLang == LangCode.ja {
            text = convertJapaneseToRomaji(text: text)
        }
        if practice.textLang == LangCode.en {
            text = convertUSSpellingToUKSpelling(text: text)
        }
        text = text.lowercased()
        return text
    }
    
    // MARK: - ListeningPracticeViewController Delegate
    
    func processRecognizedSpeech(_ text: String) {
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
