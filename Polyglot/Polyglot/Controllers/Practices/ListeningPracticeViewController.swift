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

class ListeningPracticeViewController: TextMeaningPracticeViewController {
    
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
    
    // MARK: - Views
    
    let listenButton: UIButton = {
        let button = UIButton()
        button.setImage(
            Images.listeningPracticeProduceSpeechImage.withTintColor(Colors.activeSystemButtonColor),
            for: .normal
        )
        return button
    }()
    let speakButton: UIButton = {
        let button = UIButton()
        button.setImage(
            Images.listeningPracticeStartToRecordSpeechImage.withTintColor(Colors.activeSystemButtonColor),
            for: .normal
        )
        return button
    }()
    
    // MARK: - Init
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let mainViewWidth = mainView.frame.width
        let horizontalPadding = (mainViewWidth - mainViewWidth * PracticeViewController.practiceViewWidthRatio) / 2
        // Add the listen and speak button.
        speakButton.snp.makeConstraints { make in
            make.top.equalTo(promptLabel.snp.top)
            make.trailing.equalToSuperview().inset(horizontalPadding)
            make.width.equalTo(speakButton.intrinsicContentSize.width)
        }
        listenButton.snp.makeConstraints { make in
            make.top.equalTo(promptLabel.snp.top)
            make.trailing.equalTo(speakButton.snp.leading).offset(-6)
            make.width.equalTo(speakButton.intrinsicContentSize.width)
        }
        // Update the width of the prompt label.
        promptLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().inset(horizontalPadding)
            make.trailing.equalTo(listenButton.snp.leading).offset(-6)
        }
    }
    
    override func updateSetups() {
        super.updateSetups()
                
        listenButton.addTarget(
            self,
            action: #selector(listenButtonTapped),
            for: .touchUpInside
        )
        speakButton.addTarget(
            self,
            action: #selector(speakButtonTapped),
            for: .touchUpInside
        )
    }
    
    override func updateViews() {
        super.updateViews()
        
        promptLabel.numberOfLines = 1
        promptLabel.adjustsFontSizeToFitWidth = true
        
        mainView.addSubview(listenButton)
        mainView.addSubview(speakButton)
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
                existingPhraseMeanings: currentPractice.existingPhraseMeanings
            )
            practiceView.delegate = self
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
                existingPhraseMeanings: currentPractice.existingPhraseMeanings
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
        utterance.rate = currentPractice.textLang.voiceRate
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
                
        let submission = (practiceView as! TextMeaningPracticeView).submit()
        practiceProducer.checkCorrectness(of: submission)
        (practiceView as! TextMeaningPracticeView).updateViewsAfterSubmission()
        
        isRecordingSpeech = false
        speakButton.setImage(
            Images.listeningPracticeDisallowSpeechRecordingImage.withTintColor(Colors.inactiveSystemButtonColor),
            for: .normal
        )
        speakButton.isEnabled = false
    }
    
    @objc override func nextButtonTapped() {
        updateAllNewWordsInfo(with: practiceView as! TextMeaningPracticeView)
                        
        speechSynthesizer.stopSpeaking(at: .immediate)  // Stop first.
        isProducingSpeech = false  // Then change the image.
        isRecordingSpeech = false
        speakButton.tintColor = Colors.activeSystemButtonColor
        speakButton.isEnabled = true
        
        guard !shouldFinishPracticing else {
            self.stopPracticing()
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
}

extension ListeningPracticeViewController: ListenAndRepeatPracticeViewDelegate {
    
    func canSubmit() {
        doneButtonTapped()
    }
    
}

extension ListeningPracticeViewController: AVSpeechSynthesizerDelegate {
    
    // MARK: - AVSpeechSynthesizer Delegate
     
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isProducingSpeech = false
    }
}

extension ListeningPracticeViewController {
    
    // MARK: - Utils
    
    private func startRecording() throws {  // Ref: https://developer.apple.com/documentation/speech/recognizing_speech_in_live_audio#//apple_ref/doc/uid/TP40017110
        let audioSession = AVAudioSession.sharedInstance()
        // https://stackoverflow.com/questions/40270738/avspeechsynthesizer-does-not-speak-after-using-sfspeechrecognizer
        try audioSession.setCategory(
            .playAndRecord,
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
        let recordingFormat = inputNode.outputFormat(forBus: 0)
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
        practiceMetaData["recentListeningPracticeDate"] = Date().repr()
        super.stopPracticing()
    }
    
}

protocol ListeningPracticeViewControllerDelegate {
    
    func processRecognizedSpeech(_ text: String)
    
}
