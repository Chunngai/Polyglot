//
//  TranslationPracticeViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/30.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class TranslationPracticeViewController: TextMeaningPracticeViewController {
    
    private lazy var practiceProducer: SpeakingPracticeProducer = SpeakingPracticeProducer(
        words: words,
        articles: articles
    )

    // MARK: - Init
    
    override func updateViews() {
        super.updateViews()
        
        promptLabel.numberOfLines = 1
        promptLabel.adjustsFontSizeToFitWidth = true
    }
    
    // MARK: - Methods from the Super Class
 
    override func makePrompt() -> String {
        Strings.interpretationPracticePrompt
    }
    
    override func makePracticeView() -> TextMeaningPracticeView {
        let practice = practiceProducer.currentPractice as! SpeakingPractice
        let practiceView = TranslationPracticeView(
            text: practice.text,
            meaning: practice.meaning,
            textLang: practice.textLang,
            meaningLang: practice.meaningLang,
            textSource: practice.textSource,
            isTextMachineTranslated: practice.isTextMachineTranslated,
            existingPhraseRanges: practice.existingPhraseRanges,
            existingPhraseMeanings: practice.existingPhraseMeanings
        )
        
        practiceView.speakButton.isHidden = true
        practiceView.listenButton.isHidden = true
        return practiceView
    }
    
}

extension TranslationPracticeViewController {
    
    // MARK: - Selectors
    
    @objc override func doneButtonTapped() {
        super.doneButtonTapped()
        
        if let practiceView = practiceView as? TextMeaningPracticeView {
            practiceView.updateViewsAfterSubmission()
        }
    }
    
    @objc override func nextButtonTapped() {
        if let practiceView = practiceView as? TextMeaningPracticeView {
            let newWords = newWords(
                from: practiceView.newWordsInfo,
                of: practiceView.textSource
            )
            save(newWords: newWords)
            updateExistingRangesAndMeaningsOfRemainingPractices(
                from: practiceProducer,
                with: newWords
            )
            
            if practiceView.shouldReinforce {
                practiceProducer.reinforce()
            }
        }
        
        guard !shouldFinishPracticing else {
            practiceMetaData["recentTranslationPracticeDate"] = Date().repr(of: Date.defaultDateAndTimeFormat)
            self.stopPracticing()
            return
        }
        super.nextButtonTapped()
        practiceProducer.next()
        updatePracticeView()
    }
}

extension TranslationPracticeViewController {
    
    override func stopPracticing() {
        super.stopPracticing()
    }
    
}
