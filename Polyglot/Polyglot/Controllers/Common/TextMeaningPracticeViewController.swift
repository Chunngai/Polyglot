//
//  TextMeaningPracticeViewController.swift
//  Polyglot
//
//  Created by Ho on 2/16/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class TextMeaningPracticeViewController: PracticeViewController {
    
    var allNewWordsInfo: [(
        textSource: TextSource,
        newWordsInfo: [NewWordInfo]
    )] = []

    var textViewOfPracticeView: NewWordAddingTextView {
        get {
            return (practiceView as! TextMeaningPracticeView).textView
        }
        set {
            (practiceView as! TextMeaningPracticeView).textView = newValue
        }
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // TODO: - Simplify here.
        textViewOfPracticeView.newWordBottomView.offset = UIScreen.main.bounds.maxY
        - mainView.frame.maxY
        + doneButton.radius
        + 20
    }
    
    func makePrompt() -> String {
        fatalError("makePrompt() has not been implemented.")
    }
    
    func makePracticeView() -> TextMeaningPracticeView {
        fatalError("makePracticeView() has not been implemented.")
    }
    
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
    }
}

extension TextMeaningPracticeViewController {
    
    func updateAllNewWordsInfo(with practiceView: TextMeaningPracticeView) {
        allNewWordsInfo.append((
            textSource: practiceView.textSource,
            newWordsInfo: practiceView.newWordsInfo
        ))
    }
    
    func addWordsFromArticles(words: [Word]) {
        self.words.add(newWords: words)
        for word in words {
            if LangCode.currentLanguage == LangCode.ja {
                JapaneseAccentAnalyzer.makeTokens(for: word) { tokens in
                    guard LangCode.currentLanguage == LangCode.ja else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.words.updateWord(of: word.id, newTokens: tokens)
                    }
                }
            }
            if LangCode.currentLanguage == LangCode.ru {
                RussianAccentAnalyzer.makeTokens(for: word) { tokens in
                    guard LangCode.currentLanguage == LangCode.ru else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.words.updateWord(of: word.id, newTokens: tokens)
                    }
                }
            }
        }
    }
    
    func saveNewWords() {
        var newWords: [Word] = []
        for (textSource, newWordsInfo) in allNewWordsInfo {
            
            var articleTitle: String? = nil
            if case .article(let articleId, _, _) = textSource,
               let article = articles.getArticle(from: articleId) {
                articleTitle = article.title
            } else if textSource == .chatGpt {
                articleTitle = Strings.GPTGeneratedContent
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
    
}

extension TextMeaningPracticeViewController {
    
    // MARK: - TimingBar Delegate
    
    override func stopPracticing() {
        // TODO: - Move elsewhere
        // TODO: - Add an alert
        // New words are saved only the next button is pressed.
        // If the button is not pressed, the new words will not be saved.
        updateAllNewWordsInfo(with: practiceView as! TextMeaningPracticeView)
        saveNewWords()
        
        doneButton.isHidden = true
        nextButton.isHidden = true
    }
    
}
