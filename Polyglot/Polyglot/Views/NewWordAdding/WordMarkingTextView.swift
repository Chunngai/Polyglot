//
//  WordMarkingTextView.swift
//  Polyglot
//
//  Created by Sola on 2022/12/31.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class WordMarkingTextView: UITextView, UITextViewDelegate {

    var currentWordInfo: WordInfo = WordInfo(
        textRange: UITextRange(),
        word: "",
        meaning: ""
    )  // Store the info of the new word being added.
    var wordsInfo: [WordInfo] = []
    
    var currentSelectedTextRange: UITextRange!  // For deleting new words.
    
    var isAddingNewWord: Bool = false
    var canAddNewWord: Bool = true {
        didSet {
            if canAddNewWord {
                isEditable = false
                addGestureRecognizer(tapGestureRecognizer)
            } else {
                isEditable = true
                removeGestureRecognizer(tapGestureRecognizer)
                
                autocorrectionType = .no
                spellCheckingType = .no
                autocapitalizationType = .none
            }
        }
    }
    
    var tapGestureRecognizer: UITapGestureRecognizer!
    
    var defaultTextAttributes: [NSAttributedString.Key : Any] = [
        .foregroundColor: Colors.normalTextColor,
        .backgroundColor: Colors.defaultBackgroundColor
    ]
    var defaultWordMemorizationTextAttributes: [NSAttributedString.Key : Any] = Attributes.leftAlignedLongTextAttributes
    var defaultHighlightingColor: UIColor = Colors.newWordHighlightingColor
    
    // For word memorization.
    private var contentCreatorForWordMemorization: ContentCreator = ContentCreator(.gpt4o)
    private var word2memorizationContentRange: [String: NSRange] = [:]
    private var memorizationContentRefreshIconRange2wordAndStatus: [NSRange: (word: String, isRegenerating: Bool)] = [:]
    
    // MARK: - Views
    
    private var newWordMenuItem: UIMenuItem!  // https://www.youtube.com/watch?v=s-LW_4ypwZo
    private var wordMeaningMenuItem: UIMenuItem!
    private var wordMemorizationMenuItem: UIMenuItem!
    
    var wordMarkingBottomView: WordMarkingBottomView!
    
    // MARK: - Init
    
    init(frame: CGRect = .zero, textContainer: NSTextContainer? = nil, textLang: LangCode, meaningLang: LangCode) {
        super.init(frame: frame, textContainer: textContainer)
        
        wordMarkingBottomView = WordMarkingBottomView(
            wordLang: textLang,
            meaningLang: meaningLang
        )
        
        updateSetups()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        wordMarkingBottomView.offset = wordMarkingBottomView.frame.height 
    }
    
    private func updateSetups() {
        
        isEditable = false
        
        tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(somewhereInTextViewTapped(recognizer:))
        )
        addGestureRecognizer(tapGestureRecognizer)
        
        // Display the new word menu item at the beginning.
        newWordMenuItem = UIMenuItem(
            title: Strings.newWordMenuItemString,
            action: #selector(newWordMenuItemTapped)
        )
        wordMeaningMenuItem = UIMenuItem(
            title: Strings.wordMeaningMenuItemString,
            action: #selector(wordMeaningMenuItemTapped)
        )
        wordMemorizationMenuItem = UIMenuItem(
            title: Strings.wordMemorizationMenuItemString,
            action: #selector(wordMemorizationMenuItemTapped)
        )
        UIMenuController.shared.menuItems = [
            newWordMenuItem,
            wordMeaningMenuItem,
            wordMemorizationMenuItem
        ]
        
        wordMarkingBottomView.delegate = self

    }

}

extension WordMarkingTextView {
    
    private func tappedAt(_ tappedTextRange: UITextRange) {
        
        // For canceling selections
        // & handling memorization content regeneration
        // & presenting an added new word.
        // https://stackoverflow.com/questions/48474488/get-tapped-word-in-a-uitextview

        wordMarkingBottomView.meaningTextField.resignFirstResponder()
        // Cancel the selection if any.
        resignFirstResponder()
        
        // When a new word is being added, do nothing.
        if isAddingNewWord {
            return
        }
        
        // Float down the presenting bottom view, if any.
        if wordMarkingBottomView.isFloatingUp {
            wordMarkingBottomView.floatDown()
            wordMarkingBottomView.clear()
        }
        
        // When a refresh button is tapped, regenerate the content.
        if haveTappedRefreshButtonForWordMemorizationContent(tappedTextRange: tappedTextRange) {
            return
        }
        
        // Present an added new word.
        let tapPositionValue = valueOf(textPosition: tappedTextRange.start)
        for wordInfo in wordsInfo {
            
            let wordTextRange: UITextRange = wordInfo.textRange
            // Left text position.
            let rangeStartPositionValue = valueOf(textPosition: wordTextRange.start)
            // Right text position.
            let rangeEndPositionValue = valueOf(textPosition: wordTextRange.end)

            // Use <= and do not use intersection(),
            // else the condition is false if the left of the first letter
            // or the right of the last letter is tapped.
            let isTextRangeTapped: Bool = (
                rangeStartPositionValue <= tapPositionValue
                && tapPositionValue <= rangeEndPositionValue
            )
            if isTextRangeTapped {
                wordMarkingBottomView.word = wordInfo.word
                wordMarkingBottomView.meaning = wordInfo.meaning
                wordMarkingBottomView.isAddingNewWord = false  // For displaying the delete icon.
                wordMarkingBottomView.deleteButton.isHidden = !wordInfo.canDelete
                wordMarkingBottomView.floatUp()
                
                currentSelectedTextRange = wordTextRange  // For deleting the word later.
                
                break  // Avoid overlapped highlighting.
            }
        }
    }
        
    private func haveTappedRefreshButtonForWordMemorizationContent(tappedTextRange: UITextRange) -> Bool {
        
        let tappedRange = nsRange(from: tappedTextRange)
        
        var hitRange: NSRange? = nil
        for offset in [-2, -1, 0, 1, 2] {
            let location = tappedRange.location + offset
            if location < 0 {
                continue
            }
            if location >= self.attributedText.length {
                continue
            }
            let r = NSRange(
                location: location,
                length: 1
            )
            if memorizationContentRefreshIconRange2wordAndStatus.keys.contains(r) {
                hitRange = r
                break
            }
        }
        guard let hitRange = hitRange else {
            return false
        }
        
        if let (word, isGenerating) = memorizationContentRefreshIconRange2wordAndStatus[hitRange],
           !isGenerating,
           let memorizationContentRange = word2memorizationContentRange[word] {
            
            // Disable regeneration.
            memorizationContentRefreshIconRange2wordAndStatus[hitRange]!.isRegenerating = true
            
            // Make the refresh button gray.
            let attrText = NSMutableAttributedString(attributedString: attributedText)
            attrText.replaceCharacters(
                in: hitRange,
                with: ""
            )
            attrText.insert(
                imageAttributedString(with: Images.wordMemorizationContentRefreshingImage.withTintColor(Colors.inactiveTextColor)),
                at: hitRange.location
            )
            self.attributedText = attrText
            
            // Regenerate the content.
            generateWordMemorizationContent(for: word) { content in
                
                // Enable regeneration.
                self.memorizationContentRefreshIconRange2wordAndStatus[hitRange]!.isRegenerating = false
                
                DispatchQueue.main.async {
                    
                    // Make the refresh button black.
                    var attrText = NSMutableAttributedString(attributedString: self.attributedText)
                    attrText.replaceCharacters(
                        in: hitRange,
                        with: ""
                    )
                    attrText.insert(
                        self.imageAttributedString(with: Images.wordMemorizationContentRefreshingImage.withTintColor(Colors.normalTextColor)),
                        at: hitRange.location
                    )
                    self.attributedText = attrText
                    
                    // Update the content.
                    guard let content = content else {
                        return
                    }
                    let parsedAttrContent = self.parseBoldingFor(content)
                    
                    attrText = NSMutableAttributedString(attributedString: self.attributedText)
                    attrText.replaceCharacters(
                        in: memorizationContentRange,
                        with: ""
                    )
                    attrText.insert(
                        parsedAttrContent,
                        at: memorizationContentRange.location
                    )
                    self.attributedText = attrText
                    
                    let contentLengthDiff = parsedAttrContent.string.count - memorizationContentRange.length
                    // Update word2memorizationContentRange for the current word.
                    let updatedMemorizationContentRange = NSRange(
                        location: memorizationContentRange.location,
                        length: parsedAttrContent.string.count
                    )
                    self.word2memorizationContentRange[word] = updatedMemorizationContentRange
                    // Update word2memorizationContentRange for other words, if needed.
                    for (anotherWord, memorizationContentRangeOfAnotherWord) in self.word2memorizationContentRange {
                        if memorizationContentRangeOfAnotherWord.location > updatedMemorizationContentRange.upperBound {
                            self.word2memorizationContentRange[anotherWord] = NSRange(
                                location: memorizationContentRangeOfAnotherWord.location + contentLengthDiff,
                                length: memorizationContentRangeOfAnotherWord.length
                            )
                        }
                    }
                    // Update memorizationContentRefreshIconRange2wordAndStatus for other words, if needed.
                    for (memorizationContentRefreshIconRange, wordAndStatus) in self.memorizationContentRefreshIconRange2wordAndStatus {
                        if memorizationContentRefreshIconRange.location > hitRange.location {
                            self.memorizationContentRefreshIconRange2wordAndStatus.removeValue(forKey: memorizationContentRefreshIconRange)
                            self.memorizationContentRefreshIconRange2wordAndStatus[NSRange(
                                location: memorizationContentRefreshIconRange.location + contentLengthDiff,
                                length: memorizationContentRefreshIconRange.length
                            )] = wordAndStatus
                        }
                    }
                }
            }
        }
        
        return true
        
    }
    
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
    
    func highlight(_ textRange: UITextRange, with color: UIColor?) {
        textStorage.addAttributes(
            [.backgroundColor: color as Any],
            range: nsRange(from: textRange)
        )
    }
    
    func highlightAll(with color: UIColor?) {
        for wordInfo in wordsInfo {
            highlight(
                wordInfo.textRange,
                with: color
            )
        }
    }
    
    func highlightAll() {
        for wordInfo in wordsInfo {
            var color: UIColor = Colors.newWordHighlightingColor
            if !wordInfo.canDelete {
                color = Colors.oldWordHighlightingColor
            }
            highlight(
                wordInfo.textRange,
                with: color
            )
        }
    }
    
    func imageAttributedString(with icon: UIImage) -> NSAttributedString {
        let textAttachment = NSTextAttachment()
        textAttachment.image = icon
        
        // Use the line height of the font for the image height to align with the text height
        let font = (defaultTextAttributes[.font] as? UIFont) ?? UIFont.systemFont(ofSize: Sizes.smallFontSize)
        let lineHeight = font.lineHeight
        // Adjust the width of the image to maintain the aspect ratio, if necessary
        let aspectRatio = textAttachment.image!.size.width / textAttachment.image!.size.height
        let imageWidth = lineHeight * aspectRatio
        textAttachment.bounds = CGRect(
            x: 0,
            y: (font.capHeight - lineHeight) / 2,
            width: imageWidth,
            height: lineHeight
        )
        
        return NSAttributedString(attachment: textAttachment)
    }
    
    private func generateWordMemorizationContent(for word: String, completion: @escaping (String?) -> Void) {
        
        guard !word.strip().isEmpty else {
            return
        }
        
        let prompt = Strings.wordMemorizationPrompt
            .replacingOccurrences(
                of: Strings.wordMemorizationLanguageNamePlaceHolder,
                with: Strings.languageNamesOfAllLanguages[LangCode.currentLanguage]![.en]!
            )
            .replacingOccurrences(
                of: Strings.wordMemorizationWordPlaceHolder,
                with: word
            )
            .replacingOccurrences(
                of: "English/English",
                with: "English"
            )
        contentCreatorForWordMemorization.createContent(withPrompt: prompt) { content in
            guard var content = content else {
                completion(nil)
                return
            }
            content = content.strip()
                .replacingOccurrences(of: Strings.windowsNewLineSymbol, with: "\n")
                .replacingOccurrences(of: Strings.macNewLineSymbol, with: "\n")
                .replaceMultipleBlankLinesWithSingleLine()
                .replacingOccurrences(of: "\n\n", with: "\n")
            completion(content)
        }
    }
    
    private func parseBoldingFor(_ content: String) -> NSAttributedString {
        
        // https://chatgpt.com/share/eebcc408-a5a9-496f-821e-afbbf0519931
        
        let mutableAttrStr = NSMutableAttributedString(
            string: content,
            attributes: defaultWordMemorizationTextAttributes
        )
        
        guard let font = defaultWordMemorizationTextAttributes[.font] as? UIFont else {
            return mutableAttrStr
        }
        let boldFont = UIFont.boldSystemFont(ofSize: font.pointSize)
        
        let pattern = "\\*\\*(.*?)\\*\\*"
        let regex = try? NSRegularExpression(
            pattern: pattern,
            options: .dotMatchesLineSeparators
        )
        let matches = regex?.matches(
            in: content,
            options: [],
            range: NSRange(
                location: 0,
                length: content.utf16.count
            )
        )
        
        for match in matches ?? [] {
            let range = match.range(at: 1)
            let nsRange = NSRange(
                location: range.location,
                length: range.length
            )
            mutableAttrStr.addAttribute(
                .font,
                value: boldFont,
                range: nsRange
            )
        }
        
        // Remove all **.
        mutableAttrStr.replacingAll(
            "**",
            with: ""
        )
        
        return mutableAttrStr
        
    }
    
}

extension WordMarkingTextView {
    
    // MARK: - Selectors
    
    @objc private func somewhereInTextViewTapped(recognizer: UITapGestureRecognizer) {
        
        let location: CGPoint = recognizer.location(in: self)
        // https://stackoverflow.com/questions/22348076/is-it-possible-to-create-uitextrange-manually-for-first-character
        guard let tapPosition: UITextPosition = closestPosition(to: location) else {
            return
        }
        
        guard let anotherTapLocation: UITextPosition = position(
            from: tapPosition,
            offset: 0
        ) else {
            return
        }
        guard let tappedTextRange = textRange(
            from: tapPosition,
            to: anotherTapLocation
        ) else {
            return
        }
        tappedAt(tappedTextRange)
        
    }
    
    @objc private func newWordMenuItemTapped() {

        // Obtain the new word, its selected range, and its selected text range.
        if let selectedTextRange = selectedTextRange,
            !selectedTextRange.isEmpty,
            let word = text(in: selectedTextRange) {
            
            // Store the info of the new word.
            currentWordInfo = WordInfo(
                textRange: selectedTextRange,
                word: word,
                meaning: ""  // Added later.
            )
            
            if wordMarkingBottomView.isFloatingUp {
                // Float down the presenting bottom view, if any.
                wordMarkingBottomView.floatDown()
                wordMarkingBottomView.clear()
            }
            wordMarkingBottomView.word = word
            wordMarkingBottomView.floatUp()
            
            isAddingNewWord = true
        }
    }
    
    @objc private func wordMeaningMenuItemTapped() {
        // Obtain the meaning of the selected word.
        if let selectedTextRange = selectedTextRange,
            !selectedTextRange.isEmpty,
            let meaning = text(in: selectedTextRange) {
            
            currentWordInfo.meaning = meaning
            wordMarkingBottomView.meaning = meaning
        }
    }
    
    @objc
    private func wordMemorizationMenuItemTapped() {
        
        if let selectedTextRange = selectedTextRange,
           !selectedTextRange.isEmpty,
           let word = text(in: selectedTextRange) {
            
            word2memorizationContentRange[word] = NSRange(
                location: 0, 
                length: 0
            )  // Placeholder for hiding the menu item..
            generateWordMemorizationContent(for: word) { content in
                
                guard let content = content else {
                    // Rollback.
                    self.word2memorizationContentRange.removeValue(forKey: word)
                    return
                }
                let parsedAttrContent = self.parseBoldingFor(content)
                
                DispatchQueue.main.async {
                    
                    let attrText = NSMutableAttributedString(attributedString: self.attributedText)
                    
                    attrText.append(NSAttributedString(
                        string: "\n\n",
                        attributes: self.defaultWordMemorizationTextAttributes
                    ))
                    
                    self.memorizationContentRefreshIconRange2wordAndStatus[NSRange(
                        location: attrText.length,
                        length: 1
                    )] = (
                        word: word,
                        isRegenerating: false
                    )
                    attrText.append(self.imageAttributedString(with: Images.wordMemorizationContentRefreshingImage))
                    
                    let wordAttrStr = NSMutableAttributedString(
                        string: " \(word):\n",
                        attributes: self.defaultWordMemorizationTextAttributes
                    )
                    wordAttrStr.bold(for: NSRange(
                        location: 1,  // 1: for the space.
                        length: word.count
                    ))
                    attrText.append(wordAttrStr)
                    
                    self.word2memorizationContentRange[word] = NSRange(
                        location: attrText.length,
                        length: parsedAttrContent.string.count
                    )
                    attrText.append(parsedAttrContent)
                    
                    self.attributedText = attrText
                    
                }
            }
        }
    }
    
}

extension WordMarkingTextView {
        
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {

        if !canAddNewWord {
            return false
        }
        if
            let selectedTextRange = selectedTextRange,
            memorizationContentRefreshIconRange2wordAndStatus.keys.contains(nsRange(from: selectedTextRange)) {
            return false
        }

        if action == #selector(copy(_:)) {
            return true
        }
        if !isAddingNewWord && action == #selector(newWordMenuItemTapped) {
            return true
        }
        if isAddingNewWord && action == #selector(wordMeaningMenuItemTapped) {
            return true
        }
        if action == #selector(wordMemorizationMenuItemTapped) {
            if
                let selectedTextRange = selectedTextRange,
                !selectedTextRange.isEmpty,
                let word = text(in: selectedTextRange) {
                
                if word2memorizationContentRange.keys.contains(word) {
                    return false
                } else {
                    return true
                }
            }
        }
        return false
      
    }
    
}

extension WordMarkingTextView: NewWordBottomViewDelegate {
    
    // MARK: - NewWordAddingBottomView Delegate
    
    func addNewWord() {
        
        // Add the word.
        wordsInfo.append(currentWordInfo)
        
        wordMarkingBottomView.floatDown()
        wordMarkingBottomView.clear()
        
        isAddingNewWord = false
        
        // Highlight the new word.
        let selectedRange = currentWordInfo.textRange
        highlight(
            selectedRange,
            with: defaultHighlightingColor
        )
    }
    
    func deleteNewWord() {
        
        // Find the index of the word to delete.
        var index: Int?
        for i in 0..<wordsInfo.count {
            if wordsInfo[i].textRange == currentSelectedTextRange {
                index = i
            }
        }
        guard let indexToDelete = index else {
            return
        }
        // Delete the word.
        let removedWordInfo = wordsInfo.remove(at: indexToDelete)
        
        wordMarkingBottomView.floatDown()
        wordMarkingBottomView.clear()
        
        // Remove the highlight.
        let selectedRange = removedWordInfo.textRange
        highlight(
            selectedRange,
            with: backgroundColor
        )
        // The code above will remove the background colors
        // of the overlapped ranges, which need to be recovered.
//        highlightAll(with: defaultHighlightingColor)
        highlightAll()
    }
    
    func meaningTextFieldEditingChanged() {
        currentWordInfo.meaning = wordMarkingBottomView.meaning
    }
}

struct WordInfo {
    // For storing the info of a newly added word.
    
    var textRange: UITextRange
    
    var word: String
    var meaning: String
    
    var canDelete: Bool = true
    
}

extension WordMarkingTextView {

    // MARK: - Constants
    
    static let newWordBottomViewVerticalPadding: CGFloat = 20
    
}
