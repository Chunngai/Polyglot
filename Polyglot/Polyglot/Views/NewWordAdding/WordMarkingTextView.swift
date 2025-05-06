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
    
    // Text attributes.
    var defaultTextAttributes: [NSAttributedString.Key : Any] = [
        .foregroundColor: Colors.normalTextColor,
        .backgroundColor: Colors.defaultBackgroundColor
    ]
    var defaultHighlightingColor: UIColor = Colors.newWordHighlightingColor
    
    // Content generation.
    
    var contentCreator: ContentCreator = ContentCreator(.gpt4o)
    var wordTranslator: MachineTranslator!
    
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
        
    var isColorAnimating = true
    lazy var colorAnimationOriginalColor: UIColor = defaultTextAttributes[.foregroundColor] as? UIColor ?? Colors.normalTextColor
    lazy var colorAnimationIntermediateColor: UIColor = Colors.inactiveTextColor
    // For storing the original text length.
    var originalTextLength: Int!
    
    // MARK: - Controllers
    
    var contentGenerationDelegate: WordMarkingTextViewContentGenerationDelegate!
    var urlOpenDelegate: WordMarkingTextViewURLOpenDelegate!
    var tappingDelegate: WordMarkingTextViewTappingDelegate!
    
    private var sharedMenuController = UIMenuController.shared
    
    // MARK: - Views
    
    private var newWordMenuItem: UIMenuItem!  // https://www.youtube.com/watch?v=s-LW_4ypwZo
    private var wordMeaningMenuItem: UIMenuItem!
    private var wordMemorizationMenuItem: UIMenuItem!
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
            wordMemorizationMenuItem,
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
    
    private func generatorAndPrompt(word: String, generationType: ContentGenerationType) -> (
        generator: (String, String, @escaping (String?) -> Void) -> Void,
        prompt: String
    ) {
        var generator: (String, String, @escaping (String?) -> Void) -> Void
        var prompt = ""
        switch generationType {
        case .memorization:
            generator = generateContentWithLLM
            prompt = Strings.wordMemorizationPrompt
                .replacingOccurrences(
                    of: Strings.wordMarkingTextViewContentGenerationLanguageNamePlaceHolder,
                    with: Strings.languageNamesOfAllLanguages[LangCode.currentLanguage]![.en]!
                )
                .replacingOccurrences(
                    of: Strings.wordMarkingTextViewContentGenerationWordPlaceHolder,
                    with: word
                )
                .replacingOccurrences(
                    of: "English/English",
                    with: "English"
                )
        case .translation:
            generator = generateWordTranslationContent
        case .explanation:
            generator = generateContentWithLLM
            prompt = Strings.grammarExplanationPrompt
                .replacingOccurrences(
                    of: Strings.wordMarkingTextViewContentGenerationLanguageNamePlaceHolder,
                    with: Strings.languageNamesOfAllLanguages[LangCode.currentLanguage]![.en]!
                )
                .replacingOccurrences(
                    of: Strings.wordMarkingTextViewContentGenerationWordPlaceHolder,
                    with: word
                )
        }
        
        return (
            generator: generator,
            prompt: prompt
        )
    }
    
    private func generateContentWithLLM(for word: String, with prompt: String, completion: @escaping (String?) -> Void) {
        
        guard !word.strip().isEmpty else {
            completion(nil)
            return
        }
        
        contentCreator.createContent(
            withPrompt: prompt,
            displayErrorMessageWhenFailed: true
        ) { content in
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
            
//            completion("This is a string with **B1**, *I1***B2**, *I2*, ***B3***, *I3*, **B4**, *I4*, **B5**, *I5*.")
        }
    }
    
    private func generateWordTranslationContent(for word: String, with prompt: String = "", completion: @escaping (String?) -> Void) {
        // The param "prompt" is not used in this method. It is for alignment with generateContentWithLLM().
        
        guard !word.isEmpty else {
            completion(nil)
            return
        }
        
        wordTranslator.translate(
            query: word,
            displayErrorMessageWhenFailed: true
        ) { translations, _ in
            guard !translations.isEmpty else {
                completion(nil)
                return
            }
            let concatTranslation = translations.joined(separator: "; ").strip()
            completion(concatTranslation)
        }
    }
    
    private func parseBoldAndItalics(for content: String) -> NSAttributedString {

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
    
    private func display(_ generatedContent: NSAttributedString, for word: String) -> (
        refreshIconNSRange: NSRange,
        generatedContentNSRange: NSRange
    ) {
        let attrText = NSMutableAttributedString(attributedString: self.attributedText)
        
        attrText.append(NSAttributedString(
            string: "\n\n",
            attributes: Self.contentGenerationTextAttributes
        ))
        
        let refreshIconNSRange = NSRange(
            location: attrText.length,
            length: 1
        )
        attrText.append(NSAttributedString(
            string: Strings.refreshingSymbol,
            attributes: Self.contentGenerationRefreshingIconAttributes
        ))
        attrText.setTextColor(
            for: refreshIconNSRange,
            with: Colors.activeSystemButtonColor
        )
        
        let wordAttrStr = NSMutableAttributedString(
            string: " \(word):\n",
            attributes: Self.contentGenerationTextAttributes
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
    
    private func generateContent(word: String, generationType: ContentGenerationType) {
        
        // Float down the presenting bottom view, if any.
        if wordMarkingBottomView.isFloatingUp {
            wordMarkingBottomView.floatDown()
            wordMarkingBottomView.clear()
        }
        
        let contentGenerationInfoForThisWord = ContentGenerationInfo(
            word: word,
            generationType: generationType
        )
        // Here `contentGenerationInfoForThisWord` functions as a placeholder for hiding the "memorization"/"translation" menu item.
        // It not set here, the corresponding menu item still appears before the generation completes.
        contentGenerationInfoList.append(contentGenerationInfoForThisWord)
        let contentGenerationInfoIndexForThisWord = contentGenerationInfoList.count - 1
        
        self.contentGenerationDelegate.startedContentGeneration(wordMarkingTextView: self)
                        
        // Store original text colors (e.g., black colors for normal texts and red colors for wrong characters in clozes)
        // for text color restoring after the color animation.
        var originalRange2Color: [NSRange: UIColor] = [:]
        self.attributedText.enumerateAttribute(
            .foregroundColor,
            in: NSRange(
                location: 0,
                length: self.attributedText.length
            ),
            options: []
        ) { value, range, _ in
            if let color = value as? UIColor {
                originalRange2Color[range] = color
            }
        }
        
        if originalTextLength == nil {
            // When generating content after having generated content for a word,
            // only animate the original text instead of the whole text that contains
            // the previously generated content.
            self.originalTextLength = attributedText.length
        }
        let colorAnimationRange = NSRange(
            location: 0,
            length: originalTextLength
        )
        
        self.isColorAnimating = true
        self.startTextColorTransitionAnimation(for: colorAnimationRange)
        
        let (generator, prompt) = generatorAndPrompt(
            word: word,
            generationType: generationType
        )
        generator(
            word,
            prompt
        ) { content in
            
            self.isColorAnimating = false
            
            DispatchQueue.main.async {
                self.contentGenerationDelegate.completedContentGeneration(
                    wordMarkingTextView: self,
                    content: content
                )
                
                // Recover to the original color.
                for (range, color) in originalRange2Color {
                    self.textStorage.setTextColor(
                        for: range,
                        with: color
                    )
                }
            }
            
            guard let content = content else {
                // Rollback.
                // Do not directly remove the info, as changing the arr length may affect the assignments in haveTappedRefreshButtonForGeneratedContent().
                self.contentGenerationInfoList[contentGenerationInfoIndexForThisWord] = nil
                return
            }
            
            let parsedAttrContent = self.parseBoldAndItalics(for: content)
            DispatchQueue.main.async {
                let (refreshIconNSRange, generatedContentNSRange) = self.display(parsedAttrContent, for: word)
                self.contentGenerationInfoList[contentGenerationInfoIndexForThisWord]?.refreshIconNSRange = refreshIconNSRange
                self.contentGenerationInfoList[contentGenerationInfoIndexForThisWord]?.contentNSRange = generatedContentNSRange
                
//                self.scrollRangeToVisible(refreshIconNSRange)
            }
        }
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
                if self.contentGenerationInfoList[i]?.refreshIconNSRange == r {
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
        textStorage.addAttributes(
            [NSAttributedString.Key.foregroundColor : Colors.inactiveSystemButtonColor],
            range: self.contentGenerationInfoList[generatedContentInfoIndex]!.refreshIconNSRange
        )
        
        // Regenerate the content.
        contentGenerationDelegate.startedContentGeneration(wordMarkingTextView: self)
        
        self.startTextColorTransitionAnimation(for: self.contentGenerationInfoList[generatedContentInfoIndex]!.contentNSRange)
        self.isColorAnimating = true

        let (generator, prompt) = generatorAndPrompt(
            word: self.contentGenerationInfoList[generatedContentInfoIndex]!.word,
            generationType: self.contentGenerationInfoList[generatedContentInfoIndex]!.generationType
        )
        generator(
            self.contentGenerationInfoList[generatedContentInfoIndex]!.word,
            prompt
        ) { content in
            
            self.isColorAnimating = false

            DispatchQueue.main.async {
                self.contentGenerationDelegate.completedContentGeneration(
                    wordMarkingTextView: self,
                    content: content
                )
            }
            
            // Enable regeneration.
            self.contentGenerationInfoList[generatedContentInfoIndex]!.isGenerating = false
            
            DispatchQueue.main.async {
                
                // Make the refresh button black.
                self.textStorage.addAttributes(
                    [NSAttributedString.Key.foregroundColor : Colors.activeSystemButtonColor],
                    range: self.contentGenerationInfoList[generatedContentInfoIndex]!.refreshIconNSRange
                )

                let oldContent = self.text(in: self.textRange(from: self.contentGenerationInfoList[generatedContentInfoIndex]!.contentNSRange)!)!
                guard
                    let content = content,
                    content != oldContent
                else {
                    // Recover to the original color for the original content range.
                    self.textStorage.setTextColor(
                        for: self.contentGenerationInfoList[generatedContentInfoIndex]!.contentNSRange,
                        with: self.colorAnimationOriginalColor
                    )
                    return
                }
                
                let parsedAttrContent = self.parseBoldAndItalics(for: content)
                
                // Update the content for the word.
                // DO NOT REPLACE DIRECTLY WITH THE ATTRIBUTED parsedAttrContent (NSAttributedString).
                // REPLACE WITH parsedAttrContent.string (String).
                // For the former case, the following will lead to content size changing (and thus text clipping).
                // (1) Generate memorization content for a phrase
                // (2) Translate a phrase
                // (3) Re-translate the phrase
                
                // Replace String with String.
                let attrText = NSMutableAttributedString(attributedString: self.attributedText)
                attrText.replaceCharacters(
                    in: self.contentGenerationInfoList[generatedContentInfoIndex]!.contentNSRange,  // Old content range.
                    with: parsedAttrContent.string
                )
                self.attributedText = attrText
                
                // Update the content range of the current word.
                self.contentGenerationInfoList[generatedContentInfoIndex]!.contentNSRange = NSRange(
                    location: self.contentGenerationInfoList[generatedContentInfoIndex]!.contentNSRange.location,
                    length: parsedAttrContent.string.count
                )
                
                // Update content attrs.
                self.textStorage.addAttributes(
                    Self.contentGenerationTextAttributes,
                    range: self.contentGenerationInfoList[generatedContentInfoIndex]!.contentNSRange
                )
                parsedAttrContent.enumerateAttributes(in: NSRange(
                    location: 0,
                    length: parsedAttrContent.length
                )) { attrs, r, _ in
                    guard let font = attrs[.font] as? UIFont else {
                        return
                    }
                    
                    let fontTraits = font.fontDescriptor.symbolicTraits
                    if fontTraits.contains(.traitBold) || fontTraits.contains(.traitItalic) {
                        self.textStorage.addAttributes(
                            [NSAttributedString.Key.font : font],
                            range: NSRange(
                                location: self.contentGenerationInfoList[generatedContentInfoIndex]!.contentNSRange.location + r.location,
                                length: r.length
                            )
                        )
                    }
                }
                
                // Recover to the original color for the NEW content range.
                self.textStorage.setTextColor(
                    for: self.contentGenerationInfoList[generatedContentInfoIndex]!.contentNSRange,
                    with: self.colorAnimationOriginalColor
                )
                
                // Length diff before&after the regeneration
                // for updating ranges of words after the current word.
                let contentLengthDiff = parsedAttrContent.string.count - oldContent.count
                // Update the ranges of other words, if needed.
                for i in 0..<self.contentGenerationInfoList.count {
                    guard self.contentGenerationInfoList[i] != nil else {
                        continue
                    }
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
        
        guard let word = selectedWord else {
            return
        }
        
        generateContent(
            word: word,
            generationType: .memorization
        )
        
    }
    
    @objc
    private func wordTranslationMenuItemTapped() {
        
        guard let word = selectedWord else {
            return
        }
        
        generateContent(
            word: word,
            generationType: .translation
        )
        
    }
    
    @objc
    private func grammarExplanationMenuItemTapped() {
        
        guard let word = selectedWord else {
            return
        }
        
        generateContent(
            word: word,
            generationType: .explanation
        )
        
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
            if isDeletingReinforcementWord {
                return false
            }
            return true
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
        if action == #selector(wordMemorizationMenuItemTapped) {
            if let word = selectedWord {
                let wordsToMemorize = contentGenerationInfoList.compactMap { c in
                    c?.generationType == .memorization
                    ? c?.word
                    : nil
                }
                return !wordsToMemorize.contains(word)
            }
        }
        if action == #selector(wordTranslationMenuItemTapped) {
            if let word = selectedWord {
                let translatedWords = contentGenerationInfoList.compactMap { c in
                    c?.generationType == .translation
                    ? c?.word
                    : nil
                }
                return !translatedWords.contains(word)
            }
        }
        if action == #selector(grammarExplanationMenuItemTapped) {
            if let word = selectedWord {
                let wordsToExplain = contentGenerationInfoList.compactMap { c in
                    c?.generationType == .explanation
                    ? c?.word
                    : nil
                }
                return !wordsToExplain.contains(word)
            }
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

protocol WordMarkingTextViewContentGenerationDelegate {
    
    func startedContentGeneration(wordMarkingTextView: WordMarkingTextView)
    func completedContentGeneration(wordMarkingTextView: WordMarkingTextView, content: String?)
}

protocol WordMarkingTextViewURLOpenDelegate {
    
    func openURL(wordMarkingTextView: WordMarkingTextView, urlString: String)
    
}

protocol WordMarkingTextViewTappingDelegate {
    
    func tapped(at tappedTextRange: UITextRange)
    
}
