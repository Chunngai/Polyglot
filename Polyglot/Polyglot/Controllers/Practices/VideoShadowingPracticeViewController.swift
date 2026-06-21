//
//  VideoShadowingPracticeViewController.swift
//  Polyglot
//
//  Created by Ho on 4/30/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import UIKit

class VideoShadowingPracticeViewController: TextMeaningPracticeViewController {

    var selectedArticle: Article?

    private lazy var practiceProducer: VideoShadowingPracticeProducer = {
        let producer = VideoShadowingPracticeProducer(words: words, articles: articles)
        producer.selectedArticle = selectedArticle
        return producer
    }()

    // MARK: - Init

    override func updateViews() {
        super.updateViews()

        doneButton.isHidden = true
        nextButton.isHidden = true
    }

    // MARK: - Methods from the Super Class

    override func makePracticeView() -> VideoShadowingPracticeView {

        let currentPractice = practiceProducer.currentPractice as! VideoShadowingPractice
        let practiceView = VideoShadowingPracticeView(
            text: currentPractice.text,
            meaning: currentPractice.meaning,
            textLang: currentPractice.textLang,
            meaningLang: currentPractice.meaningLang,
            textSource: currentPractice.textSource,
            isTextMachineTranslated: currentPractice.isTextMachineTranslated,
            machineTranslatorType: currentPractice.machineTranslatorType,
            existingPhraseRanges: currentPractice.existingPhraseRanges,
            existingPhraseMeanings: currentPractice.existingPhraseMeanings,
            textAccentLocs: currentPractice.textAccentLocs,
            videoURLString: currentPractice.videoURLString,
            videoID: currentPractice.videoID,
            startingTimestamp: currentPractice.startingTimestamp,
            captionEvents: currentPractice.captionEvents
        )

        practiceView.speakButton.isHidden = true
        practiceView.listenButton.isHidden = true
        practiceView.repetitionsLabel.isHidden = true
        return practiceView
    }

}

extension VideoShadowingPracticeViewController {

    override func stopPracticing() {
        guard let practiceView = practiceView as? VideoShadowingPracticeView else {
            navigationController?.dismiss(animated: true)
            return
        }
        practiceView.currentTimestamp { [weak self] timestamp in
            guard let self = self else { return }
            if timestamp != 0 {
                self.practiceProducer.cache(timestamp: timestamp)
                self.practiceMetaData = VideoShadowingPracticeProducer.loadMetaData(for: LangCode.currentLanguage)
            }
            DispatchQueue.main.async {
                self.navigationController?.dismiss(animated: true)
            }
        }
    }

}

extension VideoShadowingPracticeViewController {

    override func timingBarTimeUp(timingBar: TimingBar) {

        super.timingBarTimeUp(timingBar: timingBar)
//        self.stopPracticing()

        if let practiceView = practiceView as? VideoShadowingPracticeView {

            practiceView.youtubeWebView.evaluateJavaScript("pause()") { result, error in
                if let error = error {
                    print("JavaScript执行错误: \(error)")
                }
            }
            practiceView.disablePlaying()
            practiceView.markTextButton.isHidden = true
            practiceView.isMarkingText = true

            practiceView.currentTimestamp { timestamp in
                if timestamp != 0 {
                    self.practiceProducer.cache(timestamp: timestamp)
                    // IMPORTANT TO UPDATE THE META DATA!
                    self.practiceMetaData = VideoShadowingPracticeProducer.loadMetaData(for: LangCode.currentLanguage)
                }
            }

        }

        nextButton.isHidden = false

        return

    }

    @objc override func nextButtonTapped() {
        super.doneButtonTapped()

        if let practiceView = practiceView as? TextMeaningPracticeView {

            let newWords = newWords(
                from: practiceView.textView.wordsInfo,
                of: practiceView.textSource
            )
            add(newWords: newWords)

            generateWordPractices(from: practiceView.textView.reinforcementWordsInfo)

        }

        practiceMetaData["recentVideoShadowingPracticeDate"] = Date().repr(of: Date.defaultDateAndTimeFormat)

        self.stopPracticing()
    }

}
