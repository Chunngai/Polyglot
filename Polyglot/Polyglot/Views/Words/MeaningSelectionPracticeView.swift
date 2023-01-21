//
//  MeaningSelectionPracticeView.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class MeaningSelectionPracticeView: UIView {

    private var practiceItem: WordPracticeProducer.Item! {
        didSet {
            let buttonTexts: [String] = practiceItem.selectionTexts!
            selectionStack.set(texts: buttonTexts)
        }
    }
    
    private var answer: String {
        selectionStack.selectedButton!.titleLabel!.text!
    }
    private var isCorrect: Bool {
        answer == practiceItem.key
    }
    
    // MARK: - Controllers
    
    var delegate: WordsPracticeViewController!
    
    // MARK: - Views
    
    private var selectionStack: ThreeButtonSelectionStack = {
        let stack = ThreeButtonSelectionStack()
        return stack
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func updateSetups() {
        selectionStack.delegate = self
    }
    
    private func updateViews() {
        addSubview(selectionStack)
    }
    
    private func updateLayouts() {
        selectionStack.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    func updateValues(practiceItem: WordPracticeProducer.Item) {
        self.practiceItem = practiceItem
    }
}

extension MeaningSelectionPracticeView: WordPracticeViewDelegate {
    
    // MARK: - WordPracticeView Delegate
    
    func check() -> String {
        
        if isCorrect {
            selectionStack.selectedButton!.backgroundColor = Colors.lightCorrectColor
        } else {
            selectionStack.selectedButton!.backgroundColor = Colors.lightInorrectColor
            // Also highlight the correct answer.
            for button in selectionStack.buttons {
                if button.titleLabel!.text == practiceItem.key {
                    button.backgroundColor = Colors.lightCorrectColor
                }
            }
        }
        
        return practiceItem.practice.selectionWordsIds![selectionStack.selectedButton!.tag]
    }
}

extension MeaningSelectionPracticeView: ThreeItemSelectionStackDelegate {
    
    // MARK: - ThreeItemSelectionStack Delegate
    
    func buttonSelected(sender: UIButton) {
        selectionStack.selectButton(of: sender.tag)
        delegate.practiceStatus = .afterAnswering
    }
    
}
