//
//  ReadingPracticeViewController.swift
//  Polyglot
//
//  Created by Ho on 8/25/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class ReadingPracticeViewController: TextMeaningPracticeViewController {
    
    var selectedArticle: Article?

    private lazy var practiceProducer: ReadingPracticeProducer = {
        let producer = ReadingPracticeProducer(words: words, articles: articles)
        producer.selectedArticle = selectedArticle
        if selectedArticle != nil {
            producer.practiceList = []
        }
        return producer
    }()

    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        label.textColor = .secondaryLabel
        label.isHidden = true
        return label
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Init

    override func updateViews() {
        super.updateViews()
        promptLabel.numberOfLines = 1
        promptLabel.adjustsFontSizeToFitWidth = true
        mainView.addSubview(progressLabel)
        mainView.addSubview(loadingIndicator)
    }

    override func updateLayouts() {
        super.updateLayouts()
        progressLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(doneButton)
        }
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    // MARK: - Methods from the Super Class

    override func updatePracticeView() {
        if selectedArticle != nil && practiceProducer.practiceList.isEmpty {
            loadingIndicator.startAnimating()
            doneButton.isHidden = true
            nextButton.isHidden = true
            let superUpdate = super.updatePracticeView
            DispatchQueue.global(qos: .userInitiated).async {
                _ = self.practiceProducer.currentPractice
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.doneButton.isHidden = false
                    superUpdate()
                    self.mainView.bringSubviewToFront(self.progressLabel)
                }
            }
            return
        }
        super.updatePracticeView()
        mainView.bringSubviewToFront(progressLabel)
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
            textAccentLocs: practice.textAccentLocs,
            verbAspectAnnotations: practice.verbAspectAnnotations
        )
        practiceView.controlsView.isHidden = true
        updateProgressPrompt(for: practice)
        return practiceView
    }

    private func updateProgressPrompt(for practice: ReadingPractice) {
        guard let article = selectedArticle,
              case let .article(_, paragraphId, _) = practice.textSource,
              let paragraphId = paragraphId,
              let paraIndex = article.paras.firstIndex(where: { $0.id == paragraphId })
        else {
            progressLabel.isHidden = true
            return
        }
        progressLabel.text = "\(paraIndex + 1) / \(article.paras.count)"
        progressLabel.isHidden = false
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
                from: practiceView.textView.wordsInfo,
                of: practiceView.textSource
            )
            add(newWords: newWords)
            updateExistingRangesAndMeaningsOfRemainingPractices(
                from: practiceProducer,
                with: newWords
            )
            
            generateWordPractices(from: practiceView.textView.reinforcementWordsInfo)
            
            if practiceView.shouldReinforce {
                practiceProducer.reinforce(for: 1)
            }
        }
        // Should be called after any code that will access practiceProducer.currentPractice, as this line of code will delete the current practice.
        practiceProducer.updatePracticeRepetitions()

        guard !shouldFinishPracticing else {
            practiceMetaData["recentReadingPracticeDate"] = Date().repr(of: Date.defaultDateAndTimeFormat)
            stopPracticing()
            return
        }
        if selectedArticle != nil && practiceProducer.isArticleComplete && practiceProducer.practiceList.isEmpty {
            stopPracticing()
            return
        }
        super.nextButtonTapped()
        practiceProducer.next()
        updatePracticeView()
    }
}

extension ReadingPracticeViewController {
    
    @objc override func appMovedToBackground() {
        super.appMovedToBackground()
        practiceProducer.cacheCurrentProgress()
    }

    override func stopPracticing() {
        practiceProducer.cacheCurrentProgress()
        practiceProducer.cache()
        super.stopPracticing()
    }
    
}
