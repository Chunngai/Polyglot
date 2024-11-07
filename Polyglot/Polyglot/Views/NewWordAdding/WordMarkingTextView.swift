//
//  WordMarkingTextView.swift
//  Polyglot
//
//  Created by Sola on 2022/12/31.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class WordMarkingTextView: UITextView, UITextViewDelegate {
    
    var currentWordInfo: WordInfo = WordInfo(  // Store the info of the new word being added.
        textRange: UITextRange(),
        word: "",
        meaning: ""
    )
    var wordsInfo: [WordInfo] = []
    
    // For deleting new words.
    var currentSelectedTextRange: UITextRange!
    
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
    var defaultContentGenerationTextAttributes: [NSAttributedString.Key : Any] = Attributes.leftAlignedLongTextAttributes
    var defaultHighlightingColor: UIColor = Colors.newWordHighlightingColor
    
    enum ContentGenerationType {
        case memorization
        case translation
    }
    private var contentCreatorForWordMemorization: ContentCreator = ContentCreator(.gpt4o)
    private var wordTranslator: MachineTranslator!
    // Text font for generated content.
    private lazy var iconFontOfGeneratedContent: UIFont = (defaultTextAttributes[.font] as? UIFont) ?? UIFont.systemFont(ofSize: Sizes.smallFontSize)
    struct ContentGenerationInfo {
        var word: String

        var generationType: ContentGenerationType
        var isGenerating: Bool = false
        
        var refreshIconNSRange: NSRange = NSRange()
        var contentNSRange: NSRange = NSRange()
        
        init(word: String, generationType: ContentGenerationType) {
            self.word = word
            self.generationType = generationType
        }
        
    }
    var contentGenerationInfoList: [ContentGenerationInfo?] = []
        
    // MARK: - Views
    
    private var newWordMenuItem: UIMenuItem!  // https://www.youtube.com/watch?v=s-LW_4ypwZo
    private var wordMeaningMenuItem: UIMenuItem!
    private var wordMemorizationMenuItem: UIMenuItem!
    private var wordTranslationMenuItem: UIMenuItem!
    
    var wordMarkingBottomView: WordMarkingBottomView!
    
    // MARK: - Init
    
    init(frame: CGRect = .zero, textContainer: NSTextContainer? = nil, textLang: LangCode, meaningLang: LangCode) {
        super.init(frame: frame, textContainer: textContainer)
        
        wordMarkingBottomView = WordMarkingBottomView(
            wordLang: textLang,
            meaningLang: meaningLang
        )
        
        wordTranslator = MachineTranslator(
            srcLang: textLang,
            trgLang: meaningLang
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
        wordTranslationMenuItem = UIMenuItem(
            title: Strings.translationToken,
            action: #selector(wordTranslationMenuItemTapped)
        )
        UIMenuController.shared.menuItems = [
            newWordMenuItem,
            wordMeaningMenuItem,
            wordMemorizationMenuItem,
            wordTranslationMenuItem,
        ]
        
        wordMarkingBottomView.delegate = self

    }

}

extension WordMarkingTextView {
    
    // MARK: - Ranges
    
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
    
}

extension WordMarkingTextView {
    
    // MARK: - Highlighting
    
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
    
}

extension WordMarkingTextView {
    
    // MARK: - Generating Content for Memorization/Translation.
    
    private func generateWordMemorizationContent(for word: String, completion: @escaping (String?) -> Void) {
        
        guard !word.strip().isEmpty else {
            completion(nil)
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
    
    private func generateWordTranslationContent(for word: String, completion: @escaping (String?) -> Void) {
        
        guard !word.isEmpty else {
            completion(nil)
            return
        }
        
        wordTranslator.translate(query: word) { translations, _ in
            guard !translations.isEmpty else {
                completion(nil)
                return
            }
            let concatTranslation = translations.joined(separator: "; ").strip()
            completion(concatTranslation)
        }
    }
    
    private func display(_ generatedContent: NSAttributedString, for word: String) -> (
        refreshIconNSRange: NSRange,
        generatedContentNSRange: NSRange
    ) {
        let attrText = NSMutableAttributedString(attributedString: self.attributedText)
        
        attrText.append(NSAttributedString(
            string: "\n\n",
            attributes: self.defaultContentGenerationTextAttributes
        ))
        
        let refreshIconNSRange = NSRange(
            location: attrText.length,
            length: 1
        )
        attrText.append(self.imageAttributedString(
            icon: Images.wordMarkingTextViewContentGenerationRefreshingImage,
            font: self.iconFontOfGeneratedContent
        ))
        
        let wordAttrStr = NSMutableAttributedString(
            string: " \(word):\n",
            attributes: self.defaultContentGenerationTextAttributes
        )
        wordAttrStr.bold(for: NSRange(
            location: 1,  // 1: for the space.
            length: word.count
        ))
        attrText.append(wordAttrStr)
        
        let generatedContentNSRange = NSRange(
            location: attrText.length,
            length: generatedContent.string.count
        )
        attrText.append(generatedContent)
        
        self.attributedText = attrText
        
        return (
            refreshIconNSRange: refreshIconNSRange,
            generatedContentNSRange: generatedContentNSRange
        )
    }
    
    private func generateContent(for generationType: ContentGenerationType) {
        
        guard let selectedTextRange = selectedTextRange,
              !selectedTextRange.isEmpty,
              let word = text(in: selectedTextRange) else {
            return
        }
        
        // Float down the presenting bottom view, if any.
        if wordMarkingBottomView.isFloatingUp {
            wordMarkingBottomView.floatDown()
            wordMarkingBottomView.clear()
        }
        
        var contentGenerationInfoForThisWord = ContentGenerationInfo(
            word: word,
            generationType: generationType
        )
        // Here `contentGenerationInfoForThisWord` functions as a placeholder for hiding the "memorization"/"translation" menu item.
        // It not set here, the corresponding menu item still appears before the generation completes.
        contentGenerationInfoList.append(contentGenerationInfoForThisWord)
        let contentGenerationInfoIndexForThisWord = contentGenerationInfoList.count - 1
        
        var generator: (String, @escaping (String?) -> Void) -> Void = {
            switch generationType {
            case .memorization: return generateWordMemorizationContent
            case .translation: return generateWordTranslationContent
            }
        }()
        generator(word) { content in
            guard let content = content else {
                // Rollback.
                // Do not directly remove the info, as changing the arr length may affect the assignments in haveTappedRefreshButtonForGeneratedContent().
                self.contentGenerationInfoList[contentGenerationInfoIndexForThisWord] = nil
                return
            }
            
            let parsedAttrContent = self.parseBolding(for: content)
            DispatchQueue.main.async {
                let (refreshIconNSRange, generatedContentNSRange) = self.display(parsedAttrContent, for: word)
                self.contentGenerationInfoList[contentGenerationInfoIndexForThisWord]?.refreshIconNSRange = refreshIconNSRange
                self.contentGenerationInfoList[contentGenerationInfoIndexForThisWord]?.contentNSRange = generatedContentNSRange
            }
        }
    }
    
    private func parseBolding(for content: String) -> NSAttributedString {
        
        // https://chatgpt.com/share/eebcc408-a5a9-496f-821e-afbbf0519931
        
        let mutableAttrStr = NSMutableAttributedString(
            string: content,
            attributes: defaultContentGenerationTextAttributes
        )
        
        guard let font = defaultContentGenerationTextAttributes[.font] as? UIFont else {
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
    
    private func haveTappedRefreshButtonForGeneratedContent(tappedTextRange: UITextRange) -> Bool {
        
        let tappedRange = nsRange(from: tappedTextRange)
        
        // Do nothing if a "\n" is tapped.
        let tappedRangeWithLengthOne = NSRange(
            location: tappedRange.location,
            length: 1
        )
        guard let textRangeOfTappedRangeWithLengthOne = textRange(from: tappedRangeWithLengthOne),
              text(in: textRangeOfTappedRangeWithLengthOne) != "\n" else {
            return false
        }

        var generatedContentInfoIndex: Int? = nil
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
            for i in 0..<self.contentGenerationInfoList.count {
                if self.contentGenerationInfoList[i]!.refreshIconNSRange == r {
                    generatedContentInfoIndex = i
                    break
                }
            }
        }
        guard let generatedContentInfoIndex = generatedContentInfoIndex else {
            return false
        }

        // Do nothing if content for the word is being generated.
        guard !self.contentGenerationInfoList[generatedContentInfoIndex]!.isGenerating else {
            return false
        }
        // Disable regeneration.
        self.contentGenerationInfoList[generatedContentInfoIndex]!.isGenerating = true

        // Make the refresh button gray.
        let attrText = NSMutableAttributedString(attributedString: attributedText)
        attrText.replaceCharacters(
            in: self.contentGenerationInfoList[generatedContentInfoIndex]!.refreshIconNSRange,
            with: imageAttributedString(
                icon: Images.wordMarkingTextViewContentGenerationRefreshingImage.withTintColor(Colors.inactiveTextColor),
                font: iconFontOfGeneratedContent
            )
        )
        self.attributedText = attrText
        
        // Regenerate the content.
        var generator: (String, @escaping (String?) -> Void) -> Void = {
            switch self.contentGenerationInfoList[generatedContentInfoIndex]!.generationType {
            case .memorization: return generateWordMemorizationContent
            case .translation: return generateWordTranslationContent
            }
        }()
        generator(self.contentGenerationInfoList[generatedContentInfoIndex]!.word) { content in
            
            // Enable regeneration.
            self.contentGenerationInfoList[generatedContentInfoIndex]!.isGenerating = false
            
            DispatchQueue.main.async {
                
                // Make the refresh button black.
                var attrText = NSMutableAttributedString(attributedString: self.attributedText)
                attrText.replaceCharacters(
                    in: self.contentGenerationInfoList[generatedContentInfoIndex]!.refreshIconNSRange,
                    with: self.imageAttributedString(
                        icon: Images.wordMarkingTextViewContentGenerationRefreshingImage.withTintColor(Colors.normalTextColor),
                        font: self.iconFontOfGeneratedContent
                    )
                )
                self.attributedText = attrText
                
                // Update the content.
                guard let content = content else {
                    return
                }
                let parsedAttrContent = self.parseBolding(for: content)
                
                // Update the content for the word.
                attrText = NSMutableAttributedString(attributedString: self.attributedText)
                attrText.replaceCharacters(
                    in: self.contentGenerationInfoList[generatedContentInfoIndex]!.contentNSRange,
                    with: parsedAttrContent
                )
                self.attributedText = attrText
                
                // Length diff before&after the regeneration.
                let contentLengthDiff = parsedAttrContent.string.count - self.contentGenerationInfoList[generatedContentInfoIndex]!.contentNSRange.length
                // Update the content range of the current word.
                let updatedContentRange = NSRange(
                    location: self.contentGenerationInfoList[generatedContentInfoIndex]!.contentNSRange.location,
                    length: parsedAttrContent.string.count
                )
                self.contentGenerationInfoList[generatedContentInfoIndex]!.contentNSRange = updatedContentRange
                // Update the ranges of other words, if needed.
                for i in 0..<self.contentGenerationInfoList.count {
                    if self.contentGenerationInfoList[i]!.contentNSRange.location <= self.contentGenerationInfoList[generatedContentInfoIndex]!.contentNSRange.location {
                        continue
                    }
                    self.contentGenerationInfoList[i]!.refreshIconNSRange = NSRange(
                        location: self.contentGenerationInfoList[i]!.refreshIconNSRange.location + contentLengthDiff,
                        length: self.contentGenerationInfoList[i]!.refreshIconNSRange.length
                    )
                    self.contentGenerationInfoList[i]!.contentNSRange = NSRange(
                        location: self.contentGenerationInfoList[i]!.contentNSRange.location + contentLengthDiff,
                        length: self.contentGenerationInfoList[i]!.contentNSRange.length
                    )
                }
            }
        }
        
        return true
        
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
        
        // When a refresh button is tapped, regenerate the content.
        if haveTappedRefreshButtonForGeneratedContent(tappedTextRange: tappedTextRange) {
            return
        }
        
        // Float down the presenting bottom view, if any.
        if wordMarkingBottomView.isFloatingUp {
            wordMarkingBottomView.floatDown()
            wordMarkingBottomView.clear()
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
        generateContent(for: .memorization)
    }
    
    @objc
    private func wordTranslationMenuItemTapped() {
        generateContent(for: .translation)
    }
    
}

extension WordMarkingTextView {
        
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {

        if !canAddNewWord {
            return false
        }
        
        // Check if a refresh icon is tapped.
        let refreshIconNSRanges = contentGenerationInfoList.compactMap { c in
            c?.refreshIconNSRange
        }
        if refreshIconNSRanges.contains(selectedRange) {
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
                let wordsToMemorize = contentGenerationInfoList.compactMap { c in
                    c?.generationType == .memorization
                    ? c?.word
                    : nil
                }
                return !wordsToMemorize.contains(word)
            }
        }
        if action == #selector(wordTranslationMenuItemTapped) {
            if
                let selectedTextRange = selectedTextRange,
                !selectedTextRange.isEmpty,
                let word = text(in: selectedTextRange) {
                let translatedWords = contentGenerationInfoList.compactMap { c in
                    c?.generationType == .translation
                    ? c?.word
                    : nil
                }
                return !translatedWords.contains(word)
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
