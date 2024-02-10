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

class ListeningPracticeViewController: PracticeViewController {
    
    private lazy var practiceProducer: ListeningPracticeProducer = ListeningPracticeProducer(words: words, articles: articles)

    private var allNewWordsInfo: [Int : [NewWordInfo]] = [:]
    
    private var textViewOfPracticeView: NewWordAddingTextView {
        get {
            guard practiceView != nil else {
                // Dummy text view.
                return NewWordAddingTextView(textLang: LangCode.en, meaningLang: LangCode.en)
            }
            return (practiceView as! PracticeViewWithNewWordAddingTextView).textView
        }
        set {
            (practiceView as! PracticeViewWithNewWordAddingTextView).textView = newValue
        }
    }
    private var bottomViewOffset: CGFloat!
    
    var practiceStatus: PracticeStatus! {
        didSet {
            switch practiceStatus {
            case .beforeAnswering:
                doneButton.isHidden = false
                nextButton.isHidden = true
            case .finished:
                doneButton.isHidden = true
                nextButton.isHidden = false
            default:
                return
            }
        }
    }
    
    // Listening.
    
    var speechSynthesizer = AVSpeechSynthesizer()
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

        bottomViewOffset = UIScreen.main.bounds.maxY - mainView.frame.maxY + doneButton.radius + 20  // TODO: - Simplify here.
        // The offset of the bottom view in the current text view
        // has been set in updatePracticeView() before this method
        // is called.
        // Thus reset the offset here.
        textViewOfPracticeView.newWordBottomView.offset = bottomViewOffset
        
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
        
        practiceStatus = .beforeAnswering
        
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
        
        speechSynthesizer.delegate = self
    }
    
    override func updateViews() {
        super.updateViews()
        
        promptLabel.numberOfLines = 1
        promptLabel.adjustsFontSizeToFitWidth = true
        
        mainView.addSubview(listenButton)
        mainView.addSubview(speakButton)
    }
    
    override func updatePracticeView() {
        func makePracticeView() -> PracticeViewDelegate {
            switch practiceProducer.currentPractice.type {
            case .listenAndRepeat:
                return ListenAndRepeatPracticeView(practice: practiceProducer.currentPractice)
            case .listenAndComplete:
                return ListenAndCompletePracticeView(practice: practiceProducer.currentPractice)
            }
        }
        
        // Dismiss the keyboard.
        // If it is not dismissed, the bottom view
        // of the next new word adding text view will have
        // invalid height.
        view.endEditing(true)
        
        // Update the prompt.
        // IMPORTANT: SHOULD BE ABOVE THE SNP SETTING OF THE PRACTICE VIEW,
        // WHOSE TOP DEPENDS ON THE BOTTOM OF THE PROMPT VIEW.
        // OTHERWISE, THE LOCATIONS OF THE DRAGGABLE LABELS MAY BE WEIRD.
        let promptAttributes = NSMutableAttributedString(
            string: practiceProducer.currentPractice.prompt,
            attributes: Attributes.practicePromptAttributes
        )
        promptLabel.attributedText = promptAttributes
        
        // Remove the old practice view.
        if practiceView != nil {
            practiceView.removeFromSuperview()
        }
        // Make a new one.
        practiceView = makePracticeView()
        // Add to the main view and update layouts.
        mainView.addSubview(practiceView)
        practiceView.snp.makeConstraints { (make) in
            make.top.equalTo(promptLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(PracticeViewController.practiceViewWidthRatio)
            make.bottom.equalTo(nextButton.snp.top).offset(-20)
        }
        // Also remember to update the textview in the practice view.
        // TODO: - Can the code wrapped into NewWordAddingTextView?
        view.addSubview(textViewOfPracticeView.newWordBottomView)
        textViewOfPracticeView.newWordBottomView.frame = CGRect(
            x: view.frame.minX
                // For aligning with the text view.
                + (UIScreen.main.bounds.width * (1 - PracticeViewController.practiceViewWidthRatio) / 2),
            y: view.frame.maxY,
            width: view.frame.width
                // For aligning with the text view.
                - (UIScreen.main.bounds.width * (1 - PracticeViewController.practiceViewWidthRatio)),
            // Height: top padding + word label height + word-meaning padding + meaning label height + bottom padding.
            // TODO: Update the calculation.
            height: 20 + "word".textSize(withFont: UIFont.systemFont(ofSize: Sizes.mediumFontSize)).height + 15 + "meaning".textSize(withFont: UIFont.systemFont(ofSize: Sizes.smallFontSize)).height + 20
        )
        textViewOfPracticeView.newWordBottomView.offset = bottomViewOffset
        
        // Update the speech synthesizer.
        utterance = AVSpeechUtterance(string: practiceProducer.currentPractice.text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: practiceProducer.currentPractice.textLang.voiceIdentifier)
        
        // Update the speech recognizer.
        speechRecognizer = SFSpeechRecognizer(locale: practiceProducer.currentPractice.textLang.locale)
    }
}

extension ListeningPracticeViewController {
    
    // MARK: - Selectors
    
    @objc override func cancelButtonTapped() {
    
        // TODO: - Alert
        
        stopPracticing()
        
        isProducingSpeech = false
        isRecordingSpeech = false
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        navigationController?.dismiss(animated: true, completion: nil)

    }
    
    @objc override func doneButtonTapped() {
        
        practiceStatus = .finished
                
        (practiceView as! ListeningPracticeViewDelegate).submit()
        (practiceView as! ListeningPracticeViewDelegate).updateViewsAfterSubmission()
        
        isRecordingSpeech = false
        speakButton.setImage(
            Images.listeningPracticeDisallowSpeechRecordingImage.withTintColor(Colors.inactiveSystemButtonColor),
            for: .normal
        )
        speakButton.isEnabled = false
    }
    
    @objc override func nextButtonTapped() {
        // Store new words of the previous text.
        allNewWordsInfo[practiceProducer.currentPracticeIndex] = textViewOfPracticeView.newWordsInfo

        practiceProducer.next()
        updatePracticeView()
        
        practiceStatus = .beforeAnswering
        
        speechSynthesizer.stopSpeaking(at: .immediate)  // Stop first.
        isProducingSpeech = false  // Then change the image.
        isRecordingSpeech = false
        speakButton.tintColor = Colors.activeSystemButtonColor
        speakButton.isEnabled = true
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
    
    // MARK: - TimingBar Delegate
    
    override func stopPracticing() {
        
        // TODO: - Move elsewhere
        // New words are saved only the next button is pressed.
        // If the button is not pressed, the new words will not be saved.
        allNewWordsInfo[practiceProducer.currentPracticeIndex] = textViewOfPracticeView.newWordsInfo
        
        // TODO: - Merge with reading practice?
        func saveNewWords() {
            var newWords: [Word] = []
            for (practiceItemIndex, newWordsInfo) in allNewWordsInfo {
                
                // TODO: - Simplify this block.
                var articleTitle: String? = nil
                if let articleId = practiceProducer.practiceList[practiceItemIndex].articleId,
                   let article = practiceProducer.articles.getArticle(from: articleId) {
                    articleTitle = article.title
                }
                
                for newWordInfo in newWordsInfo {
                    newWords.append(Word(
                        text: newWordInfo.word,
                        meaning: newWordInfo.meaning,
                        note: articleTitle
                    ))
                }
            }
            
            addWordsFromArticles(words: newWords)
        }
        
        saveNewWords()
        
        doneButton.isHidden = true
        nextButton.isHidden = true
        
    }
    
}

protocol ListeningPracticeViewControllerDelegate {
    
    func processRecognizedSpeech(_ text: String)
    
}
