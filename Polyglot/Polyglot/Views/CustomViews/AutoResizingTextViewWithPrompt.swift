//
//  AutoResizingTextViewWithPrompt.swift
//  Polyglot
//
//  Created by Sola on 2022/12/31.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class AutoResizingTextViewWithPrompt: UITextView, UITextViewDelegate {

    var prompt: String!
    var promptAttributes: [NSAttributedString.Key : Any]? = nil
    
    var textAttributes: [NSAttributedString.Key : Any]? = nil {
        didSet {
            guard let prompt = prompt, let textViewText = text else {
                return
            }
            
            let content: NSMutableAttributedString = NSMutableAttributedString(
                string: "\(prompt)\(textViewText)",
                attributes: textAttributes
            )
            
            if let promptAttributes = promptAttributes {
                // Update the prompt color.
                // The text content may contain the prompt (though rare),
                // so make the range instead of directly using the prompt for attr setting.
                // Note that "-1" in the code below is needed, or the attrs of all content will be set when `text` is an empty string.
                let promptRange = NSRange(location: 0, length: prompt.count - 1)
                content.add(attributes: promptAttributes, for: promptRange)
            }
            
            attributedText = content
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
    
    func textViewDidChange(_ textView: UITextView) {
        // Automatically expand cell heights.
        guard let tableView = tableView else {
            return
        }
        adjustHeights(in: tableView)
    }
    
}

extension AutoResizingTextViewWithPrompt {
    
    private func isPromptEdited(range: NSRange) -> Bool {
        return range.location < prompt.count
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        // Prevent editing the prompt.
        // https://stackoverflow.com/questions/9444748/make-portion-of-uitextview-undeletable
        
        return !isPromptEdited(range: range)
    }
    
}
