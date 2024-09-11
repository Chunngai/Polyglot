//
//  ReadingPracticeViewController.swift
//  Polyglot
//
//  Created by Ho on 8/25/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class ReadingPracticeViewController: TextMeaningPracticeViewController {
    
    private lazy var practiceProducer: ReadingPracticeProducer = ReadingPracticeProducer(
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
        Strings.readingPracticePrompt
    }
    
    override func makePracticeView() -> TextMeaningPracticeView {
        let practice = practiceProducer.currentPractice as! ReadingPractice
        let practiceView = ReadingPracticeView(
            text: practice.text,
            meaning: practice.meaning,
            textLang: practice.textLang,
            meaningLang: practice.meaningLang,
            textSource: practice.textSource,
            isTextMachineTranslated: practice.isTextMachineTranslated,
            machineTranslatorType: practice.machineTranslatorType,
            existingPhraseRanges: practice.existingPhraseRanges,
            existingPhraseMeanings: practice.existingPhraseMeanings,
            totalRepetitions: practice.totalRepetitions,
            currentRepetition: practice.currentRepetition,
            textAccentLocs: practice.textAccentLocs
        )
        
        practiceView.speakButton.isHidden = true
        practiceView.listenButton.isHidden = true
        return practiceView
    }
    
}

extension ReadingPracticeViewController {
    
    // MARK: - Selectors
    
    @objc override func doneButtonTapped() {
        super.doneButtonTapped()
        
        if let practiceView = practiceView as? TextMeaningPracticeView {
            practiceView.updateViewsAfterSubmission()  // TODO: - accept the submitted practice as input.
        }
    }
    
    @objc override func nextButtonTapped() {
        if let practiceView = practiceView as? TextMeaningPracticeView {
            let newWords = newWords(
                from: practiceView.wordsInfo,
                of: practiceView.textSource
            )
            add(newWords: newWords)
            updateExistingRangesAndMeaningsOfRemainingPractices(
                from: practiceProducer,
                with: newWords
            )
            
        }
        // Should be called after any code that will access practiceProducer.currentPractice, as this line of code will delete the current practice.
        practiceProducer.updatePracticeRepetitions()
        
        guard !shouldFinishPracticing else {
            practiceMetaData["recentReadingPracticeDate"] = Date().repr(of: Date.defaultDateAndTimeFormat)
            stopPracticing()
            return
        }
        super.nextButtonTapped()
        practiceProducer.next()
        updatePracticeView()
    }
}

extension ReadingPracticeViewController {
    
    override func stopPracticing() {
        practiceProducer.cache()  // Finished all / tapped the cancel button.
        super.stopPracticing()
    }
    
}
