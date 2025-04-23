//
//  TextMeaningPracticeViewController.swift
//  Polyglot
//
//  Created by Ho on 2/16/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit
import SafariServices

class TextMeaningPracticeViewController: PracticeViewController {
        
    // MARK: - Init
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.hideBarSeparator()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.navigationBar.showBarSeparator()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

    }
    
    override func updateViews() {
        super.updateViews()
        
        promptLabel.removeFromSuperview()
        
        for button in [doneButton, nextButton] {
            button.backgroundColor = nil
            button.layer.borderColor = nil
            button.layer.borderWidth = 0
        }
    }
    
    override func updateLayouts() {
        
        let topOffset = UIApplication.shared.statusBarFrame.height  // https://stackoverflow.com/questions/25973733/status-bar-height-in-swift
            + navigationController!.navigationBar.frame.maxY
        
        mainView.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalToSuperview().inset(topOffset)
            make.bottom.equalToSuperview()
        }
        
        doneButton.snp.remakeConstraints { (make) in
            make.trailing.equalTo(mainView.snp.trailing).inset(Sizes.roundButtonRadius / 2)
            make.bottom.equalToSuperview().inset(Sizes.roundButtonRadius / 2)
            make.width.height.equalTo(Sizes.roundButtonRadius)
        }
        nextButton.snp.remakeConstraints { (make) in
            make.trailing.equalTo(mainView.snp.trailing).inset(Sizes.roundButtonRadius / 2)
            make.bottom.equalToSuperview().inset(Sizes.roundButtonRadius / 2)
            make.width.height.equalTo(Sizes.roundButtonRadius)
        }
        
        maskView.snp.remakeConstraints { (make) in
            // If the nav bar is translucent:
//            make.top.equalToSuperview().inset(navigationController!.navigationBar.frame.maxY + 60)
            // If the nav bar is not translucent.
            make.top.equalTo(mainView.snp.top).inset(30)
            make.width.equalToSuperview().multipliedBy(0.9)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(mainView.snp.bottom).inset(30)
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
        
        // TODO: Update the calculation.
        // Height: top padding + word label height + word-meaning padding + meaning label height + bottom padding.
        let newWordBottomViewHeight = 20
            + "word".textSize(withFont: UIFont.systemFont(ofSize: Sizes.mediumFontSize)).height
            + 10
            + "meaning".textSize(withFont: UIFont.systemFont(ofSize: Sizes.smallFontSize)).height
            + 20
        
        // Remove the old practice view.
        if let practiceView = practiceView as? TextMeaningPracticeView {
            practiceView.removeFromSuperview()
            practiceView.textView.wordMarkingBottomView.removeFromSuperview()
        }
        // Make a new one.
        practiceView = makePracticeView()
        // Add to the main view and update layouts.
        mainView.addSubview(practiceView)
        practiceView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        // Also remember to update the textview in the practice view.
        // TODO: - Can the code wrapped into WordMarkingTextView?
        if let practiceView = practiceView as? TextMeaningPracticeView {
            view.addSubview(practiceView.textView.wordMarkingBottomView)
            practiceView.textView.wordMarkingBottomView.frame = CGRect(
                x: view.frame.minX,
                y: view.frame.maxY,
                width: view.frame.width,
                height: newWordBottomViewHeight
            )
            practiceView.languageSelectionDelegate = self
            practiceView.textView.urlOpenDelegate = self
        }
        
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
    
    func newWords(from wordsInfo: [WordInfo], of textSource: TextSource) -> [Word] {
        
        var articleTitle: String? = nil
        if case .article(let articleId, _, _) = textSource,
           let article = articles.getArticle(from: articleId) {
            articleTitle = article.title
        } else if textSource == .chatGpt {
            articleTitle = Strings.GPTGeneratedContent
        }
        
        var newWords: [Word] = []
        for wordInfo in wordsInfo {
            newWords.append(Word(
                text: wordInfo.word,
                meaning: wordInfo.meaning,
                note: articleTitle
            ))
        }
            
        return newWords
    }
    
    func add(newWords: [Word]) {
        
        for newWord in newWords {
            if self.words.add(newWord: newWord) == nil {
                analyzeAccents(for: newWord.text) { tokens, fixedText, _ in
                    guard !tokens.isEmpty else {
                        return
                    }
                    let _ = self.words.updateWord(
                        of: newWord.id,
                        newText: fixedText ?? newWord.text,
                        newTokens: tokens
                    )
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
    
    func generateWordPractices(from reinforcementWordsInfo: [WordInfo]) {
 
        var reinforcementWords: [String] = []
        for reinforcementWordInfo in reinforcementWordsInfo {
            reinforcementWords.append(reinforcementWordInfo.word)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let wordPracticeProducer = WordPracticeProducer(
                words: self.words,
                articles: self.articles
            )
            wordPracticeProducer.makeAndCachePractices(for: reinforcementWords)
        }
    }
    
}

extension TextMeaningPracticeViewController: WordMarkingTextViewURLOpenDelegate {
 
    // MARK: - WordMarkingTextViewURLOpen Delegate
    
    func openURL(wordMarkingTextView: WordMarkingTextView, urlString: String) {
        
        // https://stackoverflow.com/questions/39546856/how-to-open-a-url-in-swift
        let url = URL(string: urlString)
        guard let url = url else {
            return
        }
        let vc = SFSafariViewController(url: url)
        present(vc, animated: true, completion: nil)
        
    }
    
}

extension TextMeaningPracticeViewController: TextMeaningPracticeViewDelegate {
    
    // MARK: - TextMeaningPracticeView Delegate
    
    func showLanguageSelectionController(currentlySelectedLanguage: LangCode) {
        
        let vc = LanguageSelectionViewController()
        vc.delegate = self
        vc.langs = LangCode.currentLanguage.languagesForTranslation
        vc.selectedLang = currentlySelectedLanguage
        
        navigationController?.navigationBar.backgroundColor = nil
        navigationController?.pushViewController(
            vc,
            animated: true
        )
        
    }
 
}

extension TextMeaningPracticeViewController: LanguageSelectionViewControllerDelegate {
    
    // MARK: - LanguageSelectionViewController Delegate
    
    func updateLanguage(as language: LangCode) {
        
        navigationController?.navigationBar.backgroundColor = Colors.defaultBackgroundColor
        if let practiceView = practiceView as? TextMeaningPracticeView {
            practiceView.updateMeaningLang(as: language)
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
