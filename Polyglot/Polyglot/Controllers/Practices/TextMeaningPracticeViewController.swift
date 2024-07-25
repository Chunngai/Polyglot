//
//  TextMeaningPracticeViewController.swift
//  Polyglot
//
//  Created by Ho on 2/16/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class TextMeaningPracticeViewController: PracticeViewController {

    var textViewOfPracticeView: NewWordAddingTextView {
        get {
            return (practiceView as! TextMeaningPracticeView).textView
        }
        set {
            (practiceView as! TextMeaningPracticeView).textView = newValue
        }
    }
        
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

    }
    
    override func updateLayouts() {
        super.updateLayouts()
        
        let topOffset = UIApplication.shared.statusBarFrame.height  // https://stackoverflow.com/questions/25973733/status-bar-height-in-swift
            + navigationController!.navigationBar.frame.maxY
            + 50
        
        mainView.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalToSuperview().inset(topOffset)
            make.bottom.equalToSuperview()
        }
        
        let doneAndNextButonOffset = UIScreen.main.bounds.width * (1 - PracticeViewController.practiceViewWidthRatio) / 2 - Sizes.roundButtonRadius / 2
        doneButton.snp.remakeConstraints { (make) in
            make.trailing.equalTo(mainView.snp.trailing).inset(doneAndNextButonOffset)
            make.bottom.equalToSuperview().inset(150)
            make.width.height.equalTo(Sizes.roundButtonRadius)
        }
        nextButton.snp.remakeConstraints { (make) in
            make.trailing.equalTo(mainView.snp.trailing).inset(doneAndNextButonOffset)
            make.bottom.equalToSuperview().inset(150)
            make.width.height.equalTo(Sizes.roundButtonRadius)
        }
        
    }
    
    deinit {
        // Remove observers when the view controller is deinitialized
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Methods to be Overwritten
    
    func makePrompt() -> String {
        fatalError("makePrompt() has not been implemented.")
    }
    
    func makePracticeView() -> TextMeaningPracticeView {
        fatalError("makePracticeView() has not been implemented.")
    }
    
    // MARK: - Methods from the Super Class
    
    override func updatePracticeView() {
        // Dismiss the keyboard.
        // If it is not dismissed, the bottom view
        // of the next new word adding text view will have
        // invalid height.
        view.endEditing(true)
        
        // Update the prompt.
        // IMPORTANT: SHOULD BE ABOVE THE SNP SETTING OF THE PRACTICE VIEW,
        // WHOSE TOP DEPENDS ON THE BOTTOM OF THE PROMPT VIEW.
        // OTHERWISE, THE LOCATIONS OF THE DRAGGABLE LABELS MAY BE WEIRD.
        promptLabel.attributedText = NSMutableAttributedString(
            string: makePrompt(),
            attributes: Attributes.practicePromptAttributes
        )
        
        // TODO: Update the calculation.
        // Height: top padding + word label height + word-meaning padding + meaning label height + bottom padding.
        let newWordBottomViewHeight = 20
        + "word".textSize(withFont: UIFont.systemFont(ofSize: Sizes.mediumFontSize)).height
        + 10
        + "meaning".textSize(withFont: UIFont.systemFont(ofSize: Sizes.smallFontSize)).height
        + 20
        
        // Remove the old practice view.
        if practiceView != nil {
            practiceView.removeFromSuperview()
            textViewOfPracticeView.newWordBottomView.removeFromSuperview()
        }
        // Make a new one.
        practiceView = makePracticeView()
        // Add to the main view and update layouts.
        mainView.addSubview(practiceView)
        practiceView.snp.makeConstraints { (make) in
            make.top.equalTo(promptLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(PracticeViewController.practiceViewWidthRatio)
            make.bottom.equalToSuperview().inset(
                NewWordAddingTextView.newWordBottomViewVerticalPadding / 2
                + newWordBottomViewHeight
                + NewWordAddingTextView.newWordBottomViewVerticalPadding
            )
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
            height: newWordBottomViewHeight
        )
        
        mainView.bringSubviewToFront(doneButton)
        mainView.bringSubviewToFront(nextButton)
    }
}

extension TextMeaningPracticeViewController {
    
    // MARK: - Selectors
    
    @objc 
    func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
            
        let viewFrame = view.frame

        guard viewFrame.maxY != keyboardFrame.minY else {
            return
        }
        
        // After switching from a higher keyboard to a lower keyboard,
        // there will be a black bar between the view and the keyboard.
        // The following code fixes this bug.
        let offset = keyboardFrame.minY - viewFrame.maxY
        view.frame.origin = CGPoint(
            x: view.frame.origin.x,
            y: view.frame.origin.y + offset
        )
    }
    
}

extension TextMeaningPracticeViewController {
    
    func newWords(from newWordsInfo: [NewWordInfo], of textSource: TextSource) -> [Word] {
        
        var articleTitle: String? = nil
        if case .article(let articleId, _, _) = textSource,
           let article = articles.getArticle(from: articleId) {
            articleTitle = article.title
        } else if textSource == .chatGpt {
            articleTitle = Strings.GPTGeneratedContent
        }
        
        var newWords: [Word] = []
        for newWordInfo in newWordsInfo {
            newWords.append(Word(
                text: newWordInfo.word,
                meaning: newWordInfo.meaning,
                note: articleTitle
            ))
        }
            
        return newWords
    }
    
    func add(newWords: [Word]) {
        
        for newWord in newWords {
            self.words.add(newWord: newWord)
            
            if LangCode.currentLanguage == LangCode.ja {
                JapaneseAccentAnalyzer.makeTokens(for: newWord) { tokens in
                    guard LangCode.currentLanguage == LangCode.ja else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.words.updateWord(of: newWord.id, newTokens: tokens)
                    }
                }
            }
            if LangCode.currentLanguage == LangCode.ru {
                RussianAccentAnalyzer.makeTokens(for: newWord) { tokens in
                    guard LangCode.currentLanguage == LangCode.ru else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.words.updateWord(of: newWord.id, newTokens: tokens)
                    }
                }
            }
        }
    }
    
    func updateExistingRangesAndMeaningsOfRemainingPractices(from practiceProducer: TextMeaningPracticeProducer, with newWords: [Word]) {
        guard !practiceProducer.practiceList.isEmpty else {
            return
        }
        
        for i in 0..<practiceProducer.practiceList.count {
            guard let practice = practiceProducer.practiceList[i] as? TextMeaningPractice else {
                continue
            }
            
            let (newRanges, newMeanings) = practiceProducer.findExistingPhraseRangesAndMeanings(
                for: practice.text,
                from: newWords
            )
            for (newRange, newMeaning) in zip(newRanges, newMeanings) {
                if !practice.existingPhraseRanges.contains(newRange) {
                    practice.existingPhraseRanges.append(newRange)
                    practice.existingPhraseMeanings.append(newMeaning)
                }
            }
            practiceProducer.practiceList[i] = practice
        }
    }
    
}

extension TextMeaningPracticeViewController {
    
    // MARK: - TimingBar Delegate
    
    override func stopPracticing() {
        // TODO: - Add an alert
        
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
}
