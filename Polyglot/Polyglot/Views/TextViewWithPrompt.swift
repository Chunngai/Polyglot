//
//  TextViewWithPrompt.swift
//  Polyglot
//
//  Created by Ho on 11/2/23.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class TextViewWithPrompt: UITextView {

    var prompt: String! {
        didSet {
            text = prompt
        }
    }
    
    var promptAttributes: [NSAttributedString.Key : Any]? = nil {
        didSet {
            updateTextAttributes()
        }
    }
    var textAttributes: [NSAttributedString.Key : Any]? = nil {
        didSet {
            updateTextAttributes()
        }
    }
    
    override var text: String! {
        didSet {
            // Only called once?
            // For subsequent changes, textViewDidChange() will be called.
            
            maybeAddPrompt()
            updateTextAttributes()
        }
    }
    
    var content: String {
        if let range = text.range(of: prompt) {
            return text.replacingOccurrences(of: prompt, with: "", range: range)
        } else {
            return text.replacingOccurrences(of: prompt, with: "")
        }
    }
        
    // MARK: - Init
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        updateConfigs()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateConfigs() {
        // Important! Do not set the delegate as a view controller.
        // https://www.jianshu.com/p/bf26d3d68a7d
        delegate = self
    }
    
    private func updateViews() {
        
    }
    
    private func updateLayouts() {
        
    }
}

extension TextViewWithPrompt  {
    
    private func maybeAddPrompt() {
        if let prompt = prompt, !text.starts(with: prompt) {
            if prompt.strip() != text.strip() {
                // Guarantee that the prompt is at the beginning.
                text = prompt + text
            } else {
                // If the content is deleted after "selete all",
                // the space after the prompt will be removed.
                text = prompt
            }
        }
    }
    
    private func isPromptEdited(range: NSRange) -> Bool {
        return range.location < prompt.count
    }
    
    private func updateTextAttributes() {
        // Store the current selected range.
        // https://stackoverflow.com/questions/34914948/how-to-stop-cursor-changing-position-when-i-setattributedtext-in-uitextview-dele
        let currentSelectedRange: NSRange = selectedRange
        
        // Set attrs for the content.
        if let textAttributes = textAttributes {
            // DO NOT USE THE ".ADD" METHOD OF THE EXTENSION OF NSMUTABLEATTRIBUTEDSTRING.
            // THIS METHOD USES STRING RANGES, WHICH CANNOT BE PROPERLY HANDLED
            // WHEN TEXT CONTAINS SPECIAL SYMBOLS, SUCH AS IPA SYMBOLS.
            let newAttributedText = NSMutableAttributedString(string: text, attributes: textAttributes)
            
            // Set attrs for the prompt.
            // The text content may contain the prompt (though rare),
            // so make the range instead of directly using the prompt for attr setting.
            if let prompt = prompt, let promptAttributes = promptAttributes {
                let promptRange = NSRange(location: 0, length: prompt.count)
                newAttributedText.addAttributes(promptAttributes, range: promptRange)
            }
            
            attributedText = newAttributedText
        }
                
        // Recover the selected range.
        selectedRange = currentSelectedRange
    }
}

extension TextViewWithPrompt: UITextViewDelegate {
    
    // MARK: - UITextView Delegate
    
    func textViewDidChange(_ textView: UITextView) {
        // Update attributes for the prompt and the content.
        maybeAddPrompt()
        updateTextAttributes()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        // Prevent editing the prompt.
        // https://stackoverflow.com/questions/9444748/make-portion-of-uitextview-undeletable
        
        return !isPromptEdited(range: range)
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
                
        // Disallow to select the prompt.
        // Note that nothing should be done if no text is selected (r.length == 0)!
        var r = textView.selectedRange
//        if r.length != 0 && r.location < prompt.count {
//            r = NSRange(location: prompt.count, length: content.count)
//            textView.selectedRange = r
//        }
        if r.location < prompt.count {
            r.location = prompt.count
            textView.selectedRange = r
        }
    }
}

