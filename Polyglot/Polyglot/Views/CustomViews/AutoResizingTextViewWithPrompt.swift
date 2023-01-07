//
//  AutoResizingTextViewWithPrompt.swift
//  Polyglot
//
//  Created by Sola on 2022/12/31.
//  Copyright © 2022 Sola. All rights reserved.
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
        }
    }
    
    var content: String {
        // TODO: - If the content is deleted after "selete all", the space after the prompt text will be deleted, and the replacement does not work at all.
        return text.replacingOccurrences(of: prompt, with: "")
    }
    
    // The table view that contains cells with AutoResizingTextViewWithPrompt.
    var tableView: UITableView?
    
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

extension AutoResizingTextViewWithPrompt  {
    
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
            tableView.beginUpdates()
            tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
        }
    }
    
    private func maybeAddPrompt() {
        if let prompt = prompt, !text.starts(with: prompt) {
            // Guarantee that the prompt is at the beginning.
            text = prompt + text
        }
    }
    
    private func isPromptEdited(range: NSRange) -> Bool {
        return range.location < prompt.count
    }
    
    private func updateTextAttributes() {
        // Store the current selected range.
        // https://stackoverflow.com/questions/34914948/how-to-stop-cursor-changing-position-when-i-setattributedtext-in-uitextview-dele
        let currentSelectedRange: NSRange = selectedRange
        
        let newAttributedText: NSMutableAttributedString = NSMutableAttributedString(string: text)
        // Set attrs for the content.
        if let textAttributes = textAttributes {
            newAttributedText.add(attributes: textAttributes)
        }
        // Set attrs for the prompt.
        // The text content may contain the prompt (though rare),
        // so make the range instead of directly using the prompt for attr setting.
        if let prompt = prompt, let promptAttributes = promptAttributes {
            let promptRange = NSRange(location: 0, length: prompt.count)
            newAttributedText.add(attributes: promptAttributes, for: promptRange)
        }
        attributedText = newAttributedText
        
        // Recover the selected range.
        selectedRange = currentSelectedRange
    }
}

extension AutoResizingTextViewWithPrompt: UITextViewDelegate {
    
    // MARK: - UITextView Delegate
    
    func textViewDidChange(_ textView: UITextView) {
        // Automatically expand cell heights.
        guard let tableView = tableView else {
            return
        }
        adjustHeights(in: tableView)
        
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

        // When all content is deleted,
        // textView.text.count may be less than prompt.count.
        // Reset here.
        if textView.text.count < prompt.count {
            textView.text = prompt
        }
                
        // Disallow to select the prompt.
        var r = textView.selectedRange
        if r.location < prompt.count {
            r = NSRange(location: prompt.count, length: content.count)
            textView.selectedRange = r
        }
    }
}
