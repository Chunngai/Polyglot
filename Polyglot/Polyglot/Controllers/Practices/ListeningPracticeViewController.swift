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

    private var shouldSpeakSlowUtterance: Bool = false
    var slowSpeedUtterance: AVSpeechUtterance!
    var normalSpeedUtterance: AVSpeechUtterance!
    var utterance: AVSpeechUtterance {
        if !shouldSpeakSlowUtterance {
            return normalSpeedUtterance
        } else {
            return slowSpeedUtterance
        }
    }
    
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
            button.backgroundColor = nil
            button.layer.borderColor = nil
            button.layer.borderWidth = 0
            button.isHidden = true
            return button
        }
        return buttons
    }()
    var shouldUpdatePractice: Bool = false {
        didSet {
            if shouldUpdatePractice {
                self.nextButton.isHidden = true
            } else {
                if self.doneButton.isHidden {
                    // Without the condition, the doneButton will be displayed after re-entering the app.
                    self.nextButton.isHidden = false
                }
                mainView.bringSubviewToFront(self.nextButton)
                // Hide counting buttons.
                for countingButton in self.countingButtons {
                    countingButton.isHidden = true
                }
            }
        }
    }
    var canRecord: Bool = true {
        didSet {
            if !canRecord {
                isRecordingSpeech = false
            }
        }
    }
    
    // MARK: - Views
    
    var listenButton: UIButton!
    var speakButton: UIButton!
       
    // MARK: - Init
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // https://stackoverflow.com/questions/45955583/detect-when-a-view-controller-goes-to-background-and-gets-resumed
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Dynamically determine the keyboard showing type
        // for typing clozed words/typing meanings
        // instead of using a single one.
        // The IQKeyboardManager is suitable for typing clozed words
        // and the self-defined one is suitable for typing meanings.
        // Execution path:
        // super.super.viewDidLoad() -> super.viewDidLoad() -> super.addObserver() -> self.removeObserver()
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        // Detect if the app will move to background.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
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
                machineTranslatorType: currentPractice.machineTranslatorType,
                clozeRanges: currentPractice.clozeRanges,
                existingPhraseRanges: currentPractice.existingPhraseRanges,
                existingPhraseMeanings: currentPractice.existingPhraseMeanings,
                totalRepetitions: currentPractice.totalRepetitions,
                currentRepetition: currentPractice.currentRepetition,
                textAccentLocs: currentPractice.textAccentLocs
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
                machineTranslatorType: currentPractice.machineTranslatorType,
                existingPhraseRanges: currentPractice.existingPhraseRanges,
                existingPhraseMeanings: currentPractice.existingPhraseMeanings,
                totalRepetitions: currentPractice.totalRepetitions,
                currentRepetition: currentPractice.currentRepetition,
                textAccentLocs: currentPractice.textAccentLocs
            )
        }
    }
    
    override func updatePracticeView() {
        super.updatePracticeView()
        
        let currentPractice = practiceProducer.currentPractice as! ListeningPractice
        
        // Update the speech synthesizer.
                
        speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer.delegate = self
        
        normalSpeedUtterance = AVSpeechUtterance(string: LangCode.currentLanguage.processTextForSpeechUtterance(text: currentPractice.text))
        normalSpeedUtterance.voice = AVSpeechSynthesisVoice(identifier: currentPractice.textLang.voiceIdentifier)
        normalSpeedUtterance.rate = currentPractice.textLang.configs.voiceRate
        
        slowSpeedUtterance = AVSpeechUtterance(string: LangCode.currentLanguage.processTextForSpeechUtterance(text: currentPractice.text))
        slowSpeedUtterance.voice = AVSpeechSynthesisVoice(identifier: currentPractice.textLang.voiceIdentifier)
        slowSpeedUtterance.rate = currentPractice.textLang.configs.slowVoiceRate
        
        shouldSpeakSlowUtterance = false
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
                practiceProducer.reinforce(
                    for: LangCode.currentLanguage.configs.listeningPracticeRepetition,
                    shouldPracticeImmediately: true
                )
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
    }
    
    @objc
    private func applicationWillResignActive()  {
        isProducingSpeech = false
        isRecordingSpeech = false
        
        shouldUpdatePractice = false
    }
}

extension ListeningPracticeViewController {
    
    // MARK: - ListenAndRepeatPracticeView Delegate
    
    func submitAndNext() {
        doneButtonTapped()
        
        shouldUpdatePractice = true
        for buttonIndex in 0..<countingButtons.count {
            let button = countingButtons[buttonIndex]
            // https://stackoverflow.com/questions/38031137/how-to-program-a-delay-in-swift-3
            DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(buttonIndex))) {
                if !self.shouldUpdatePractice {
                    return
                }
                // Display the current button.
                button.isHidden = false
                self.mainView.bringSubviewToFront(button)
                // Hide other buttons.
                let nextButtonIndex = (buttonIndex + 1) % self.countingButtons.count
                let nextNextButtonIndex = (buttonIndex + 2) % self.countingButtons.count
                self.countingButtons[nextButtonIndex].isHidden = true
                self.countingButtons[nextNextButtonIndex].isHidden = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(self.countingButtons.count))) {
            if !self.shouldUpdatePractice {
                return
            }
            self.nextButtonTapped()
        }
        
    }
    
    func enableIQKeyboardManager() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        IQKeyboardManager.shared.enable = true
    }
    
    func disableIQKeyboardManager() {
        IQKeyboardManager.shared.enable = false
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }
    
}

extension ListeningPracticeViewController: AVSpeechSynthesizerDelegate {
    
    // MARK: - AVSpeechSynthesizer Delegate
     
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isProducingSpeech = false
        shouldSpeakSlowUtterance.toggle()
        if canRecord {
            isRecordingSpeech = true
        }
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
        inputNode.removeTap(onBus: 0)
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
        guard audioSession.sampleRate == recordingFormat.sampleRate else {
            self.isRecordingSpeech = false
            print("audioSession.sampleRate \(audioSession.sampleRate) != recordingFormat.sampleRate \(recordingFormat.sampleRate)")
            NSLog("audioSession.sampleRate \(audioSession.sampleRate) != recordingFormat.sampleRate \(recordingFormat.sampleRate)")
            return
        }
        guard recordingFormat.sampleRate != 0 && recordingFormat.channelCount != 0 else {
            // Handle random crash (after using the mic with Siri?)
            // https://stackoverflow.com/questions/41805381/avaudioengine-inputnode-installtap-crash-when-restarting-recording
            self.isRecordingSpeech = false
            print("Not enough available inputs!")
            NSLog("Not enough available inputs!")
            return
        }
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
        shouldUpdatePractice = false
        super.stopPracticing()
    }
    
}

protocol ListeningPracticeViewControllerDelegate {
    
    func processRecognizedSpeech(_ text: String)
    
}
