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
        let practice = practiceProducer.currentPractice
        return TranslationPracticeView(
            text: practice.text,
            meaning: practice.meaning,
            textLang: practice.textLang,
            meaningLang: practice.meaningLang,
            textSource: practice.textSource,
            isTextMachineTranslated: practice.isTextMachineTranslated,
            existingPhraseRanges: practice.existingPhraseRanges,
            existingPhraseMeanings: practice.existingPhraseMeanings
        )
    }
    
}

extension TranslationPracticeViewController {
    
    // MARK: - Selectors
    
    @objc override func cancelButtonTapped() {
        super.cancelButtonTapped()
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc override func doneButtonTapped() {
        super.doneButtonTapped()
        (practiceView as! TextMeaningPracticeView).updateViewsAfterSubmission()
    }
    
    @objc override func nextButtonTapped() {
        super.nextButtonTapped()
        
        updateAllNewWordsInfo(with: practiceView as! TextMeaningPracticeView)
        practiceProducer.next()
        updatePracticeView()
    }
}
