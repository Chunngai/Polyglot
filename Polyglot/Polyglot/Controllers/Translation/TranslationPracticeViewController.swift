//
//  TranslationPracticeViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/30.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class TranslationPracticeViewController: PracticeViewController {
    
    private var practiceProducer: TranslationPracticeProducer!

    private var allNewWordsInfo: [Int : [NewWordInfo]] = [:]
    
    private var textViewOfPracticeView: NewWordAddingTextView {
        get {
            guard practiceView != nil else {
                return NewWordAddingTextView()
            }
            return (practiceView as! TranslationPracticeView).textView
        }
        set {
            (practiceView as! TranslationPracticeView).textView = newValue
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
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateSetups()
        updateViews()
        updateLayouts()
        updatePracticeView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        bottomViewOffset = UIScreen.main.bounds.maxY - mainView.frame.maxY + doneButton.radius + 20  // TODO: - Simplify here.
        // The offset of the bottom view in the current text view
        // has been set in updatePracticeView() before this method
        // is called.
        // Thus reset the offset here.
        textViewOfPracticeView.newWordBottomView.offset = bottomViewOffset
    }
    
    override func updateSetups() {
        super.updateSetups()
        
        practiceStatus = .beforeAnswering
        
        solveKeyboardLocation()
    }
    
    override func updateViews() {
        super.updateViews()
    }
    
    override func updateLayouts() {
        super.updateLayouts()
    }
    
    override func updatePracticeView() {
        // Remove the old practice view.
        if practiceView != nil {
            practiceView.removeFromSuperview()
        }
        // Make a new one.
        practiceView = {
            let practiceView = TranslationPracticeView()
            practiceView.updateValues(practiceItem: practiceProducer.currentPractice)
            return practiceView
        }()
        // Add to the main view and update layouts.
        mainView.addSubview(practiceView)
        practiceView.snp.makeConstraints { (make) in
            make.top.equalTo(promptLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.bottom.equalTo(nextButton.snp.top).offset(-20)
        }
        // Also remember to update the textview in the practice view.
        // TODO: - Can the code wrapped into NewWordAddingTextView?
        view.addSubview(textViewOfPracticeView.newWordBottomView)
        textViewOfPracticeView.newWordBottomView.frame = CGRect(
            x: view.frame.minX,
            y: view.frame.maxY,
            width: view.frame.width,
            height: view.frame.height
        )
        textViewOfPracticeView.newWordBottomView.offset = bottomViewOffset
        
        // Update the prompt.
        promptLabel.attributedText = NSAttributedString(
            string: Strings.translationPracticePrompt,
            attributes: Attributes.practicePromptAttributes
        )
    }
    
    func updateValues(articles: [Article]) {
        practiceProducer = TranslationPracticeProducer(articles: articles)
    }
}

extension TranslationPracticeViewController {
    
    // MARK: - Utils
    
    private func displayTranslation() {
        textViewOfPracticeView.attributedText = NSAttributedString(
            string: "\(practiceProducer.currentPractice.text)\n\nTranslation:\n\(practiceProducer.currentPractice.meaning)",  // TODO: - Update here.
            attributes: Attributes.longTextAttributes
        )
        
        // Restore the highlights.
        // TODO: - Simplify here.
        textViewOfPracticeView.highlightAll()
    }
}

extension TranslationPracticeViewController {
    
    // MARK: - Selectors
    
    @objc override func cancelButtonTapped() {
    
        // TODO: - Alert
        
        stopPracticing()
        navigationController?.dismiss(animated: true, completion: nil)

    }
    
    @objc override func doneButtonTapped() {
        
        practiceStatus = .finished
                
        displayTranslation()
    }
    
    @objc override func nextButtonTapped() {
        // Store new words of the previous text.
        allNewWordsInfo[practiceProducer.currentPracticeIndex] = textViewOfPracticeView.newWordsInfo

        practiceProducer.next()
        updatePracticeView()
        
        practiceStatus = .beforeAnswering
    }
}

extension TranslationPracticeViewController {
    
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
                let articleId = practiceProducer.practiceList[practiceItemIndex].practice.articleId
                let article = practiceProducer.dataSource.getArticle(from: articleId)
                let articleTitle = article?.title
                
                for newWordInfo in newWordsInfo {
                    newWords.append(Word(
                        text: newWordInfo.word,
                        meaning: newWordInfo.meaning,
                        note: articleTitle ?? nil
                    ))
                }
            }
            
            var loadedWords = Word.load()  // TODO: - Update.
            loadedWords.add(newWords: newWords)  // TODO: - Don't load every time.
            Word.save(&loadedWords)
        }
        
        saveNewWords()
        
        doneButton.isHidden = true
        nextButton.isHidden = true
        
    }
    
}
