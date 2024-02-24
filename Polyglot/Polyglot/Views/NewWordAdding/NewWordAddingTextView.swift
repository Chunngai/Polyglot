//
//  NewWordAddingTextView.swift
//  Polyglot
//
//  Created by Sola on 2022/12/31.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class NewWordAddingTextView: UITextView, UITextViewDelegate {

    var currentNewWordInfo: NewWordInfo = NewWordInfo(
        textRange: UITextRange(),
        word: "",
        meaning: ""
    )  // Store the info of the new word being added.
    var newWordsInfo: [NewWordInfo] = []
    
    var currentSelectedTextRange: UITextRange!  // For deleting new words.
    
    var isAddingNewWord: Bool = false
    
    // MARK: - Views
    
    private var newWordMenuItem: UIMenuItem!  // https://www.youtube.com/watch?v=s-LW_4ypwZo
    private var wordMeaningMenuItem: UIMenuItem!
    
    var newWordBottomView: NewWordAddingBottomView!
    
    // MARK: - Init
    
    init(frame: CGRect = .zero, textContainer: NSTextContainer? = nil, textLang: LangCode, meaningLang: LangCode) {
        super.init(frame: frame, textContainer: textContainer)
        
        newWordBottomView = NewWordAddingBottomView(
            wordLang: textLang,
            meaningLang: meaningLang
        )
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateSetups() {
        
        isEditable = false
        
        newWordBottomView.delegate = self
                
        // Display the new word menu item at the beginning.
        newWordMenuItem = UIMenuItem(
            title: Strings.newWordMenuItemString,
            action: #selector(newWordMenuItemTapped)
        )
        wordMeaningMenuItem = UIMenuItem(
            title: Strings.wordMeaningMenuItemString,
            action: #selector(wordMeaningMenuItemTapped)
        )
        UIMenuController.shared.menuItems = [newWordMenuItem, wordMeaningMenuItem]
                
        
        addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(somewhereInTextViewTapped(recognizer:))
        ))
    }
    
    private func updateViews() {
        backgroundColor = nil
        showsVerticalScrollIndicator = false
    }
    
    private func updateLayouts() {
        
    }

}

extension NewWordAddingTextView {
    
    // MARK: - Utils
    
    func nsRange(from textRange: UITextRange) -> NSRange {
        // Ref: https://stackoverflow.com/questions/21149767/convert-selectedtextrange-uitextrange-to-nsrange
        let location = offset(from: beginningOfDocument, to: textRange.start)
        let length = offset(from: textRange.start, to: textRange.end)
        return NSRange(location: location, length: length)
    }
    
    func textRange(from nsRange: NSRange) -> UITextRange? {
        // Ref: https://stackoverflow.com/questions/9126709/create-uitextrange-from-nsrange
        if let rangeStart = position(from: beginningOfDocument, offset: nsRange.location),
           let rangeEnd = position(from: rangeStart, offset: nsRange.length) {
            return textRange(from: rangeStart, to: rangeEnd)
        }
        return nil
    }
    
    func hightlight(_ textRange: UITextRange, with color: UIColor) {
        let newAttributedText = NSMutableAttributedString(attributedString: attributedText)
        newAttributedText.addAttributes([NSAttributedString.Key.backgroundColor : color], range: nsRange(from: textRange))
        attributedText = newAttributedText
    }
    
    func highlightAll() {
        for newWordInfo in newWordsInfo {
            hightlight(newWordInfo.textRange, with: Colors.lightBlue)
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
                textRange: selectedTextRange,
                word: word,
                meaning: ""  // Added later.
            )
            
            if newWordBottomView.isFloatingUp {
                // Float down the presenting bottom view, if any.
                newWordBottomView.floatDown()
                newWordBottomView.clear()
            }
            newWordBottomView.word = word
            newWordBottomView.floatUp()
            
            isAddingNewWord = true
        }
    }
    
    @objc private func wordMeaningMenuItemTapped() {
        // Obtain the meaning of the selected word.
        if let selectedTextRange = selectedTextRange,
            !selectedTextRange.isEmpty,
            let meaning = text(in: selectedTextRange) {
            
            currentNewWordInfo.meaning = meaning
            newWordBottomView.meaning = meaning
        }
    }
    
    @objc private func somewhereInTextViewTapped(recognizer: UITapGestureRecognizer) {
        
        newWordBottomView.meaningTextField.resignFirstResponder()
        
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

            // Use < instead of <=,
            // else tapping anywhere below the text will meet the condition
            // if the range is at the end of the text.
            let isTextRangeTapped: Bool = rangeStartPositionValue < tapPositionValue
                && tapPositionValue < rangeEndPositionValue
            if isTextRangeTapped {
                newWordBottomView.word = newWordInfo.word
                newWordBottomView.meaning = newWordInfo.meaning
                newWordBottomView.isAddingNewWord = false  // For displaying the delete icon.
                newWordBottomView.floatUp()
                
                currentSelectedTextRange = wordTextRange  // For deleting the word later.
                
                break  // Avoid overlapped highlighting.
            }
        }
    }
}

extension NewWordAddingTextView {
        
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        if action == #selector(copy(_:)) {
            return true
        }
        if !isAddingNewWord && action == #selector(newWordMenuItemTapped) {
            return true
        }
        if isAddingNewWord && action == #selector(wordMeaningMenuItemTapped) {
            return true
        }
        return false
      
    }
    
}

extension NewWordAddingTextView: NewWordBottomViewDelegate {
    
    // MARK: - NewWordAddingBottomView Delegate
    
    func addNewWord() {
        
        // Add the word.
        newWordsInfo.append(currentNewWordInfo)
        
        newWordBottomView.floatDown()
        newWordBottomView.clear()
        
        isAddingNewWord = false
        
        // Highlight the new word.
        let selectedRange = currentNewWordInfo.textRange
        hightlight(selectedRange, with: Colors.lightBlue)
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
        let selectedRange = removedNewWordInfo.textRange
        hightlight(selectedRange, with: Colors.lightGrayBackgroundColor)
        // The code above will remove the background colors
        // of the overlapped ranges, which need to be recovered.
        highlightAll()
    }
    
    func meaningTextFieldEditingChanged() {
        currentNewWordInfo.meaning = newWordBottomView.meaning
    }
}

struct NewWordInfo {
    // For storing the info of a newly added word.
    
    var textRange: UITextRange
    
    var word: String
    var meaning: String
}
