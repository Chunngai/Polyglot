//
//  VideoShadowingPracticeViewController.swift
//  Polyglot
//
//  Created by Ho on 4/30/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import UIKit

class VideoShadowingPracticeViewController: TextMeaningPracticeViewController {

    private lazy var practiceProducer: VideoShadowingPracticeProducer = VideoShadowingPracticeProducer(
        words: words,
        articles: articles
    )
    
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
    
    override func timingBarTimeUp(timingBar: TimingBar) {
        
        super.timingBarTimeUp(timingBar: timingBar)
        self.stopPracticing()
        
        return
    
    }
    
    override func stopPracticing() {
        
        if let practiceView = practiceView as? TextMeaningPracticeView {
            
            let newWords = newWords(
                from: practiceView.textView.wordsInfo,
                of: practiceView.textSource
            )
            add(newWords: newWords)
            
            generateWordPractices(from: practiceView.textView.reinforcementWordsInfo)
            
        }
        
        practiceMetaData["recentVideoShadowingPracticeDate"] = Date().repr(of: Date.defaultDateAndTimeFormat)
        
        if let practiceView = practiceView as? VideoShadowingPracticeView {
            practiceView.currentTimestamp { timestamp in
                if timestamp != 0 {
                    self.practiceProducer.cache(timestamp: timestamp)
                    // IMPORTANT TO UPDATE THE META DATA!
                    self.practiceMetaData = VideoShadowingPracticeProducer.loadMetaData(for: LangCode.currentLanguage)
                }
            }
        }
        
        super.stopPracticing()
        
    }
    
}
