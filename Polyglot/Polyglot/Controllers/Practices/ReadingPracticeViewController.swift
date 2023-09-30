//
//  ReadingPracticeViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/21.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class ReadingPracticeViewController: PracticeViewController {
    
    private lazy var practiceProducer: ReadingPracticeProducer = ReadingPracticeProducer(articles: articles)

    private var allNewWordsInfo: [Int : [NewWordInfo]] = [:]
        
    private var textViewOfPracticeView: NewWordAddingTextView {
        get {
            guard practiceView != nil else {
                // Dummy text view.
                return NewWordAddingTextView(textLang: LangCode.en, meaningLang: LangCode.en)
            }
            return (practiceView as! ReadingPracticeView).textView
        }
        set {
            (practiceView as! ReadingPracticeView).textView = newValue
        }
    }
    private var bottomViewOffset: CGFloat!
    
    // MARK: - Init
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // https://stackoverflow.com/questions/55492684/how-to-get-the-frame-of-a-uiview-that-has-been-setup-through-snapkit
        bottomViewOffset = UIScreen.main.bounds.maxY - mainView.frame.maxY + doneButton.radius + 20  // TODO: - Simplify here.
        // The offset of the bottom view in the current text view
        // has been set in updatePracticeView() before this method
        // is called.
        // Thus reset the offset here.
        textViewOfPracticeView.newWordBottomView.offset = bottomViewOffset
    }
    
    override func updateViews() {
        super.updateViews()
        
        promptLabel.isHidden = true  // No prompt label is needed.
        doneButton.isHidden = true  // No done button is needed.
        nextButton.isHidden = false
    }
    
    override func updatePracticeView() {
        // Dismiss the keyboard.
        // If it is not dismissed, the bottom view
        // of the next new word adding text view will have
        // invalid height.
        // https://stackoverflow.com/questions/24126678/close-ios-keyboard-by-touching-anywhere-using-swift
        view.endEditing(true)
        
        // Remove the old practice view.
        if practiceView != nil {
            practiceView.removeFromSuperview()
        }
        // Make a new one.
        practiceView = {
            return ReadingPracticeView(
                text: practiceProducer.currentPractice.text,
                textLang: practiceProducer.currentPractice.textLang,
                meaning: practiceProducer.currentPractice.meaning,
                meaningLang: practiceProducer.currentPractice.meaningLang
            )
        }()
        // Add to the main view and update layouts.
        mainView.addSubview(practiceView)
        practiceView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
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

        // Recover new words of the current text, if any.
        // Will not be executed if there is not a previous button.
        if allNewWordsInfo.keys.contains(practiceProducer.currentPracticeIndex) {
            textViewOfPracticeView.newWordsInfo = allNewWordsInfo[practiceProducer.currentPracticeIndex]!
            textViewOfPracticeView.highlightAll()  // TODO: - Wrap?
        }
    }
}

extension ReadingPracticeViewController {
    
    // MARK: - Selectors
    
    @objc override func cancelButtonTapped() {
        
        // TODO: - Alert.
        
        stopPracticing()
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc override func nextButtonTapped() {
        // Store new words of the previous text.
        allNewWordsInfo[practiceProducer.currentPracticeIndex] = textViewOfPracticeView.newWordsInfo
        
        practiceProducer.next()
        updatePracticeView()
    }
}

extension ReadingPracticeViewController {
    
    // MARK: - TimeBar Delegate
    
    override func stopPracticing() {
        
        // TODO: - Move elsewhere
        // New words are saved only the next button is pressed.
        // If the button is not pressed, the new words will not be saved.
        allNewWordsInfo[practiceProducer.currentPracticeIndex] = textViewOfPracticeView.newWordsInfo
        
        // TODO: - Merge.
        func saveNewWords() {
            var newWords: [Word] = []
            for (practiceItemIndex, newWordsInfo) in allNewWordsInfo {
                let articleId = practiceProducer.practiceList[practiceItemIndex].practice.articleId
                let article = practiceProducer.dataSource.getArticle(from: articleId)
                let articleTitle = article?.title
                
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
        
        nextButton.isHidden = true
    }
    
}
