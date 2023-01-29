//
//  MeaningSelectionPracticeView.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit
import NaturalLanguage

class MeaningSelectionPracticeView: UIView {
    
    // MARK: - Controllers
    
    var delegate: WordsPracticeViewController!
    
    // MARK: - Views
    
    private var selectionStack: ThreeButtonSelectionStack = ThreeButtonSelectionStack()
    
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
    
    func updateValues(selectionTexts: [String]) {
        selectionStack.set(texts: selectionTexts)
    }
}

extension MeaningSelectionPracticeView: WordPracticeViewDelegate {
    
    // MARK: - WordPracticeView Delegate
    
    func submit() -> String {
        selectionStack.isSelectionEnabled = false
        
        return selectionStack.selectedButton!.titleLabel!.text!
    }
    
    func updateViews(for correctness: WordPractice.Correctness, key: String, tokenizer: NLTokenizer) {
        if correctness == .correct {
            selectionStack.selectedButton!.backgroundColor = Colors.lightCorrectColor
        } else {
            selectionStack.selectedButton!.backgroundColor = Colors.lightInorrectColor
            
            // Also highlight the correct answer.
            for button in selectionStack.buttons {
                if button.titleLabel!.text == key {
                    button.backgroundColor = Colors.lightCorrectColor
                    break
                }
            }
        }
    }
}

extension MeaningSelectionPracticeView: ThreeItemSelectionStackDelegate {
    
    // MARK: - ThreeItemSelectionStack Delegate
    
    func buttonSelected(sender: UIButton) {
        selectionStack.selectButton(of: sender.tag)
        delegate.practiceStatus = .afterAnswering
    }
    
}
