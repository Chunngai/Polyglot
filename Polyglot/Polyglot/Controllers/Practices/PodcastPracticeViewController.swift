//
//  PodcastPracticeViewController.swift
//  Polyglot
//
//  Created by Ho on 1/19/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import UIKit
import AVFAudio

class PodcastPracticeViewController: TextMeaningPracticeViewController {
    
    private lazy var practiceProducer: PodcastPracticeProducer = PodcastPracticeProducer(
        words: words,
        articles: articles
    )
        
    var speechSynthesizer: AVSpeechSynthesizer!

    var slowSpeedUtterance: AVSpeechUtterance!
    var normalSpeedUtterance: AVSpeechUtterance!

    var synthesizingTimes: Int? = 0
    
    // MARK: - Init
    
    override func updateSetups() {
        super.updateSetups()
        
//        timingBar.isHidden = true
//        timingBar.stop()
        
        doneButton.isHidden = true
        nextButton.isHidden = true
    }
    
    // MARK: - Methods from the Super Class
    
    override func makePracticeView() -> TextMeaningPracticeView {
        let practice = practiceProducer.currentPractice as! PodcastPractice
        let practiceView = PodcastPracticeView(
            text: practice.text,
            meaning: practice.meaning,
            textLang: practice.textLang,
            meaningLang: practice.meaningLang,
            textSource: practice.textSource,
            isTextMachineTranslated: practice.isTextMachineTranslated,
            machineTranslatorType: practice.machineTranslatorType,
            existingPhraseRanges: practice.existingPhraseRanges,
            existingPhraseMeanings: practice.existingPhraseMeanings,
            textAccentLocs: practice.textAccentLocs
        )
        
        practiceView.speakButton.isHidden = true
        practiceView.listenButton.isHidden = true
        practiceView.repetitionsLabel.isHidden = true
        
        return practiceView
    }
    
    override func updatePracticeView() {
        super.updatePracticeView()
        
        let currentPractice = practiceProducer.currentPractice as! PodcastPractice
                        
        speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer.delegate = self
        
        normalSpeedUtterance = AVSpeechUtterance(string: LangCode.currentLanguage.processTextForSpeechUtterance(text: currentPractice.text))
        normalSpeedUtterance.voice = AVSpeechSynthesisVoice(identifier: currentPractice.textLang.voiceIdentifier)
        normalSpeedUtterance.rate = currentPractice.textLang.configs.voiceRate
        
        slowSpeedUtterance = AVSpeechUtterance(string: LangCode.currentLanguage.processTextForSpeechUtterance(text: currentPractice.text))
        slowSpeedUtterance.voice = AVSpeechSynthesisVoice(identifier: currentPractice.textLang.voiceIdentifier)
        slowSpeedUtterance.rate = currentPractice.textLang.configs.slowVoiceRate

        speechSynthesizer.speak(normalSpeedUtterance)
        
    }
    
}

extension PodcastPracticeViewController {
    
    // MARK: - Selectors
    
    @objc override func cancelButtonTapped() {
        
        speechSynthesizer.stopSpeaking(at: .immediate)
        synthesizingTimes = nil
        
        super.cancelButtonTapped()
        
    }
}

extension PodcastPracticeViewController: AVSpeechSynthesizerDelegate {
    
    // MARK: - AVSpeechSynthesizer Delegate
     
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        
        if synthesizingTimes == nil {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.synthesizingTimes! += 1
            if self.synthesizingTimes == 1 {
                self.speechSynthesizer.speak(self.slowSpeedUtterance)
            } else if self.synthesizingTimes == 2 {
                self.speechSynthesizer.speak(self.normalSpeedUtterance)
            } else {
                self.practiceProducer.next()
                self.updatePracticeView()
                self.synthesizingTimes = 0
            }
        }
        
    }
}


extension PodcastPracticeViewController {
    
    override func toggleButtonTapped() {
        
        if toggleButton.image == Icons.startIcon {
            
            speechSynthesizer.continueSpeaking()
            toggleButton.image = Icons.pauseIcon
            
            maskView.isHidden = true
            mainView.isUserInteractionEnabled = true
            
        } else if toggleButton.image == Icons.pauseIcon {
            
            speechSynthesizer.pauseSpeaking(at: .immediate)
            toggleButton.image = Icons.startIcon
            
            maskView.isHidden = false
            mainView.isUserInteractionEnabled = false
            view.bringSubviewToFront(maskView)  // The mask view should be in the front of all views.
            
        }
    }
    
    override func maskViewTapped() {
        
        speechSynthesizer.continueSpeaking()
        toggleButton.image = Icons.pauseIcon
        
        maskView.isHidden = true
        mainView.isUserInteractionEnabled = true
        
    }
    
    override func stopPracticing() {
        practiceProducer.cache()  // Finished all / tapped the cancel button.
        super.stopPracticing()
    }
    
}
