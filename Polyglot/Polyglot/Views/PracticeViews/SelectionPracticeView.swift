//
//  SelectionPracticeView.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit
import NaturalLanguage

class SelectionPracticeView: WordPracticeView {
    
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
        view.layer.borderWidth = Sizes.defaultBorderWidth
        view.layer.borderColor = Colors.borderColor.cgColor
        return view
    }()
    
    private var textView: UITextView = {
        // Use TextKit 1 by setting usingTextLayoutManager to false.
        // Otherwise the following warning will be raised
        // and the text view cannot be scrolled after scrolling the
        // underscore to the middle of the view using textView.setContentOffset()
        // in layoutSubviews().
        //
        // UITextView 4,365,398,528 is switching to TextKit 1 compatibility mode because its layoutManager was accessed. Break on void _UITextViewEnablingCompatibilityMode(UITextView *__strong, BOOL) to debug.
        //
        // https://stackoverflow.com/questions/74517550/siwiftui-uitextview-is-switching-to-textkit-1
        let textView = UITextView(usingTextLayoutManager: false)
        textView.backgroundColor = Colors.lightGrayBackgroundColor
        textView.textColor = Colors.normalTextColor
        textView.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.showsVerticalScrollIndicator = false
        textView.attributedText = NSAttributedString(
            string: " ",
            attributes: Attributes.defaultLongTextAttributes(fontSize: Sizes.smallFontSize)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textViewBackgroundView.layoutSubviews()
        // THE SCROLLING WORKS PROPERLY
        // ONLY AFTER THE FRAME OF THE TEXTVIEW IS DETERMINED.
        // SINCE THE TEXTVIEW IS A SUBVIEW OF TEXTVIEWBACKGROUNDVIEW,
        // `textViewBackgroundView.layoutSubviews()` IS REQUIRED
        // BEFORE THE SCROLLING IS PERFORMED.
        if let text = textView.text {
            // Scroll to the underscore.
            if let range = text.range(of: Strings.underscoreToken) {
                let nsRange = text.nsrange(from: range)
                let textRect = textView.layoutManager.boundingRect(forGlyphRange: nsRange, in: textView.textContainer)
                let centerOffsetY = (textView.bounds.height - textRect.height) / 2 - textRect.minY
                let contentOffsetY = textView.contentOffset.y - centerOffsetY
                let maxContentOffsetY = textView.contentSize.height - textView.bounds.height
                let adjustedContentOffsetY = min(  // Ensure that the scrolling will not result in a large space at the end of the text view (e.g., when the underscore is near the end of the text).
                    max(  // Ensure that the underscore is not currently at the visible area of the text view.
                        contentOffsetY, 
                        0
                    ), 
                    maxContentOffsetY
                )
                let contentOffset = CGPoint(
                    x: 0, 
                    y: contentOffsetY
                )
                textView.setContentOffset(
                    contentOffset, 
                    animated: false
                )
                // if contentOffsetY > 0 {
                //     let contentOffset = CGPoint(x: 0, y: contentOffsetY)
                //     textView.setContentOffset(contentOffset, animated: false)
                // }
            }
        }
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
        
        selectionStack.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        textViewBackgroundView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalTo(selectionStack.snp.top).offset(-20)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        textView.snp.makeConstraints { (make) in
            make.width.equalToSuperview().multipliedBy(0.95)
            make.height.equalToSuperview().multipliedBy(0.9)
            make.centerX.centerY.equalToSuperview()
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
    
    // MARK: - Methods from the Super Class
    
    override func submit() -> String {
        selectionStack.isSelectionEnabled = false
        
        return selectionStack.selectedButton!.titleLabel!.text!
    }
    
    override func updateViewsAfterSubmission(for correctness: WordPractice.Correctness, key: String, tokenizer: NLTokenizer) {
        if correctness == .correct {
            selectionStack.selectedButton!.backgroundColor = Colors.correctColor
        } else {
            selectionStack.selectedButton!.backgroundColor = Colors.incorrectColor
            
            // Also highlight the correct answer.
            for button in selectionStack.buttons {
                if button.titleLabel!.text == key {
                    button.backgroundColor = Colors.correctColor
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
        delegate.activateDoneButton()
    }
    
}
