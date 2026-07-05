//
//  WordMarkingTextView.swift
//  Polyglot
//
//  Created by Sola on 2022/12/31.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class WordMarkingTextView: UITextView, UITextViewDelegate, TextAnimationDelegate {
    
    // New word adding.
    
    var currentWordInfo: WordInfo = WordInfo(  // Store the info of the new word being added.
        textRange: UITextRange(),
        word: "",
        meaning: ""
    )
    var wordsInfo: [WordInfo] = []
    
    var isAddingNewWord: Bool = false
    
    // Reinforcement word adding.
    
    var reinforcementWordsInfo: [WordInfo] = []
    
    // Should be reset to false in two situations.
    // 1) when the cancel-reinforcement item is tapped.
    // In this situation, reset the value in the func somewhereInTextViewTapped.
    // 2) when somewhere on the screen is tapped.
    // In this situation, reset the value in the func cancelReinforcementMenuItemTapped.
    private var isDeletingReinforcementWord: Bool = false
    
    private var indexOfReinforcementWordToDelete: Int?
    
    // For deleting new words.
    var currentSelectedTextRange: UITextRange!
    
    var canMarkWords: Bool = true
    var tapGestureRecognizer: UITapGestureRecognizer!
    
    // Text attributes.
    var defaultTextAttributes: [NSAttributedString.Key : Any] = [
        .foregroundColor: Colors.normalTextColor,
        .backgroundColor: Colors.defaultBackgroundColor
    ]
    var defaultHighlightingColor: UIColor = Colors.newWordHighlightingColor
    
    // Content generation.

    var textLang: LangCode!
    var meaningLang: LangCode!

    var contentCreator: ContentCreator = ContentCreator()
    var wordTranslator: MachineTranslator!

    // Chat.
    var chatSystemPrompt: String = ""
    var chatMessages: [[String: String]] = []
    
    enum ContentGenerationType {
        case memorization
        case translation
        case explanation
    }
    
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

    var isColorAnimating = false
    lazy var colorAnimationOriginalColor: UIColor = defaultTextAttributes[.foregroundColor] as? UIColor ?? Colors.normalTextColor
    lazy var colorAnimationIntermediateColor: UIColor = Colors.inactiveTextColor
    var originalTextLength: Int!

    // MARK: - Controllers

    var contentGenerationDelegate: WordMarkingTextViewContentGenerationDelegate!
    var urlOpenDelegate: WordMarkingTextViewURLOpenDelegate!
    var tappingDelegate: WordMarkingTextViewTappingDelegate!
    weak var chatDelegate: WordMarkingTextViewChatDelegate?
    
    private var sharedMenuController = UIMenuController.shared
    
    // MARK: - Views
    
    private var newWordMenuItem: UIMenuItem!
    private var wordMeaningMenuItem: UIMenuItem!
    private var wordTranslationMenuItem: UIMenuItem!
    private var grammarExplanationMenuItem: UIMenuItem!
    private var searchMenuItem: UIMenuItem!
    private var reinforceMenuItem: UIMenuItem!
    private var cancelReinforcementMenuItem: UIMenuItem!
    
    private var menuItems: [UIMenuItem]!
    
    var wordMarkingBottomView: WordMarkingBottomView!
    
    // MARK: - Init
    
    init(frame: CGRect = .zero, textContainer: NSTextContainer? = nil, textLang: LangCode, meaningLang: LangCode) {
        super.init(frame: frame, textContainer: textContainer)

        self.textLang = textLang
        self.meaningLang = meaningLang

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
        
        wordMarkingBottomView.offset = wordMarkingBottomView.frame.height + 20
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
        wordTranslationMenuItem = UIMenuItem(
            title: Strings.translationToken,
            action: #selector(wordTranslationMenuItemTapped)
        )
        grammarExplanationMenuItem = UIMenuItem(
            title: Strings.grammarExplanationMenuItemString,
            action: #selector(grammarExplanationMenuItemTapped)
        )
        searchMenuItem = UIMenuItem(
            title: Strings.searchMenuItemString,
            action: #selector(searchMenuItemTapped)
        )
        reinforceMenuItem = UIMenuItem(
            title: Strings.reinforceMenuItemString,
            action: #selector(reinforceMenuItemTapped)
        )
        cancelReinforcementMenuItem = UIMenuItem(
            title: Strings.cancelReinforcementMenuItemString,
            action: #selector(cancelReinforcementMenuItemTapped)
        )
        menuItems = [
            newWordMenuItem,
            wordMeaningMenuItem,
            wordTranslationMenuItem,
            grammarExplanationMenuItem,
            searchMenuItem,
            reinforceMenuItem,
        ]
        sharedMenuController.menuItems = menuItems
        
        wordMarkingBottomView.delegate = self

    }

}

extension WordMarkingTextView {
    
    // MARK: - Utils
    
    private var selectedWord: String? {
        if let selectedTextRange = selectedTextRange,
           !selectedTextRange.isEmpty,
           let word = text(in: selectedTextRange) {
            return word
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
    
    // MARK: - Underlining
    
    func underline(_ textRange: UITextRange, with color: UIColor?) {
        textStorage.addAttributes(
            [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .underlineColor: color as Any
            ],
            range: nsRange(from: textRange)
        )
    }
    
    func underlineAll() {
        for reinforcementWordInfo in reinforcementWordsInfo {
            var color: UIColor = Colors.newReinforcementWordUnderlineColor
            if !reinforcementWordInfo.canDelete {
                color = Colors.oldReinforcementWordUnderlineColor
            }
            underline(
                reinforcementWordInfo.textRange,
                with: color
            )
        }
    }
    
}

extension WordMarkingTextView {

    // MARK: - Content Generation

    // Sends translate/explain actions as chat bubbles via chatDelegate.
    func sendChatMessageForAction(word: String, generationType: ContentGenerationType) {
        guard !word.strip().isEmpty else { return }

        let textLangName = Strings.languageNamesOfAllLanguages[textLang]?[.en] ?? textLang.rawValue
        let meaningLangName = Strings.languageNamesOfAllLanguages[meaningLang]?[.en] ?? meaningLang.rawValue

        let systemPrompt: String
        let userMessage: String

        switch generationType {
        case .translation:
            systemPrompt = """
You are a language tutor helping a \(meaningLangName) speaker learn \(textLangName). The user will give you a \(textLangName) word or phrase to translate. Use the surrounding context to inform the translation.

Reply in \(meaningLangName) using this exact format:
**[full translation]**
- [word1] → [translation1]
- [word2] → [translation2]
...
"""
            userMessage = "\(Strings.translateActionToken(for: meaningLang)) \"\(word)\""
        case .explanation:
            systemPrompt = """
You are a language tutor helping a \(meaningLangName) speaker learn \(textLangName). The user will give you a \(textLangName) word or phrase. Identify the key grammar points in it — for example, fixed expressions, grammatical structures, case usage, verb forms, or idiomatic patterns. For each grammar point, give its name and a brief explanation of how it works. Be concise. Respond in \(meaningLangName).
"""
            userMessage = "\(Strings.explainActionToken(for: meaningLang)) \"\(word)\""
        case .memorization:
            return
        }

        chatMessages.append(["role": "user", "content": userMessage])
        chatDelegate?.chatDidSendMessage(userMessage)

        var accumulated = ""
        contentCreator.streamContent(
            withSystemPrompt: systemPrompt,
            conversationMessages: chatMessages,
            onChunk: { [weak self] chunk in
                accumulated += chunk
                self?.chatDelegate?.chatDidReceiveChunk(chunk)
            },
            onFinish: { [weak self] in
                if !accumulated.isEmpty {
                    self?.chatMessages.append(["role": "assistant", "content": accumulated])
                }
                self?.chatDelegate?.chatDidFinish()
            },
            onError: { [weak self] in
                self?.chatDelegate?.chatDidFail()
            }
        )
    }

    fileprivate func parseBoldAndItalics(for content: String) -> NSAttributedString {

        // https://chatgpt.com/share/eebcc408-a5a9-496f-821e-afbbf0519931
        // https://chatgpt.com/share/67335ac0-e5b8-800d-938a-047efc72b189
        
        let attrText = NSMutableAttributedString(
            string: content,
            attributes: Self.contentGenerationTextAttributes
        )
        
        func parse(
            fontTrait: UIFontDescriptor.SymbolicTraits,
            parsingPattern: String,
            markerLength: Int
        ) {
           
            let regex = try? NSRegularExpression(
                pattern: parsingPattern,
                options: .dotMatchesLineSeparators
            )
            let matches = regex?.matches(
                in: attrText.string,
                options: [],
                range: NSRange(
                    location: 0,
                    length: attrText.string.utf16.count
                )
            ) ?? []
            
            var matchedPhraseRanges: [NSRange] = []
            var matchedMarkerPairRanges: [(left: NSRange, right: NSRange)] = []
            for m in matches {
                matchedPhraseRanges.append(m.range(at: 2))
                matchedMarkerPairRanges.append((
                    left: m.range(at: 1),
                    right: m.range(at: 3)
                ))
            }
            
            // Add traits to font.
            for m in matchedPhraseRanges {
                let attrs = attrText.attributes(
                    at: m.location,
                    effectiveRange: nil
                )
                guard let font = attrs[.font] as? UIFont else {
                    continue
                }
                
                let fontDescriptor = font.fontDescriptor
                let combinedTraits = fontDescriptor.symbolicTraits.union(fontTrait)
                if let newFontDescriptor = fontDescriptor.withSymbolicTraits(combinedTraits) {
                    attrText.addAttributes(
                        [NSAttributedString.Key.font : UIFont(
                            descriptor: newFontDescriptor,
                            size: font.pointSize
                        )],
                        range: m
                    )
                }
                
            }
            
            // Remove markers.
            var offset: Int = 0
            for p in matchedMarkerPairRanges {
                var leftRange = p.left
                var rightRange = p.right
                
                leftRange = NSRange(
                    location: leftRange.location + offset,
                    length: leftRange.length
                )
                attrText.replaceCharacters(in: leftRange, with: "")
                
                rightRange = NSRange(
                    location: rightRange.location + offset - markerLength,  // - markerLength: for the left replacement above.
                    length: rightRange.length
                )
                attrText.replaceCharacters(in: rightRange, with: "")
                
                offset -= markerLength * 2
            }
            
        }
        
        parse(
            fontTrait: UIFontDescriptor.SymbolicTraits.traitBold,
            parsingPattern: "(\\*\\*)(.*?)(\\*\\*)",
            markerLength: 2  // **
        )
        parse(
            fontTrait: UIFontDescriptor.SymbolicTraits.traitItalic,
            parsingPattern: "(\\*)(.*?)(\\*)",
            markerLength: 1  // *
        )

        return attrText
    }

    func sendChatMessage(_ userMessage: String) {
        guard !userMessage.strip().isEmpty else { return }

        chatMessages.append(["role": "user", "content": userMessage])
        chatDelegate?.chatDidSendMessage(userMessage)

        var accumulatedReply = ""
        contentCreator.streamContent(
            withSystemPrompt: chatSystemPrompt,
            conversationMessages: chatMessages,
            onChunk: { [weak self] chunk in
                guard let self = self else { return }
                accumulatedReply += chunk
                self.chatDelegate?.chatDidReceiveChunk(chunk)
            },
            onFinish: { [weak self] in
                guard let self = self else { return }
                if !accumulatedReply.isEmpty {
                    self.chatMessages.append(["role": "assistant", "content": accumulatedReply])
                }
                self.chatDelegate?.chatDidFinish()
            },
            onError: { [weak self] in
                self?.chatDelegate?.chatDidFail()
            }
        )
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

        // For canceling selections
        // & handling memorization content regeneration
        // & presenting an added new word.
        // https://stackoverflow.com/questions/48474488/get-tapped-word-in-a-uitextview

        wordMarkingBottomView.meaningTextField.resignFirstResponder()
        // Cancel the selection if any.
        resignFirstResponder()
        tappingDelegate.selectionDidClear()
        
        // When a new word is being added, do nothing.
        if isAddingNewWord {
            return
        }
        
        // Float down the presenting bottom view, if any.
        if wordMarkingBottomView.isFloatingUp {
            wordMarkingBottomView.floatDown()
            wordMarkingBottomView.clear()
        }
        
        let tapPositionValue = valueOf(textPosition: tappedTextRange.start)
        // If there exists a word whose upper bound == attributedText.length - 1,
        // the bottom view for the word will be floated up when tapping
        // anywhere below the text.
        // The following condition is to avoid it.
        if tapPositionValue == attributedText.length {
            return
        }
        
        // Present an added new word.
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
        
        isDeletingReinforcementWord = false
        // Present a word for reinforcement.
        for (i, reinforcementWordInfo) in reinforcementWordsInfo.enumerated() {
            
            let wordTextRange: UITextRange = reinforcementWordInfo.textRange
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
            if isTextRangeTapped && reinforcementWordInfo.canDelete {

                isDeletingReinforcementWord = true
                indexOfReinforcementWordToDelete = i
                
                // https://chatgpt.com/share/679f363c-694c-800d-aa6b-37d27ae9b76b
                sharedMenuController.menuItems = [cancelReinforcementMenuItem]
                sharedMenuController.setTargetRect(
                    CGRect(
                        x: location.x,
                        y: location.y,
                        width: 0,
                        height: 0
                    ),
                    in: self
                )
                sharedMenuController.setMenuVisible(
                    true,
                    animated: true
                )
                
                // Restore the menu items.
                sharedMenuController.menuItems = menuItems
                
                break  // Avoid overlapped highlighting.
            }
        }
        
        tappingDelegate.tapped(at: tappedTextRange)
        
    }
    
    @objc private func newWordMenuItemTapped() {

        // Obtain the new word, its selected range, and its selected text range.
        if 
            let selectedTextRange = selectedTextRange,
            !selectedTextRange.isEmpty,
            var word = text(in: selectedTextRange) 
        {
            
            word = word
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: Strings.windowsNewLineSymbol, with: " ")
                .replacingOccurrences(of: Strings.macNewLineSymbol, with: " ")
            
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
    private func wordTranslationMenuItemTapped() {
        guard let word = selectedWord else { return }
        sendChatMessageForAction(word: word, generationType: .translation)
    }

    @objc
    private func grammarExplanationMenuItemTapped() {
        guard let word = selectedWord else { return }
        sendChatMessageForAction(word: word, generationType: .explanation)
    }
    
    @objc
    private func searchMenuItemTapped() {
        
        guard let word = selectedWord?.strip() else {
            return
        }
        
        var urlString = "https://www.google.com/search?q=conjugation for \(word)"
        if LangCode.currentLanguage == .es {
            urlString = "https://www.spanishdict.com/conjugate/\(word)"
        }
        if LangCode.currentLanguage == .ru {
            urlString = "https://en.openrussian.org/ru/яблоко?search=\(word)"
        }
        
        urlOpenDelegate.openURL(wordMarkingTextView: self, urlString: urlString)
        
    }
    
    @objc
    private func reinforceMenuItemTapped() {
        
        // Obtain the word to reinforce, its selected range, and its selected text range.
        if let selectedTextRange = selectedTextRange,
            !selectedTextRange.isEmpty,
            let word = text(in: selectedTextRange) {

            // Store the info of the reinforcement word.
            reinforcementWordsInfo.append(WordInfo(
                textRange: selectedTextRange,
                word: word,
                meaning: ""
            ))
            underline(
                selectedTextRange,
                with: Colors.newReinforcementWordUnderlineColor
            )
        }
        
    }
    
    @objc func cancelReinforcementMenuItemTapped() {
                
        guard let indexOfReinforcementWordToDelete = indexOfReinforcementWordToDelete else {
            return
        }
        
        let removedReinforcementWordInfo = reinforcementWordsInfo.remove(at: indexOfReinforcementWordToDelete)
        
        // Remove the underline.
        underline(
            removedReinforcementWordInfo.textRange,
            with: backgroundColor
        )
        // The code above will remove the background colors
        // of the overlapped ranges, which need to be recovered.
        underlineAll()
        
        isDeletingReinforcementWord = false
        
    }
    
}

extension WordMarkingTextView {
        
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {

        if action == #selector(copy(_:)) {
            if isDeletingReinforcementWord {
                return false
            }
            return true
        }
        
        if !canMarkWords {
            return false
        }
        
        if !isAddingNewWord && action == #selector(newWordMenuItemTapped) {
            if let word = selectedWord {
                return !wordsInfo.map { wordInfo in
                    wordInfo.word
                }.contains(word)
            }
//            return true
        }
        if isAddingNewWord && action == #selector(wordMeaningMenuItemTapped) {
            return true
        }
        if action == #selector(wordTranslationMenuItemTapped) {
            return selectedWord != nil
        }
        if action == #selector(grammarExplanationMenuItemTapped) {
            return selectedWord != nil
        }
        if action == #selector(searchMenuItemTapped) {
            return true
        }
        if action == #selector(reinforceMenuItemTapped) {
            return true
        }
        if action == #selector(cancelReinforcementMenuItemTapped) && isDeletingReinforcementWord {
            return true
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
        
    static let contentGenerationTextAttributes: [NSAttributedString.Key : Any] = Attributes.defaultLongTextAttributes(fontSize: Sizes.smallFontSize)
    static let contentGenerationRefreshingIconAttributes: [NSAttributedString.Key : Any] = Attributes.defaultLongTextAttributes(fontSize: Sizes.mediumFontSize)
    
}

protocol WordMarkingTextViewChatDelegate: AnyObject {
    func chatDidSendMessage(_ userMessage: String)
    func chatDidReceiveChunk(_ chunk: String)
    func chatDidFinish()
    func chatDidFail()
}

protocol WordMarkingTextViewContentGenerationDelegate {
    
    func startedContentGeneration(wordMarkingTextView: WordMarkingTextView)
    func completedContentGeneration(wordMarkingTextView: WordMarkingTextView, content: String?)
}

protocol WordMarkingTextViewURLOpenDelegate {
    
    func openURL(wordMarkingTextView: WordMarkingTextView, urlString: String)
    
}

protocol WordMarkingTextViewTappingDelegate {
    func tapped(at tappedTextRange: UITextRange)
    func selectionDidClear()
}
