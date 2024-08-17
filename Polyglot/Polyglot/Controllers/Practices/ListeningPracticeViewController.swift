//
//  ListeningViewController.swift
//  Polyglot
//
//  Created by Ho on 2/6/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import AVFoundation
import Speech

class ListeningPracticeViewController: TextMeaningPracticeViewController, ListenAndRepeatPracticeViewDelegate {
    
    private lazy var practiceProducer: ListeningPracticeProducer = ListeningPracticeProducer(
        words: words,
        articles: articles
    )
    
    // Listening.
    
    var speechSynthesizer: AVSpeechSynthesizer!
    var utterance: AVSpeechUtterance!
    
    var isProducingSpeech: Bool = false {
        didSet {
            if isProducingSpeech {
                isRecordingSpeech = false
                if !speechSynthesizer.isSpeaking {
                    // Should clear the previously enqueued utterance first.
                    // This is necessary when the speaker becomes ready to speak after being
                    // occupied by other apps, e.g., speech recognition of sougou input.
                    // Without the clearing, the app will crash with the error:
                    // An AVSpeechUtterance shall not be enqueued twice
                    speechSynthesizer.stopSpeaking(at: .immediate)
                    speechSynthesizer.speak(utterance)
                } else {
                    speechSynthesizer.continueSpeaking()
                }
                
                listenButton.setImage(
                    Images.listeningPracticePauseSpeechImage,
                    for: .normal
                )
            } else {
                if speechSynthesizer.isSpeaking {
                    speechSynthesizer.pauseSpeaking(at: .immediate)
                }
                
                listenButton.setImage(
                    Images.listeningPracticeProduceSpeechImage,
                    for: .normal
                )
            }
        }
    }
    
    // Speaking.
    
    var speechRecognizer: SFSpeechRecognizer!
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    
    var isRecordingSpeech: Bool = false {
        didSet {
            if isRecordingSpeech {
                isProducingSpeech = false
                
                speakButton.setImage(
                    Images.listeningPracticeRecordingSpeechImage,
                    for: .normal
                )
                
                try? startRecording()
            } else {
                speakButton.setImage(
                    Images.listeningPracticeStartToRecordSpeechImage,
                    for: .normal
                )
                
                audioEngine.stop()
                recognitionRequest?.endAudio()
                recognitionRequest = nil
                recognitionTask?.cancel()
                recognitionTask = nil
            }
        }
    }
    
    // MARK: - ListenAndRepeatPracticeViewDelegate.
    var countingButtons: [UIButton] = {
        var buttons: [UIButton] = [3, 2, 1].map { count in
            let button = RoundButton(radius: Sizes.roundButtonRadius)
            button.setTitle(String(count), for: .normal)
            button.setTitleColor(Colors.weakTextColor, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: Sizes.mediumFontSize)
            button.backgroundColor = Colors.lightBlue
            button.layer.borderColor = Colors.borderColor.cgColor
            button.layer.borderWidth = Sizes.defaultBorderWidth
            button.isHidden = true
            return button
        }
        return buttons
    }()
    var shouldUpdatePractice: Bool = false
    
    // MARK: - Views
    
    var listenButton: UIButton!
    var speakButton: UIButton!
       
    // MARK: - Init
    
    override func updateSetups() {
        super.updateSetups()
        
        for button in countingButtons {
            button.addTarget(
                self,
                action: #selector(countingButtonTapped),
                for: .touchUpInside
            )
        }
    }
    
    override func updateViews() {
        super.updateViews()
        
        for button in countingButtons {
            mainView.addSubview(button)
        }
    }
    
    override func updateLayouts() {
        super.updateLayouts()
        
        for button in countingButtons {
            button.snp.makeConstraints { (make) in
                make.edges.equalTo(doneButton.snp.edges)
            }
        }
    }
    
    // MARK: - Methods from the Super Class
    
    override func makePrompt() -> String {
        let currentPractice = practiceProducer.currentPractice as! ListeningPractice
        return currentPractice.prompt
    }
    
    override func makePracticeView() -> TextMeaningPracticeView {
        let currentPractice = practiceProducer.currentPractice as! ListeningPractice
        switch currentPractice.practiceType {
        case .listenAndRepeat:
            let practiceView = ListenAndRepeatPracticeView(
                text: currentPractice.text,
                meaning: currentPractice.meaning,
                textLang: currentPractice.textLang,
                meaningLang: currentPractice.meaningLang,
                textSource: currentPractice.textSource,
                isTextMachineTranslated: currentPractice.isTextMachineTranslated,
                clozeRanges: currentPractice.clozeRanges,
                existingPhraseRanges: currentPractice.existingPhraseRanges,
                existingPhraseMeanings: currentPractice.existingPhraseMeanings,
                totalRepetitions: currentPractice.totalRepetitions,
                currentRepetition: currentPractice.currentRepetition
            )
            practiceView.delegate = self
            
            listenButton = practiceView.listenButton
            listenButton.addTarget(
                self,
                action: #selector(listenButtonTapped),
                for: .touchUpInside
            )
            
            speakButton = practiceView.speakButton
            speakButton.addTarget(
                self,
                action: #selector(speakButtonTapped),
                for: .touchUpInside
            )
            
            return practiceView
        case .listenAndComplete:
            return ListenAndCompletePracticeView(
                text: currentPractice.text,
                meaning: currentPractice.meaning,
                textLang: currentPractice.textLang,
                meaningLang: currentPractice.meaningLang,
                textSource: currentPractice.textSource,
                isTextMachineTranslated: currentPractice.isTextMachineTranslated,
                existingPhraseRanges: currentPractice.existingPhraseRanges,
                existingPhraseMeanings: currentPractice.existingPhraseMeanings,
                totalRepetitions: currentPractice.totalRepetitions,
                currentRepetition: currentPractice.currentRepetition
            )
        }
    }
    
    override func updatePracticeView() {
        super.updatePracticeView()
        
        let currentPractice = practiceProducer.currentPractice as! ListeningPractice
        
        // Update the speech synthesizer.
        speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer.delegate = self
        utterance = AVSpeechUtterance(string: currentPractice.text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: currentPractice.textLang.voiceIdentifier)
        utterance.rate = currentPractice.textLang.configs.voiceRate
        isProducingSpeech = true
        
        // Update the speech recognizer.
        speechRecognizer = SFSpeechRecognizer(locale: currentPractice.textLang.locale)
    }
}

extension ListeningPracticeViewController {
    
    // MARK: - Selectors
    
    @objc override func cancelButtonTapped() {
        
        isProducingSpeech = false
        isRecordingSpeech = false
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        super.cancelButtonTapped()

    }
    
    @objc override func doneButtonTapped() {
        super.doneButtonTapped()
        
        if let practiceView = practiceView as? TextMeaningPracticeView {
            let submission = practiceView.submit()
            if let correctness = practiceProducer.submit(submission),
               correctness <= ListeningPracticeProducer.listenAndRepeatRedoThredshold {
                practiceView.shouldReinforce = true
            }
            practiceView.updateViewsAfterSubmission()
        }
        
        isRecordingSpeech = false
        speakButton.setImage(
            Images.listeningPracticeStartToRecordSpeechImage.withTintColor(Colors.inactiveSystemButtonColor),
            for: .normal
        )
        speakButton.isEnabled = false
    }
    
    @objc override func nextButtonTapped() {
        
        if let practiceView = practiceView as? TextMeaningPracticeView {
            let newWords = newWords(
                from: practiceView.newWordsInfo,
                of: practiceView.textSource
            )
            add(newWords: newWords)
            updateExistingRangesAndMeaningsOfRemainingPractices(
                from: practiceProducer,
                with: newWords
            )
            
            if practiceView.shouldReinforce {
                practiceProducer.reinforce()
            }
        }
        // Should be called after any code that will access practiceProducer.currentPractice, as this line of code will delete the current practice.
        practiceProducer.updatePracticeRepetitions()
        
        speechSynthesizer.stopSpeaking(at: .immediate)  // Stop first.
        isProducingSpeech = false  // Then change the image.
        isRecordingSpeech = false
        speakButton.tintColor = Colors.activeSystemButtonColor
        speakButton.isEnabled = true
        
        guard !shouldFinishPracticing else {
            practiceMetaData["recentListeningPracticeDate"] = Date().repr(of: Date.defaultDateAndTimeFormat)
            stopPracticing()
            return
        }
        super.nextButtonTapped()
        practiceProducer.next()
        updatePracticeView()
    }
    
    @objc
    private func listenButtonTapped() {
        isProducingSpeech.toggle()
    }
    
    @objc
    private func speakButtonTapped() {
        isRecordingSpeech.toggle()
    }
    
    @objc
    private func countingButtonTapped() {
        shouldUpdatePractice = false
        mainView.bringSubviewToFront(self.nextButton)
    }
}

extension ListeningPracticeViewController {
    
    func submitAndNext() {
        doneButtonTapped()
        
        shouldUpdatePractice = true
        for buttonIndex in 0..<countingButtons.count {
            let button = countingButtons[buttonIndex]
            // https://stackoverflow.com/questions/38031137/how-to-program-a-delay-in-swift-3
            DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(buttonIndex))) {
                if !self.shouldUpdatePractice {
                    self.mainView.bringSubviewToFront(self.nextButton)
                    return
                }
                button.isHidden = false
                self.mainView.bringSubviewToFront(button)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(self.countingButtons.count))) {
            if !self.shouldUpdatePractice {
                return
            }
            self.nextButtonTapped()
        }
        
    }
    
}

extension ListeningPracticeViewController: AVSpeechSynthesizerDelegate {
    
    // MARK: - AVSpeechSynthesizer Delegate
     
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isProducingSpeech = false
        isRecordingSpeech = true
    }
}

extension ListeningPracticeViewController {
    
    // MARK: - Utils
    
    private func startRecording() throws {  // Ref: https://developer.apple.com/documentation/speech/recognizing_speech_in_live_audio#//apple_ref/doc/uid/TP40017110
        let audioSession = AVAudioSession.sharedInstance()
        // https://stackoverflow.com/questions/40270738/avspeechsynthesizer-does-not-speak-after-using-sfspeechrecognizer
        try audioSession.setCategory(
            .playAndRecord,  // Slow.
            mode: .default,
            options: [.defaultToSpeaker, .allowBluetoothA2DP]
        )
        try audioSession.setActive(
            true,
            options: .notifyOthersOnDeactivation
        )
        let inputNode = audioEngine.inputNode

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            isRecordingSpeech = false
            return
        }
        recognitionRequest.shouldReportPartialResults = true

        speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in

            var isFinal = false
            
            if let result = result {
                if let practiceView = self.practiceView as? ListeningPracticeViewControllerDelegate {
                    practiceView.processRecognizedSpeech(result.bestTranscription.formattedString)
                }
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.isRecordingSpeech = false
                inputNode.removeTap(onBus: 0)
            }
        }
        
        // Configure the microphone input.
        var recordingFormat = inputNode.outputFormat(forBus: 0)
        if audioSession.sampleRate != recordingFormat.sampleRate {  // Get hardware (hw) sample rate: https://stackoverflow.com/questions/50712088/how-to-get-hardware-samplerate-from-ios-device
            // Make the hw sample rate consistent with that of the recording format.
            // Sample rate inconsistency will occur when the mic is used by other apps, e.g., speech recognition of sougou input.
            // Without making them consistent, the app will crash with the error:
            // required condition is false: IsFormatSampleRateAndChannelCountValid(format)
            guard let updatedFormat = AVAudioFormat(standardFormatWithSampleRate: audioSession.sampleRate, channels: 1) else {
                return
            }
            recordingFormat = updatedFormat
        }
        guard recordingFormat.sampleRate != 0 && recordingFormat.channelCount != 0 else {
            // Handle random crash (after using the mic with Siri?)
            // https://stackoverflow.com/questions/41805381/avaudioengine-inputnode-installtap-crash-when-restarting-recording
            self.isRecordingSpeech = false
            print("Not enough available inputs!")
            NSLog("Not enough available inputs!")
            return
        }
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: recordingFormat
        ) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
}

extension ListeningPracticeViewController {
    
    override func stopPracticing() {
        practiceProducer.cache()  // Finished all / tapped the cancel button.
        super.stopPracticing()
    }
    
}

protocol ListeningPracticeViewControllerDelegate {
    
    func processRecognizedSpeech(_ text: String)
    
}
