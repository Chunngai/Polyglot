//
//  SelectionPracticeView.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit
import NaturalLanguage

class SelectionPracticeView: UIView {
    
    // MARK: - Controllers
    
    var delegate: WordsPracticeViewController!
    
    // MARK: - Views
    
    private var textViewBackgroundView: UIView = {
        
        // For content inset of the text view.
        // Directly modifying textView.contentInset does not work well.
        
        let view = UIView()
        view.backgroundColor = Colors.lightGrayBackgroundColor
        view.layer.masksToBounds = true
        view.layer.cornerRadius = Sizes.smallCornerRadius
        return view
    }()
    
    private var textView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = Colors.lightGrayBackgroundColor
        textView.textColor = Colors.normalTextColor
        textView.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.showsVerticalScrollIndicator = false
        textView.attributedText = NSAttributedString(
            string: " ",
            attributes: Attributes.defaultLongTextAttributes
        )
        textView.isHidden = true
        return textView
    }()
    
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
        addSubview(textViewBackgroundView)
        textViewBackgroundView.addSubview(textView)
        
        addSubview(selectionStack)
    }
    
    private func updateLayouts() {
        textViewBackgroundView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.3)
        }
        textView.snp.makeConstraints { (make) in
            make.width.equalToSuperview().multipliedBy(0.95)
            make.height.equalToSuperview().multipliedBy(0.9)
            make.centerX.centerY.equalToSuperview()
        }
        
        selectionStack.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    func updateValues(selectionTexts: [String], textViewText: String? = nil) {
        
        selectionStack.set(texts: selectionTexts)
        
        if let textViewText = textViewText {
            textViewBackgroundView.isHidden = false
            textView.isHidden = false
            textView.text = textViewText
        } else {
            textViewBackgroundView.isHidden = true
            textView.isHidden = true
        }
    }
}

extension SelectionPracticeView: WordPracticeViewDelegate {
    
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

extension SelectionPracticeView: ThreeItemSelectionStackDelegate {
    
    // MARK: - ThreeItemSelectionStack Delegate
    
    func buttonSelected(sender: UIButton) {
        selectionStack.selectButton(of: sender.tag)
        delegate.practiceStatus = .afterAnswering
    }
    
}
