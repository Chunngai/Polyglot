//
//  ListenAndRepeatPracticeView.swift
//  Polyglot
//
//  Created by Ho on 2/7/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

struct BiGram: Codable, Hashable {
    var leftToken: String = ""
    var rightToken: String = ""
}

struct BiRange: Codable {
    var leftRange: NSRange = NSRange()
    var rightRange: NSRange = NSRange()
}

class ListenAndRepeatPracticeView: TextMeaningPracticeView {
    
    var clozeRanges: [NSRange]!
    private var matchedClozeRanges: Set<NSRange> = []
    private var unmatchedClozeRanges: Set<NSRange> {
        Set(clozeRanges).subtracting(matchedClozeRanges)
    }
    
    // For typing clozed words.
    private var isSubmitted: Bool = false {
        didSet {
            if isSubmitted {
                textView.canAddNewWord = true
            } else {
                textView.canAddNewWord = false
            }
        }
    }
    private var selectedRangeWhenBecomingFirstResponderAgain: NSRange!
    private var edittedAttrCharRangeToOriginalAttrChar: [NSRange: NSAttributedString] = [:]
    private var edittedAttrCharRange: NSRange?
    private var attributedTextBeforeEditting: NSAttributedString?
    private var canIncreaseTextLength: Bool = true
    private var isAdjustingSelectedRange: Bool = false
    
    private var textBiGram2BiRanges: [BiGram: [BiRange]] = [:]  // A bi-gram may correspond to multiple bi-ranges.
    
    private var shouldProcessRecognizedSpeech: Bool = true
    
    // MARK: - Controllers
    
    var delegate: ListeningPracticeViewController! {
        didSet {
            delegate.canRecord = true
            // Before submitting.
            delegate.enableIQKeyboardManager()
        }
    }
    
    // MARK: - Init
    
    init(
        frame: CGRect = .zero,
        text: String,
        meaning: String,
        textLang: LangCode,
        meaningLang: LangCode,
        textSource: TextSource,
        isTextMachineTranslated: Bool,
        machineTranslatorType: MachineTranslatorType,
        clozeRanges: [NSRange],
        existingPhraseRanges: [NSRange],
        existingPhraseMeanings: [String],
        totalRepetitions: Int,
        currentRepetition: Int,
        textAccentLocs: [Int]
    ) {
        super.init(
            frame: frame,
            text: text,
            meaning: meaning,
            textLang: textLang,
            meaningLang: meaningLang,
            textSource: textSource,
            isTextMachineTranslated: isTextMachineTranslated,
            machineTranslatorType: machineTranslatorType,
            existingPhraseRanges: existingPhraseRanges,
            existingPhraseMeanings: existingPhraseMeanings,
            totalRepetitions: totalRepetitions,
            currentRepetition: currentRepetition,
            textAccentLocs: textAccentLocs
        )
        
        self.clozeRanges = clozeRanges
        
        upperString = text
        lowerString = meaning
        if textSource == .chatGpt {
            upperIcon = Icons.chatgptIcon
        }
        if isTextMachineTranslated {
            lowerIcon = translatorIcon
        }
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func updateSetups() {
        super.updateSetups()
        
        var updatedText = text ?? ""
        // Handle inconsistent word splitting. E.g., 인공지능/인공 지능.
        if LangCode.currentLanguage == .ko {
            let koTokens = text.tokenized(with: LangCode.currentLanguage.wordTokenizer)
            for i in 0..<koTokens.count - 1 {
                updatedText += " " + koTokens[i] + koTokens[i + 1]
            }
        }
        textBiGram2BiRanges = generateBiGram2BiRanges(for: updatedText)
        
        isSubmitted = false
        // When the attributed text of the text view is set in `displayUpper()`,
        // `textViewDidChangeSelection()` will be called and the selected location
        // will be equal to the length of the text.
        selectedRangeWhenBecomingFirstResponderAgain = NSRange(
            location: text.count, 
            length: 0
        )
    }
    
    override func updateViews() {
        super.updateViews()
        
        makeClozes()
    }
    
    // MARK: - Methods from the Super Class
    
    override func displayUpper() {
        
        super.displayUpper()
        
        if textSource == .chatGpt {
            for i in 0..<clozeRanges.count {
                clozeRanges[i].location += 2  // One for the icon and one for the space.
            }
            for (biGram, biRanges) in textBiGram2BiRanges {
                for i in 0..<biRanges.count {
                    textBiGram2BiRanges[biGram]![i].leftRange.location += 2
                    textBiGram2BiRanges[biGram]![i].rightRange.location += 2
                }
            }
            for i in 0..<existingPhraseRanges.count {
                existingPhraseRanges[i].location += 2
            }
            for i in 0..<textAccentLocs.count {
                textAccentLocs[i] += 2
            }
        }
        
        markAccents(at: textAccentLocs)
        
    }
    
    override func displayLower() {
        super.displayLower()
        
        markAccents(at: textAccentLocs)
    }
    
    override func submit() -> Any {
        
        isSubmitted = true
        delegate.disableIQKeyboardManager()
        restoreIncorrectTypedWords()
        
        return Array<NSRange>(matchedClozeRanges)
    }
    
    override func updateViewsAfterSubmission() {
        
        super.updateViewsAfterSubmission()
        
        // If the practice is submitted without turning off the mic,
        // the processRecognizedSpeech() func will still be called where
        // recognized clozes are set with background colors,
        // leading to invalid new phrase highlighting.
        shouldProcessRecognizedSpeech = false
        
        displayUnmatchedText()
        highlightExistingPhrases(
            existingPhraseRanges: existingPhraseRanges,
            existingPhraseMeanings: existingPhraseMeanings
        )
    }
}

extension ListenAndRepeatPracticeView: ListeningPracticeViewControllerDelegate {
    
    private func generateBiGram2BiRanges(for text: String) -> [BiGram: [BiRange]] {
        let ranges = text.tokenRanges
        guard ranges.count > 1 else {
            if ranges.count == 0 {
                return [BiGram(): []]
            } else {  // ranges.count == 1
                let range = ranges[0]
                let token = (text as NSString).substring(with: range)
                return [BiGram(leftToken: preprocess(token)): [BiRange(leftRange: range)]]
            }
        }
        
        var biGram2BiRanges: [BiGram: [BiRange]] = [:]
        for i in 0..<ranges.count - 1 {
            let leftRange = ranges[i]
            let rightRange = ranges[i + 1]
            guard clozeRanges.contains(leftRange) || clozeRanges.contains(rightRange) else {
                continue
            }
            
            var leftToken = (text as NSString).substring(with: leftRange)
            leftToken = preprocess(leftToken)
            var rightToken = (text as NSString).substring(with: rightRange)
            rightToken = preprocess(rightToken)
            
            let biGram = BiGram(
                leftToken: leftToken,
                rightToken: rightToken
            )
            let biRange = BiRange(
                leftRange: leftRange,
                rightRange: rightRange
            )
            
            if biGram2BiRanges.keys.contains(biGram) {
                biGram2BiRanges[biGram]!.append(biRange)
            } else {
                biGram2BiRanges[biGram] = [biRange]
            }
        }
        
        return biGram2BiRanges
    }
    
    private func generateBiGrams(from tokens: [String]) -> Set<BiGram> {
        guard tokens.count > 1 else {
            if tokens.count == 0 {
                return [BiGram()]
            } else {  // tokens.count == 1
                return [BiGram(leftToken: preprocess(tokens[0]))]
            }
        }
        
        var biGrams: Set<BiGram> = []
        for i in 0..<tokens.count - 1 {
            var leftToken = tokens[i]
            leftToken = preprocess(leftToken)
            var rightToken = tokens[i + 1]
            rightToken = preprocess(rightToken)
            
            let biGram = BiGram(
                leftToken: leftToken,
                rightToken: rightToken
            )
            biGrams.insert(biGram)
        }
        
        return biGrams
    }
    
    private func preprocess(_ text: String) -> String {
        var text = text
        if textLang == LangCode.ja {
            text = convertJapaneseToRomaji(text: text)
        }
        text = text.lowercased()
        if textLang == LangCode.en {
            text = convertUSSpellingToUKSpelling(text: text)
        }
        if textLang == LangCode.ru {
            text = convertRussianJoToJe(text: text)
        }
        if text.isNumericText {
            text = text.numericRepresentation ?? text
        }
        return text
    }
    
    // MARK: - ListeningPracticeViewController Delegate
    
    func processRecognizedSpeech(_ text: String) {
        guard shouldProcessRecognizedSpeech else {
            return
        }
        
        var speechTokens = text.tokenized(with: LangCode.currentLanguage.wordTokenizer)
        if LangCode.currentLanguage == .ko {  // Handle inconsistent word splitting.
            let nKoTokens = speechTokens.count
            for i in 0..<nKoTokens - 1 {
                speechTokens.append(speechTokens[i] + speechTokens[i + 1])
            }
        }
        let speechBiGrams = generateBiGrams(from: speechTokens)
        
        let newAttributes = NSMutableAttributedString(attributedString: textView.attributedText!)
        let biGramOverlaps = Set(textBiGram2BiRanges.keys).intersection(speechBiGrams)
        for biGramOverlap in biGramOverlaps {
            guard let biRangeOverlaps = textBiGram2BiRanges[biGramOverlap] else {
                continue
            }
            for biRangeOverlap in biRangeOverlaps {
                for range in [biRangeOverlap.leftRange, biRangeOverlap.rightRange] {
                    if clozeRanges.contains(range) {
                        newAttributes.setTextColor(
                            for: range,
                            with: textView.defaultTextAttributes[.foregroundColor] as! UIColor
                        )
                        newAttributes.setBackgroundColor(
                            for: range,
                            with: textView.defaultTextAttributes[.backgroundColor] as! UIColor
                        )
                        matchedClozeRanges.insert(range)
                    }
                }
            }
        }
        textView.attributedText = newAttributes
        
        if matchedClozeRanges.count == clozeRanges.count {
            delegate.submitAndNext()
        }
    }
    
}

extension ListenAndRepeatPracticeView {
    
    private func makeClozes() {
        let attributedText = NSMutableAttributedString(attributedString: textView.attributedText!)
        for clozeRange in clozeRanges {
            attributedText.setTextColor(
                for: clozeRange,
                with: Colors.clozeMaskColor
            )
            attributedText.setBackgroundColor(
                for: clozeRange,
                with: Colors.clozeMaskColor
            )
        }
        textView.attributedText = attributedText
    }
    
    private func displayUnmatchedText() {
        let newAttributes = NSMutableAttributedString(attributedString: textView.attributedText!)
        for clozeRange in unmatchedClozeRanges {
            newAttributes.setTextColor(
                for: clozeRange,
                with: Colors.incorrectColor
            )
            newAttributes.setBackgroundColor(
                for: clozeRange,
                with: mainView.backgroundColor!
            )
        }
        textView.attributedText = newAttributes
    }
    
    private func checkTypedWordCorrectness() {
        var typedWord: String = ""
        var targetWord: String = ""
        var currentLocation = textView.selectedRange.location
        var rangesToRemove: [NSRange] = []
        while true {
            currentLocation -= 1
            if currentLocation < 0 {
                break
            }
            
            let bgColorOfCurrentLocation = textView.attributedText.backgroundColor(at: currentLocation)
            if bgColorOfCurrentLocation != Colors.clozeMaskColor {
                break
            }
            
            let charAtCurrentRange = NSRange(
                location: currentLocation,
                length: 1
            )
            // https://stackoverflow.com/questions/3836670/how-to-get-a-single-nsstring-character-from-an-nsstring
            let currentChar = textView.attributedText.attributedSubstring(from: charAtCurrentRange).string
            typedWord = currentChar + typedWord
            
            if let originalCharInTargetWord = edittedAttrCharRangeToOriginalAttrChar[charAtCurrentRange]?.string {
                targetWord = originalCharInTargetWord + targetWord
                rangesToRemove.append(charAtCurrentRange)
            }
        }
        
        if typedWord.normalized(
            shouldStrip:true,
            caseInsensitive: true,
            diacriticInsensitive: true
        ) == targetWord.normalized(
            shouldStrip:true,
            caseInsensitive: true,
            diacriticInsensitive: true
        ) {
            let typedWordRange = NSRange(
                location: currentLocation + 1,  // +1: recover the -1.
                length: typedWord.count
            )
            matchedClozeRanges.insert(typedWordRange)
            textView.textStorage.addAttributes(
                [
                    .foregroundColor : textView.defaultTextAttributes[.foregroundColor] as! UIColor,
                    .backgroundColor : textView.defaultTextAttributes[.backgroundColor] as! UIColor
                ],
                range: typedWordRange
            )
            
            for rangeToRemove in rangesToRemove {
                edittedAttrCharRangeToOriginalAttrChar.removeValue(forKey: rangeToRemove)
            }
            
            let unmatchedClozeRanges = self.unmatchedClozeRanges
            if !unmatchedClozeRanges.isEmpty {  // Select the next cloze.
                
                var rangeOfNextCloze: NSRange = NSRange(
                    location: textView.attributedText.length,
                    length: 0
                )
                for unmatchedClozeRange in self.unmatchedClozeRanges {
                    if
                        unmatchedClozeRange.location - typedWordRange.location > 0  // So the unmatched range is after the typed range.
                        && unmatchedClozeRange.location < rangeOfNextCloze.location  // To get the nearest unmatched range.
                    {
                        rangeOfNextCloze = unmatchedClozeRange
                    }
                }
                
                isAdjustingSelectedRange = true
                textView.selectedRange = NSRange(
                    location: rangeOfNextCloze.location,
                    length: 0
                )
                isAdjustingSelectedRange = false
                
                // Otherwise the typped consonant (e.g., s) will attach to the previous typed char
                // if the previous typed char ends w/ a vowel (e.g., e).
                if LangCode.currentLanguage == .ko {
                    textView.resignFirstResponder()
                    textView.becomeFirstResponder()
                }
                
            } else {
                textView.resignFirstResponder()
            }
        }
        
        if matchedClozeRanges.count == clozeRanges.count {
            delegate.submitAndNext()
        }
        
    }
    
    private func restoreIncorrectTypedWords() {
        for (edittedCharRange, originalChar) in edittedAttrCharRangeToOriginalAttrChar {
            // https://stackoverflow.com/questions/9096710/how-to-replace-text-in-uitextview-with-selected-range
            textView.textStorage.replaceCharacters(
                in: edittedCharRange,
                with: originalChar
            )
        }
    }
    
    private func shouldMoveBackward(_ r: NSRange) -> Bool {
        
        let locOfPreviousChar = r.location - 1
        guard locOfPreviousChar >= 0 else {
            return false
        }
        
        let previousCharTextColor = textView.attributedText.textColor(at: locOfPreviousChar)
        let previousCharBgColor = textView.attributedText.backgroundColor(at: locOfPreviousChar)
        
        if
            (
                previousCharTextColor == textView.defaultTextAttributes[.foregroundColor] as! UIColor
                && previousCharBgColor == Colors.clozeMaskColor
            )
                || previousCharBgColor == textView.defaultTextAttributes[.backgroundColor] as! UIColor {
            return false
        }
        return true
        
    }
    
    private func adjustSelectedRange() {
                
        var selectedRange = textView.selectedRange
        while shouldMoveBackward(selectedRange) {
            let l = selectedRange.location - 1
            if l >= 0 {
                selectedRange = NSRange(
                    location: l,
                    length: selectedRange.length
                )
            } else {
                break
            }
        }
        textView.selectedRange = selectedRange
    }
    
}

extension ListenAndRepeatPracticeView {
    
    // MARK: - UITextView Delegate
    
    func textViewDidChange(_ textView: UITextView) {
        
        guard var edittedCharRange = edittedAttrCharRange,
              let attributedTextBeforeEditting = attributedTextBeforeEditting else {
            self.edittedAttrCharRange = nil
            self.attributedTextBeforeEditting = nil
            return
        }
        
        self.edittedAttrCharRange = nil
        self.attributedTextBeforeEditting = nil

        if attributedTextBeforeEditting.length < textView.attributedText.length {  // Insertion.

            guard canIncreaseTextLength else {
                // After the following line the selected location moves
                // to the end of the text.
                // If the cursor is also at the end of the text
                // when typing, unselectable place will be selectable
                // in textViewDidChangeSelection.
                // Therefore, resetting the selected range of the text view
                // is needed.
                textView.attributedText = attributedTextBeforeEditting
                textView.selectedRange = edittedCharRange
                return
            }
            
            // Obtain the original char.
            let originalCharLocation = edittedCharRange.location + 1
            guard originalCharLocation < textView.attributedText.length else {
                return
            }
            let originalCharRange: NSRange = NSRange(
                location: originalCharLocation,
                length: 1
            )
            let originalChar = textView.attributedText.attributedSubstring(from: originalCharRange)
            
            // Store the original char.
            // Store the char only when the editted char range has not been stored,
            // otherwise when deleting the char at the range, the char will be restored to
            // the previously typed (stored) char.
            if !edittedAttrCharRangeToOriginalAttrChar.keys.contains(edittedCharRange) {
                edittedAttrCharRangeToOriginalAttrChar[edittedCharRange] = originalChar
            }
            
            // Remove the original char.
            textView.textStorage.deleteCharacters(in: originalCharRange)
            
        } else if attributedTextBeforeEditting.length > textView.attributedText.length {  // Deletion.

            // Obtain and remove the original char from the mapping.
            guard let originalChar = edittedAttrCharRangeToOriginalAttrChar.removeValue(forKey: edittedCharRange) else {
                return
            }
            
            // Insert the original char to the original location.
            textView.textStorage.insert(
                originalChar,
                at: edittedCharRange.location
            )
                
        // Some Insertions/deletions for Korean and similar languages.
        // E.g., the newly inserted Korean symbol attaches to the previous character.
        // In this case, do nothing.
        } else {

            let newEdittedCharLocation = edittedCharRange.location - 1
            guard newEdittedCharLocation >= 0 else {
                return
            }
            edittedCharRange = NSRange(
                location: newEdittedCharLocation,
                length: 1
            )
            
        }

        // If the character before the editted character also has changed,
        // e.g., the consonant of the last Korean character attaches to the
        // current editted character, also should update the text attributes
        // of the last character. If not updated, the text attributes of
        // the last character will be lost.
        // For convenience, update the attributes of all editted ranges.
        if let textView = textView as? WordMarkingTextView {
            for edittedRange in edittedAttrCharRangeToOriginalAttrChar.keys {
                textView.textStorage.addAttributes(
                    [
                        .foregroundColor : textView.defaultTextAttributes[.foregroundColor] as! UIColor,
                        .backgroundColor: Colors.clozeMaskColor,
                        // If not set, the font of the typed word will be bold
                        // if the last char of the last word is set bold (accented)
                        // in Russian.
                            .font: textView.defaultTextAttributes[.font] as! UIFont
                    ],
                    range: edittedRange
                )
            }
        }

        // When finished typing a word, check its correctness.
        // Case 1: reached the end of the text.
        // Case 2: reached the word boundary.
        let bgColorOfNewSelectedLocationOfCharToReplace = textView.attributedText.backgroundColor(at: textView.selectedRange.location)
        if textView.selectedRange.location > self.text.count
            || bgColorOfNewSelectedLocationOfCharToReplace == textView.backgroundColor {
            checkTypedWordCorrectness()
        }
        
        // Explicitly call this method here instead of executing the code
        // in textViewDidChangeSelection after shouldChangeTextIn.
        textViewDidChangeSelection(textView)

    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        // https://stackoverflow.com/questions/61363193/how-to-keep-some-text-non-editable-and-some-editable-in-textview-swift
        
        guard !isSubmitted else {
            return false
        }
                
        let isInserting = !text.isEmpty
        if isInserting {
            // Only allow to insert a single char to a single location.
            guard range.length == 0
                    && text.count == 1 else {
                return false
            }
            
            if Character(text).isWhitespace {
                return false
            }
            
            let bgColorOfRangeOfCharToReplace = textView.attributedText.backgroundColor(at: range.location)
            if bgColorOfRangeOfCharToReplace == textView.backgroundColor {
                // In this case, the cursor is already at the end of the cloze,
                // and only deletion / typing Korean symbols are enabled.
                canIncreaseTextLength = false
            } else {
                canIncreaseTextLength = true
            }
            
            edittedAttrCharRange = NSRange(
                location: range.location,
                length: 1
            )
            
        } else {
            // Only allow to delete a single char at a single location.
            guard range.length == 1
                    && text.count == 0 else {
                return false
            }
            
            let bgColorOfRangeOfCharToReplace = textView.attributedText.backgroundColor(at: range.location)
            if bgColorOfRangeOfCharToReplace == textView.backgroundColor {
                // In this case, the character before the cloze word will be deleted,
                // which is not intended.
                return false
            }
            
            let textColorOfRangeOfCharToReplace = textView.attributedText.textColor(at: range.location)
            if textColorOfRangeOfCharToReplace == Colors.clozeMaskColor {
                // In this case, a clozed character is being deleted,
                // which is not intended.
                return false
            }
            
            edittedAttrCharRange = range
            
        }
                
        attributedTextBeforeEditting = textView.attributedText
        
        return true
        
    }
    
    // https://stackoverflow.com/questions/18553193/find-out-when-cursor-is-moved-uitextview
    override func textViewDidChangeSelection(_ textView: UITextView) {
        super.textViewDidChangeSelection(textView)
        
        // KNOWN ISSUE: WHEN MOVING THE CURSOR BY
        // LONG PRESSING THE WHITESPACE AND SWIPING,
        // THE ERROR "Keyboard queue task timeout detected"
        // WILL BE RAISED WHEN CALLING `textView.resignFirstResponder()`.
        
        guard !isSubmitted else {
            return
        }
        guard attributedTextBeforeEditting == nil else {
            // Calling order: shouldChangeTextIn -> textViewDidChangeSelection -> textViewDidChange.
            // For Korean, after shouldChangeTextIn is called, textView.attributedText may be raw,
            // e.g., ChatGPT가 적용된 빙 검색엔진은 (original text)
            // -> "ChatGPT가 적용된 ㅂ 검색엔진은"
            // -> "ChatGPT가 적용된 ㅂㅣ 검색엔진은".
            // Then, textViewDidChangeSelection will be called.
            // Since textView.attributedText may be raw at this point,
            // the code in textViewDidChangeSelection may lead to unexpected results.
            // Therefore, skip here and instead call textViewDidChangeSelection at the end of textViewDidChange,
            // where textView.attributedText has been handled properly (text and attrs).
            // Note that the current implementation uses attributedTextBeforeEditting to determine
            // if it is typing, and that requires that attributedTextBeforeEditting is set to nil
            // properly.
            return
        }
        
        // When adjusting the selected range the current method may be called multiple times in a recursion.
        guard !isAdjustingSelectedRange else {
            return
        }
        
        let selectedRange = textView.selectedRange
        
        // If selected all, cancel the selection.
        // Else cannot edit after selecting all.
        if selectedRange == NSRange(
            location: 0,
            length: textView.attributedText.length
        ) {
            textView.selectedRange = NSRange(
                location: 0,
                length: 0
            )
            return
        }
        
        // If selected a whole cloze (by double tapping), cancel the selection.
        if selectedRange.length != 0 {
            textView.selectedRange = NSRange(
                location: 0,
                length: 0
            )
            return
        }
        
        guard selectedRange.location >= 0,
              selectedRange.location <= textView.text.count else {
            // Do not place the code in the next line in `textViewDidEndEditing()`,
            // as that method will only be called for isFirstResponder -> isNotFirstResponder.
            // However, `selectedRangeBeforeResigningToFirstResponder` should be modified
            // for both isFirstResponder -> isNotFirstResponder and isNotFirstResponder -> isNotFirstResponder.
            selectedRangeWhenBecomingFirstResponderAgain = textView.selectedRange
            textView.resignFirstResponder()
            return
        }
        
        let bgColorOfCharToReplace = textView.attributedText.backgroundColor(at: textView.selectedRange.location)
        let bgColorBeforeCharToReplace = {
            var positionBeforeCharToReplace: Int = textView.selectedRange.location - 1
            if positionBeforeCharToReplace <= 0 {
                positionBeforeCharToReplace += 1
            }
            let bgColorBeforeCharToReplace = textView.attributedText.backgroundColor(at: positionBeforeCharToReplace)
            return bgColorBeforeCharToReplace
        }()
        if bgColorOfCharToReplace == Colors.clozeMaskColor
            // Only allow deleting in the following case.
            || (
                bgColorOfCharToReplace == textView.backgroundColor
                && bgColorBeforeCharToReplace == Colors.clozeMaskColor
            ) {
            
            // Move the cursor to the beginning of the cloze
            // or to the next typped char in the cloze.
            isAdjustingSelectedRange = true
            adjustSelectedRange()
            isAdjustingSelectedRange = false
            
            textView.becomeFirstResponder()
            delegate.canRecord = false
            // Without the following line of code,
            // when tapping the end of the word after resigning
            // the cursor still appears.
            selectedRangeWhenBecomingFirstResponderAgain = textView.selectedRange
            
        } else {
            selectedRangeWhenBecomingFirstResponderAgain = textView.selectedRange
            textView.resignFirstResponder()
        }
        
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        
        guard !isSubmitted else {
            return false
        }
        
        // Note that:
        // (1) the selected range of the text view in `textViewShouldBeginEditing()`
        // is the one before previously resigning.
        // (2) `textViewDidChangeSelection()` will not be called after `textViewShouldBeginEditing()`
        // if the selected range before and after the text view becomes the first responder
        // is equal.
        // Therefore,
        // if (1) `textView.resignFirstResponder()` is called in `textViewDidChangeSelection()`
        // when somewhere not editable is selected/tapped,
        // and (2) the text view becomes the first responder again later when somewhere in
        // the text view is tapped,
        // and (3) the tapped range is equal to the selected range before resigning:
        // `textViewDidChangeSelection()` will not be called as
        // the selected range has not been changed -> the tapped range,
        // which is intended to be not editable, will become editable.
        // Therefore, check if the tapped range is editable here for that case.
        if let selectedRangeWhenBecomingFirstResponderAgain = selectedRangeWhenBecomingFirstResponderAgain,
           selectedRangeWhenBecomingFirstResponderAgain == textView.selectedRange {
            return false
        }
        
        return true
    }
    
}

protocol ListenAndRepeatPracticeViewDelegate {
    
    var countingButtons: [UIButton] { get }
    var shouldUpdatePractice: Bool { get set }
    var canRecord: Bool { get set }
    
    func submitAndNext()
    func enableIQKeyboardManager()
    func disableIQKeyboardManager()
    
}
