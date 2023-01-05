//
//  NewWordAddingTextView.swift
//  Polyglot
//
//  Created by Sola on 2022/12/31.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class NewWordAddingTextView: UITextView, UITextViewDelegate {

    var currentNewWordInfo: NewWordInfo!  // Store the info of the new word being added.
    var newWordsInfo: [NewWordInfo] = []
    var currentSelectedTextRange: UITextRange!  // For deleting new words.
    
    var isAddingNewWord: Bool! {
        didSet {
            if !isAddingNewWord {
                UIMenuController.shared.menuItems = [newWordMenuItem]
            } else {
                UIMenuController.shared.menuItems = []
            }
        }
    }
    
    // MARK: - Views
    
    private var newWordMenuItem: UIMenuItem!  // https://www.youtube.com/watch?v=s-LW_4ypwZo
    
    var newWordBottomView: NewWordBottomView = NewWordBottomView()
    
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
        delegate = self
        
        newWordBottomView.delegate = self
                
        // Display the new word menu item at the beginning.
        newWordMenuItem = UIMenuItem(title: Strings.newWord, action: #selector(newWordMenuItemTapped))
        isAddingNewWord = false
        
        isEditable = false
        
        addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(somewhereInTextViewTapped(recognizer:))
        ))
    }
    
    private func updateViews() {
        backgroundColor = nil
    }
    
    private func updateLayouts() {
        
    }

}

extension NewWordAddingTextView {
    
    // MARK: - Utils
    
    func hightlight(_ range: NSRange, with color: UIColor) {
        let newAttributedText = NSMutableAttributedString(attributedString: attributedText)
        newAttributedText.addAttributes([NSAttributedString.Key.backgroundColor : color], range: range)
        attributedText = newAttributedText
    }
    
    func highlightAll() {
        for newWordInfo in newWordsInfo {
            hightlight(newWordInfo.range, with: Colors.weakLightBlue)
        }
    }
}

extension NewWordAddingTextView {
    
    // MARK: - Selectors
    
    @objc private func newWordMenuItemTapped() {

        // Obtain the new word, its selected range, and its selected text range.
        if let selectedTextRange = selectedTextRange,
            !selectedTextRange.isEmpty,
            let word = text(in: selectedTextRange) {
            
            // Store the info of the new word.
            currentNewWordInfo = NewWordInfo(
                range: selectedRange,
                textRange: selectedTextRange,
                word: word,
                meaning: ""  // Added later.
            )
            
            newWordBottomView.word = word
            newWordBottomView.floatUp()
            
            isAddingNewWord = true
        }
    }
    
    @objc private func somewhereInTextViewTapped(recognizer: UITapGestureRecognizer) {
        
        // https://stackoverflow.com/questions/48474488/get-tapped-word-in-a-uitextview
        
        // For canceling selections
        // & presenting an added new word.
        
        // Cancel the selection if any.
        resignFirstResponder()
        
        if isAddingNewWord {
            // When a new word is being added, do nothing.
            return
        }
        
        // Present an added new word.
        
        if newWordBottomView.isFloatingUp {
            // Float down the presenting bottom view, if any.
            newWordBottomView.floatDown()
            newWordBottomView.clear()
        }

        // Obtain the text position of the tap.
        let location: CGPoint = recognizer.location(in: self)
        let tapPosition: UITextPosition = closestPosition(to: location)!
        
        // Tapped text position.
        let tapPositionValue = valueOf(textPosition: tapPosition)
        for newWordInfo in newWordsInfo {
            
            let wordTextRange: UITextRange = newWordInfo.textRange

            // Left text position.
            let rangeStartPositionValue = valueOf(textPosition: wordTextRange.start)
            // Right text position.
            let rangeEndPositionValue = valueOf(textPosition: wordTextRange.end)

            let isTextRangeTapped: Bool = rangeStartPositionValue <= tapPositionValue
                && tapPositionValue <= rangeEndPositionValue
            if isTextRangeTapped {
                newWordBottomView.word = newWordInfo.word
                newWordBottomView.meaning = newWordInfo.meaning
                newWordBottomView.isAddingNewWord = false  // For displaying the delete icon.
                newWordBottomView.floatUp()
                
                currentSelectedTextRange = wordTextRange  // For deleting the word later.
            }
        }
    }
}

extension NewWordAddingTextView {
    
    // MARK: - UITextView Delegate
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        
        if !isAddingNewWord {
            // Update the meaning only if a new word is being added.
            // In other situations, e.g., an added word is selected, do nothing.
            return
        }
        
        if !newWordBottomView.isFloatingUp {
            // No new word selected.
            return
        }
        
        // Obtain the meaning of the selected word.
        if let selectedTextRange = textView.selectedTextRange,
            !selectedTextRange.isEmpty,
            let meaning = textView.text(in: selectedTextRange) {
            
            currentNewWordInfo.meaning = meaning
            newWordBottomView.meaning = meaning
        }
    }
    
}

extension NewWordAddingTextView: NewWordBottomViewDelegate {
    
    // MARK: - NewWordBottomView Delegate
    
    func addNewWord() {
        
        // Check if the mearning has been filled in.
        if currentNewWordInfo.meaning == "" {
            // TODO: - Highlight the textfield.
            print("Meaning needed.")
            return
        }
        
        // Add the word.
        newWordsInfo.append(currentNewWordInfo)
        
        newWordBottomView.floatDown()
        newWordBottomView.clear()
        
        isAddingNewWord = false
        
        // Highlight the new word.
        let selectedRange = currentNewWordInfo.range
        hightlight(selectedRange, with: Colors.weakLightBlue)
    }
    
    func deleteNewWord() {
        
        // Find the index of the word to delete.
        var index: Int?
        for i in 0..<newWordsInfo.count {
            if newWordsInfo[i].textRange == currentSelectedTextRange {
                index = i
            }
        }
        guard let indexToDelete = index else {
            return
        }
        // Delete the word.
        let removedNewWordInfo = newWordsInfo.remove(at: indexToDelete)
        
        newWordBottomView.floatDown()
        newWordBottomView.clear()
        
        // Remove the highlight.
        let selectedRange = removedNewWordInfo.range
        hightlight(selectedRange, with: Colors.weakBackgroundColor)
    }
    
    func meaningTextFieldEditingChanged() {
        currentNewWordInfo.meaning = newWordBottomView.meaning
    }
}

protocol NewWordAddingTextViewDelegate {
    
    func newWordBottomViewOffset() -> Float
    
}

struct NewWordInfo {
    // For storing the info of a newly added word.
    
    var range: NSRange
    var textRange: UITextRange
    
    var word: String
    var meaning: String
}
