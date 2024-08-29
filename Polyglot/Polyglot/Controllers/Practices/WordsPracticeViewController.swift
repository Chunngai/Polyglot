//
//  WordsPracticeViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift

class WordsPracticeViewController: PracticeViewController {
    
    private lazy var practiceProducer: WordPracticeProducer = WordPracticeProducer(
        words: words,
        articles: articles
    )
       
    // Code for adjusting the height of the textfield
    // when the keyboard is displayed.
    // TODO: - Move the code elsewhere.
    
    private var oriFrameOfFillingPracticeView: CGRect?
    private var marginBetweenTextFieldAndKeyboard: CGFloat = 30
    
    private func resetFillingPracticeViewMovingOffset() {

        guard let fillingPracticeView = practiceView as? FillingPracticeView else {
            return
        }
        guard let oriFrameOfFillingPracticeView = oriFrameOfFillingPracticeView else {
            return
        }
        
        UIView.animate(withDuration: 0.2) {
            fillingPracticeView.frame = oriFrameOfFillingPracticeView
        }
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
                
        guard let fillingPracticeView = practiceView as? FillingPracticeView else {
            return
        }
        if oriFrameOfFillingPracticeView == nil {
            oriFrameOfFillingPracticeView = fillingPracticeView.frame
        }
        if fillingPracticeView.frame != oriFrameOfFillingPracticeView {
            resetFillingPracticeViewMovingOffset()
        }
        
        // https://stackoverflow.com/questions/8082493/how-to-get-the-frame-of-a-view-inside-another-view
        let textFieldRelatedFrame = fillingPracticeView.convert(fillingPracticeView.textField.frame, to: self.view)
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        if textFieldRelatedFrame.maxY + marginBetweenTextFieldAndKeyboard >= keyboardSize.minY {
            let movingOffset = textFieldRelatedFrame.maxY - keyboardSize.minY + marginBetweenTextFieldAndKeyboard
            UIView.animate(withDuration: 0.2) {
                fillingPracticeView.frame = CGRect(
                    x: fillingPracticeView.frame.minX,
                    y: fillingPracticeView.frame.minY - movingOffset,
                    width: fillingPracticeView.frame.width,
                    height: fillingPracticeView.frame.height
                )
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        resetFillingPracticeViewMovingOffset()
    }
    
    // MARK: - Init

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        IQKeyboardManager.shared.enable = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        IQKeyboardManager.shared.enable = true
    }
    
    override func updateSetups() {
        super.updateSetups()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    override func updatePracticeView() {
        
        let currentPractice = practiceProducer.currentPractice as! WordPracticeProducer.Item
        
        func makePracticeView() -> WordPracticeView {

            switch currentPractice.practice.practiceType {
            case .meaningSelection:
                return {
                    let practiceView = SelectionPracticeView()
                    practiceView.updateValues(selectionTexts: currentPractice.selectionTexts!)
                    practiceView.delegate = self
                    return practiceView
                }()
            case .meaningFilling:
                return {
                    let practiceView = FillingPracticeView()
                    practiceView.delegate = self
                    return practiceView
                }()
            case .contextSelection:
                return {
                    let practiceView = SelectionPracticeView()
                    practiceView.updateValues(
                        selectionTexts: currentPractice.selectionTexts!,
                        textViewText: currentPractice.context!
                    )
                    practiceView.delegate = self
                    return practiceView
                }()
            case .accentSelection:
                return {
                    let practiceView = SelectionPracticeView()
                    practiceView.updateValues(selectionTexts: currentPractice.selectionTexts!)
                    practiceView.delegate = self
                    return practiceView
                }()
            case .reordering:
                return {
                    let practiceView = ReorderingPracticeView()
                    practiceView.updateValues(words: currentPractice.wordsToReorder!)
                    practiceView.delegate = self
                    return practiceView
                }()
            }
        }
        
        // Update the prompt.
        // IMPORTANT: SHOULD BE ABOVE THE SNP SETTING OF THE PRACTICE VIEW,
        // WHOSE TOP DEPENDS ON THE BOTTOM OF THE PROMPT VIEW.
        // OTHERWISE, THE LOCATIONS OF THE DRAGGABLE LABELS MAY BE WEIRD.
        let promptAttributes = NSMutableAttributedString(
            string: currentPractice.prompt,
            attributes: Attributes.practicePromptAttributes
        )
        promptAttributes.add(
            attributes: Attributes.practiceWordAttributes,
            for: currentPractice.wordInPrompt
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
        
        // TODO: - Move elsewhere.
        if let practiceView = practiceView as? ReorderingPracticeView {
            view.layoutIfNeeded()
            // https://stackoverflow.com/questions/14020027/how-do-i-know-that-the-uicollectionview-has-been-loaded-completely
            practiceView.wordBank.reloadData()
            practiceView.wordBank.performBatchUpdates(nil, completion: { (_) in
                practiceView.makeDraggableWordBankItems()
            })
        }
        
        deactivateDoneButton()
    }
}

extension WordsPracticeViewController: WordPracticeViewDelegate {
    
    // MARK: - WordPracticeView Delegate
    
    func activateDoneButton() {
        doneButton.isEnabled = true
        doneButton.backgroundColor = Colors.lightBlue
    }
    
    func deactivateDoneButton() {
        doneButton.isEnabled = false
        doneButton.backgroundColor = Colors.lightGrayBackgroundColor
    }
}

extension WordsPracticeViewController {
    
    // MARK: - Selectors
    
    @objc override func doneButtonTapped() {
        super.doneButtonTapped()
        
        let answer = (practiceView as! WordPracticeView).submit()
        practiceProducer.submit(answer: answer)
        
        let currentPractice = practiceProducer.currentPractice as! WordPracticeProducer.Item
        (practiceView as! WordPracticeView).updateViewsAfterSubmission(
            for: currentPractice.practice.correctness!,
            key: currentPractice.key,
            tokenizer: currentPractice.tokenizer
        )
    }
    
    @objc override func nextButtonTapped() {   
        guard !shouldFinishPracticing else {
            practiceMetaData["recentWordPracticeDate"] = Date().repr(of: Date.defaultDateAndTimeFormat)
            self.stopPracticing()
            return
        }
        
        super.nextButtonTapped()
        practiceProducer.next()
        updatePracticeView()
    }
}

extension WordsPracticeViewController {
    
    // MARK: - TimingBar Delegate
    
    override func stopPracticing() {
        
        for practiceItem in practiceProducer.practiceList {
            let practiceItem = practiceItem as! WordPracticeProducer.Item
            guard let word = words.getWord(from: practiceItem.practice.wordId) else {
                continue
            }
            guard word.tokens != nil else {
                continue
            }
            analyzeAccents(for: word.text) { tokens in
                guard !tokens.isEmpty else {
                    return
                }
                let _ = self.words.updateWord(of: word.id, newTokens: tokens)
            }
            
        }
        
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
}
