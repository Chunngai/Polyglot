//
//  AutoResizingTextViewWithPrompt.swift
//  Polyglot
//
//  Created by Ho on 11/2/23.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class AutoResizingTextViewWithPrompt: UITextView {

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
        
    // Auto resizing.
    // The table view that contains cells with AutoResizingTextViewWithPrompt.
    var tableViewForHeightAdjustment: UITableView?
    
    // MARK: - Controllers
    
    var delegate_: AutoResizingTextViewWithPromptDelegate!
    
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
        isScrollEnabled = false
    }
    
    private func updateViews() {
        
    }
    
    private func updateLayouts() {
        
    }
}

extension AutoResizingTextViewWithPrompt  {
    
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
        
        // Set attrs for the prompt.
        // The text content may contain the prompt (though rare),
        // so make the range instead of directly using the prompt for attr setting.
        if let prompt = prompt, let promptAttributes = promptAttributes {
            let promptRange = NSRange(location: 0, length: prompt.count)
            textStorage.add(
                attributes: promptAttributes,
                for: promptRange
            )
        }
        
        // Set attrs for the content.
        if let textAttributes = textAttributes {
            // DO NOT USE THE ".ADD" METHOD OF THE EXTENSION OF NSMUTABLEATTRIBUTEDSTRING.
            // THIS METHOD USES STRING RANGES, WHICH CANNOT BE PROPERLY HANDLED
            // WHEN TEXT CONTAINS SPECIAL SYMBOLS, SUCH AS IPA SYMBOLS.
//            let newAttributedText = NSMutableAttributedString(string: text, attributes: textAttributes)
            
            let textRange = NSRange(
                location: prompt.count,
                length: text.count - prompt.count
            )
            textStorage.add(
                attributes: textAttributes,
                for: textRange
            )
        }

    }
}

extension AutoResizingTextViewWithPrompt: UITextViewDelegate {
    
    // MARK: - UITextView Delegate
    
    func textViewDidChange(_ textView: UITextView) {
        
        // Automatically expand cell heights.
        if let tableView = tableViewForHeightAdjustment {
            adjustHeights(in: tableView)
        }
        
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

extension AutoResizingTextViewWithPrompt {
    
    // MARK: - Auto Resizing
    
    private func adjustHeights(in tableView: UITableView) {
        
        // Adjust the height of the cell containing the text view
        // when edits are made.
        // https://stackoverflow.com/questions/37014919/expand-uitextview-and-uitableview-when-uitextviews-text-extends-beyond-1-line
        
        let size = self.bounds.size
        let newSize = self.sizeThatFits(CGSize(
            width: size.width,
            height: CGFloat.greatestFiniteMagnitude
        ))
        
        if size.height != newSize.height {
            UIView.setAnimationsEnabled(false)
            tableView.isScrollEnabled = false
            tableView.beginUpdates()
            tableView.endUpdates()
            tableView.isScrollEnabled = true
            UIView.setAnimationsEnabled(true)
        }
    }
    
}

extension AutoResizingTextViewWithPrompt {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        delegate_.textViewDidEndEditing(textView)
    }
    
}

protocol AutoResizingTextViewWithPromptDelegate {
    
    func textViewDidEndEditing(_ textView: UITextView)
    
}
