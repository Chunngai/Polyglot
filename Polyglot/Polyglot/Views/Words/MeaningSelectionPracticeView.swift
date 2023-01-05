//
//  MeaningSelectionPracticeView.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class MeaningSelectionPracticeView: UIView {

    private var practiceItem: WordPracticeProducer.WordPracticeItem! {
        didSet {
            let buttonTexts: [String] = practiceItem.selectionTexts!
            selectionStack.updateValues(buttonTexts: buttonTexts)
        }
    }
    
    private var answer: String? {
        selectionStack.selectedButton?.titleLabel!.text
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
    
    func updateValues(practiceItem: WordPracticeProducer.WordPracticeItem) {
        self.practiceItem = practiceItem
    }
}

extension MeaningSelectionPracticeView: PracticeDelegate {
    
    // MARK: - Practice Delegate
    
    func check() -> Any {
        
        let isCorrect: Bool = answer == practiceItem.key
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
