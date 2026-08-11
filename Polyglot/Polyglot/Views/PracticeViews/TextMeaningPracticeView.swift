//
//  TextMeaningPracticeView.swift
//  Polyglot
//
//  Created by Ho on 2/7/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class TextMeaningPracticeView: BasePracticeView {
    
    var text: String!
    var meaning: String!
    var textLang: LangCode!
    var meaningLang: LangCode!
    var textSource: TextSource!
    var isTextMachineTranslated: Bool!
    var machineTranslatorType: MachineTranslatorType!
    var existingPhraseRanges: [NSRange]!
    var existingPhraseMeanings: [String]!
    var totalRepetitions: Int!
    var currentRepetition: Int!
    var textAccentLocs: [Int]!
    var verbAspectAnnotations: [VerbAspectAnnotation]!
    var nounCaseAnnotations: [NounCaseAnnotation]!
    var shortAdjectiveAnnotations: [ShortAdjectiveAnnotation]!

    var repetitionIncrement: Int!
    
    var upperString: String!
    var lowerString: String!
    
    var unselectableRanges: [NSRange] = []

    var rangeOfTranslatorIcon: NSRange?
    var rangeOfTranslationText: NSRange?
    
    var showsReinforceButton: Bool = true

    var shouldReinforce: Bool = false {
        didSet {
            if shouldReinforce {
                reinforceButton.tintColor = Colors.inactiveSystemButtonColor
                reinforceTextButton.setTitleColor(Colors.inactiveTextColor, for: .normal)
                
                totalRepetitions += repetitionIncrement
            } else {
                reinforceButton.tintColor = Colors.activeSystemButtonColor
                reinforceTextButton.setTitleColor(Colors.activeTextColor, for: .normal)
                
                totalRepetitions -= repetitionIncrement
            }
            
            updateRepetitionLabelText()
        }
    }
    
    // MARK: - Controllers
    
    var languageSelectionDelegate: TextMeaningPracticeViewDelegate!
    
    // MARK: - Views
    
    var mainView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.defaultBackgroundColor
        return view
    }()
    
    var textView: WordMarkingTextView!
    
    let listenButton: UIButton = {
        let button = Buttons.createControlButton(from: Images.listeningPracticeProduceSpeechImage)
        button.isEnabled = true
        return button
    }()
    let speakButton: UIButton = {
        let button = Buttons.createControlButton(from: Images.listeningPracticeStartToRecordSpeechImage)
        button.isEnabled = true
        return button
    }()
    lazy var controlsView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = Sizes.smallStackSpacing
        stackView.backgroundColor = Colors.lightGrayBackgroundColor
        stackView.layer.masksToBounds = true
        stackView.layer.cornerRadius = Sizes.defaultCornerRadius
        
        stackView.addArrangedSubview(listenButton)
        stackView.addArrangedSubview(speakButton)
        
        return stackView
    }()
    
    let reinforceButton: UIButton = {
        let button = UIButton()
        button.setImage(
            Images.textMeaningPracticeReinforceImage,
            for: .normal
        )
        button.backgroundColor = .none
        button.isHidden = true
        return button
    }()
    let reinforceTextButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.reinforce, for: .normal)
        button.setTitleColor(Colors.activeSystemButtonColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        button.backgroundColor = .none
        button.isHidden = true
        return button
    }()
    
    let repetitionsLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.weakTextColor
        label.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        label.textAlignment = .center
        return label
    }()
    
    var contentGenerationSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        return spinner
    }()

    // Chat bubble panel.
    lazy var contentScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        return sv
    }()
    lazy var chatBubblesStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        sv.alignment = .fill
        sv.isHidden = true
        return sv
    }()
    lazy var chatTypingIndicator: UIActivityIndicatorView = {
        let ind = UIActivityIndicatorView(style: .medium)
        ind.hidesWhenStopped = true
        return ind
    }()
    private weak var currentAIBubbleLabel: UILabel?
    private var currentAIBubbleText: String = ""

    // Chat input bar.
    lazy var chatInputBar: UIView = {
        let v = UIView()
        v.backgroundColor = Colors.lightGrayBackgroundColor
        v.layer.cornerRadius = Sizes.defaultCornerRadius
        v.layer.masksToBounds = true
        return v
    }()
    lazy var chatTextField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        tf.placeholder = "Ask a language question..."
        tf.returnKeyType = .send
        tf.delegate = self
        tf.addTarget(self, action: #selector(chatTextFieldChanged), for: .editingChanged)
        return tf
    }()
    lazy var chatSendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        btn.tintColor = Colors.inactiveSystemButtonColor
        btn.isEnabled = false
        btn.addTarget(self, action: #selector(chatSendButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    var translatorIcon: UIImage {
        switch machineTranslatorType {
        case .google: return Icons.googleTranslateIcon
        case .gpt: return Icons.chatgptIcon
        case .baidu: return Icons.baiduTranslateIcon
        default: return UIImage.init(systemName: "questionmark.square.dashed")!
        }
    }
    
    var upperIcon: UIImage?
    var lowerIcon: UIImage?
    lazy var iconFont: UIFont = textView.defaultTextAttributes[.font] as! UIFont

    private lazy var legendView: GrammarAnnotationLegendView = GrammarAnnotationLegendView()

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
        existingPhraseRanges: [NSRange],
        existingPhraseMeanings: [String],
        totalRepetitions: Int,
        currentRepetition: Int,
        textAccentLocs: [Int],
        verbAspectAnnotations: [VerbAspectAnnotation] = [],
        nounCaseAnnotations: [NounCaseAnnotation] = [],
        shortAdjectiveAnnotations: [ShortAdjectiveAnnotation] = [],
        repetitionIncrement: Int
    ) {
        super.init(frame: frame)

        self.text = text
        self.meaning = meaning
        self.textLang = textLang
        self.meaningLang = meaningLang
        self.textSource = textSource
        self.isTextMachineTranslated = isTextMachineTranslated
        self.machineTranslatorType = machineTranslatorType
        self.existingPhraseRanges = existingPhraseRanges
        self.existingPhraseMeanings = existingPhraseMeanings
        self.totalRepetitions = totalRepetitions
        self.currentRepetition = currentRepetition
        self.textAccentLocs = textAccentLocs
        self.verbAspectAnnotations = verbAspectAnnotations
        self.nounCaseAnnotations = nounCaseAnnotations
        self.shortAdjectiveAnnotations = shortAdjectiveAnnotations
        self.repetitionIncrement = repetitionIncrement
        
        textView = {
            let textView = WordMarkingTextView(
                textLang: textLang,
                meaningLang: meaningLang
            )
            
            textView.textContainerInset = UIEdgeInsets(
                top: textView.textContainerInset.top,
                left: textView.textContainerInset.left,
                bottom: textView.textContainerInset.bottom,
                right: textView.textContainerInset.right
            )
            
            textView.showsVerticalScrollIndicator = false
            textView.showsHorizontalScrollIndicator = false
            
            textView.defaultTextAttributes = {
                var attrs = Attributes.defaultLongTextAttributes(fontSize: Sizes.mediumFontSize)
                // IMPORTANT TO ENSURE THAT THE CHARS IN THE INITIAL TEXT
                // HAVE THE SAME BG COLOR WITH THE TEXT VIEW, OTHERWISE
                // CLOZE TYPING WILL NOT WORK PROPERLY.
                attrs[.backgroundColor] = textView.backgroundColor
                return attrs
            }()
            textView.attributedText = NSMutableAttributedString(
                string: " ",
                attributes: textView.defaultTextAttributes
            )
            
            return textView
        }()
        
        updateRepetitionLabelText()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func updateSetups() {
        textView.delegate = self
        textView.contentGenerationDelegate = self
        textView.tappingDelegate = self

        reinforceButton.addTarget(
            self,
            action: #selector(reinforceButtonTapped),
            for: .touchUpInside
        )
        reinforceTextButton.addTarget(
            self,
            action: #selector(reinforceButtonTapped),
            for: .touchUpInside
        )

        textView.chatDelegate = self

        chatTextField.placeholder = Strings.chatPlaceholder(for: meaningLang)

        let langName = Strings.languageNamesOfAllLanguages[textLang]?[.en] ?? textLang.rawValue
        var systemPrompt = "You are a helpful language tutor. The user is studying \(langName). The current text is:\n\n\(text!)"
        if let m = meaning, !m.isEmpty {
            let meaningLangName = Strings.languageNamesOfAllLanguages[meaningLang]?[.en] ?? meaningLang.rawValue
            systemPrompt += "\n\nTranslation (\(meaningLangName)): \(m)"
        }
        systemPrompt += "\n\nAnswer questions about vocabulary, grammar, or expressions in this text. Be concise."
        textView.chatSystemPrompt = systemPrompt

        let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tap.cancelsTouchesInView = false
        mainView.addGestureRecognizer(tap)
    }
    
    func updateViews() {
        addSubview(mainView)

        contentScrollView.addSubview(textView)
        contentScrollView.addSubview(chatBubblesStack)
        contentScrollView.addSubview(chatTypingIndicator)
        mainView.addSubview(contentScrollView)

        mainView.addSubview(controlsView)
        mainView.addSubview(reinforceButton)
        mainView.addSubview(reinforceTextButton)
        mainView.addSubview(repetitionsLabel)
        mainView.addSubview(contentGenerationSpinner)
        mainView.addSubview(legendView)

        chatInputBar.addSubview(chatTextField)
        chatInputBar.addSubview(chatSendButton)
        mainView.addSubview(chatInputBar)

        displayUpper()
    }

    func updateLayouts() {
        mainView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentScrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(legendView.snp.top).offset(-4)
        }
        // textView is non-scrolling; its height is driven by content.
        textView.isScrollEnabled = false
        textView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.width.equalTo(contentScrollView)
        }
        chatBubblesStack.snp.makeConstraints { make in
            make.top.equalTo(textView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.width.equalTo(contentScrollView)
            make.bottom.equalToSuperview().inset(8)
        }
        chatTypingIndicator.snp.makeConstraints { make in
            make.top.equalTo(chatBubblesStack.snp.bottom).offset(4)
            make.leading.equalToSuperview()
        }
        controlsView.snp.makeConstraints { make in
            make.width.equalTo(200)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(20)
            make.height.equalTo(60)
        }
        chatInputBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Sizes.roundButtonRadius / 2)
            make.bottom.equalTo(controlsView.snp.top).offset(-8)
            make.height.equalTo(44)
        }
        chatTextField.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.trailing.equalTo(chatSendButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
        chatSendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
        reinforceButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Sizes.roundButtonRadius / 2)
            make.centerY.equalTo(controlsView.snp.centerY)
        }
        repetitionsLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(listenButton.snp.centerY)
        }
        contentGenerationSpinner.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(legendView.snp.top).offset(-40)
        }
        legendView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Sizes.roundButtonRadius / 2)
            make.bottom.equalTo(chatInputBar.snp.top).offset(-8)
        }
    }
    
    func displayUpper() {
        let attributedText = NSMutableAttributedString(
            string: "",
            attributes: textView.defaultTextAttributes
        )
        if let upperIcon = upperIcon {
            let iconRange = NSRange(
                location: attributedText.length,
                length: 2  // Icon + space.
            )
            unselectableRanges.append(iconRange)

            if upperIcon == translatorIcon {
                rangeOfTranslatorIcon = NSRange(
                    location: attributedText.length,
                    length: 1
                )
            }
            
            attributedText.append(NSAttributedString.imageAttributedString(
                icon: upperIcon,
                font: iconFont
            ))
            attributedText.append(NSAttributedString(
                string: " ",
                attributes: textView.defaultTextAttributes
            ))
            // Should add attrs for the icon.
            // Else the attrs are lost.
            attributedText.addAttributes(
                textView.defaultTextAttributes,
                range: iconRange
            )
        }
        attributedText.append(NSAttributedString(
            string: upperString,
            attributes: textView.defaultTextAttributes
        ))
        if let upperIcon = upperIcon, upperIcon == translatorIcon {
            rangeOfTranslationText = NSRange(
                location: attributedText.length - upperString.utf16.count,
                length: upperString.utf16.count
            )
        }
        
        textView.attributedText = attributedText
    }
    
    func displayLower() {
        let attributedText = NSMutableAttributedString(attributedString: textView.attributedText!)
        attributedText.append(NSAttributedString(
            string: "\n",
            attributes: textView.defaultTextAttributes
        ))
        if let lowerIcon = lowerIcon {
            let iconRange = NSRange(
                location: attributedText.length,
                length: 2  // Icon + space.
            )
            unselectableRanges.append(iconRange)

            if lowerIcon == translatorIcon {
                rangeOfTranslatorIcon = NSRange(
                    location: attributedText.length,
                    length: 1
                )
            }
            
            attributedText.append(NSAttributedString.imageAttributedString(
                icon: lowerIcon,
                font: iconFont
            ))
            attributedText.append(NSAttributedString(
                string: " ",
                attributes: textView.defaultTextAttributes
            ))
            // Should add attrs for the icon.
            // Else the attrs are lost.
            attributedText.addAttributes(
                textView.defaultTextAttributes,
                range: iconRange
            )
        }
        attributedText.append(NSAttributedString(
            string: lowerString,
            attributes: textView.defaultTextAttributes
        ))
        if let lowerIcon = lowerIcon, lowerIcon == translatorIcon {
            rangeOfTranslationText = NSRange(
                location: attributedText.length - lowerString.utf16.count,
                length: lowerString.utf16.count
            )
        }

        textView.attributedText = attributedText

        // Update system prompt to include translation now that it's visible.
        if let m = lowerString, !m.isEmpty {
            let langName = Strings.languageNamesOfAllLanguages[textLang]?[.en] ?? textLang.rawValue
            let meaningLangName = Strings.languageNamesOfAllLanguages[meaningLang]?[.en] ?? meaningLang.rawValue
            var prompt = "You are a helpful language tutor. The user is studying \(langName). The current text is:\n\n\(text!)"
            prompt += "\n\nTranslation (\(meaningLangName)): \(m)"
            prompt += "\n\nAnswer questions about vocabulary, grammar, or expressions in this text. Be concise."
            textView.chatSystemPrompt = prompt
        }

    }
    
    func submit() -> Any {
        fatalError("submit() has not been implemented.")
    }
    
    func updateViewsAfterSubmission() {
//        listenButton.isHidden = true
//        speakButton.isHidden = true
        listenButton.isEnabled = false
        speakButton.isEnabled = false
        
        reinforceButton.isHidden = !showsReinforceButton
        reinforceTextButton.isHidden = !showsReinforceButton
        
        displayLower()
        
        currentRepetition += 1
        updateRepetitionLabelText()
    }
}

extension TextMeaningPracticeView {
    
    // MARK: - Utils
    
    func highlightExistingPhrases(existingPhraseRanges: [NSRange], existingPhraseMeanings: [String]) {
        for (range, meaning) in zip(existingPhraseRanges, existingPhraseMeanings) {
            guard let textRange = textView.textRange(from: range) else {
                continue
            }
            let text = (textView.text as NSString).substring(with: range)
            textView.wordsInfo.append(WordInfo(
                textRange: textRange,
                word: text,
                meaning: meaning,
                canDelete: false
            ))
        }
        textView.highlightAll(with: Colors.oldWordHighlightingColor)
    }
    
    func highlightExistingReinforcementWords() {

        let wordPracticeCounter = WordPracticeProducer.countWordPractices(for: LangCode.currentLanguage)
        for word in wordPracticeCounter.keys {
            let range = (textView.text as NSString).range(of: word)
            if range.location == NSNotFound {
                continue
            }
            guard let textRange = textView.textRange(from: range) else {
                continue
            }
            
            textView.reinforcementWordsInfo.append(WordInfo(
                textRange: textRange,
                word: word,
                meaning: "",
                canDelete: false
            ))
        }
        textView.underlineAll()
    }
    
    private func updateRepetitionLabelText() {
        repetitionsLabel.text = "\(currentRepetition!)/\(totalRepetitions!)"
    }
    
    func markVerbAspects(at annotations: [VerbAspectAnnotation]) {
        legendView.markVerbAspects(in: textView.textStorage, at: annotations)
    }

    func markNounCases(at annotations: [NounCaseAnnotation]) {
        legendView.markNounCases(in: textView.textStorage, at: annotations)
    }

    func markShortAdjectives(at annotations: [ShortAdjectiveAnnotation]) {
        guard LangCode.currentLanguage.configs.shouldShowNounCasesInPractices else { return }

        let fontSize = (textView.font?.pointSize ?? Sizes.smallFontSize)
        for annotation in annotations {
            let range = NSRange(location: annotation.position, length: annotation.length)
            guard range.location + range.length <= textView.textStorage.length else { continue }
            // Merge the italic trait into whatever font is already set on the range
            // (rather than overwriting it), so a bold stress mark applied earlier by
            // markAccents(at:) doesn't get wiped out.
            textView.textStorage.addSymbolicTrait(.traitItalic, for: range, fontSize: fontSize)
        }
    }

    func markAccents(at accentLocs: [Int]) {
        for accentLoc in accentLocs {
            
            var fontSizeForAccentToMark: CGFloat = Sizes.smallFontSize
            if let font = textView.defaultTextAttributes[.font] as? UIFont {
                fontSizeForAccentToMark = font.pointSize
            }
            let boldFontAttributes = [
                NSAttributedString.Key.font : UIFont.systemFont(
                    ofSize: fontSizeForAccentToMark,
                    weight: .bold
                )
            ]
            
            let nsRangeForCharToMark = NSRange(
                location: accentLoc,
                length: 1
            )
            
            textView.textStorage.addAttributes(
                boldFontAttributes,
                range: nsRangeForCharToMark
            )
        }
    }
    
}

extension TextMeaningPracticeView: UITextViewDelegate {
    
    // MARK: - UITextViewDelegate
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        // Disable the selection of icons.
        let r = textView.selectedRange
        for unselectableRange in self.unselectableRanges {
            if unselectableRange.intersection(r) != nil {
                let newLocation = unselectableRange.location + unselectableRange.length
                let newLength = abs(r.length - newLocation)
                if newLength > 0 {
                    textView.selectedRange = NSRange(location: newLocation, length: newLength)
                }
                break
            }
        }

        // Populate chat input with selected text.
        let finalRange = textView.selectedRange
        if finalRange.length > 0,
           let selected = (textView.attributedText.string as NSString).substring(with: finalRange) as String?,
           !selected.isEmpty {
            chatTextField.text = "\"\(selected)\""
            updateChatSendButton()
        }
    }
    
    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange) -> Bool {
        // Disable the interaction of icons.
        return false
    }
    
}

extension TextMeaningPracticeView: WordMarkingTextViewContentGenerationDelegate {
    
    @objc
    func startedContentGeneration(wordMarkingTextView: WordMarkingTextView) {
        
        repetitionsLabel.isHidden = true
        contentGenerationSpinner.isHidden = false
        contentGenerationSpinner.startAnimating()
        mainView.bringSubviewToFront(contentGenerationSpinner)

    }
    
    @objc
    func completedContentGeneration(wordMarkingTextView: WordMarkingTextView, content: String?) {
        
        repetitionsLabel.isHidden = false
        contentGenerationSpinner.isHidden = true
        contentGenerationSpinner.stopAnimating()
        
    }
    
}

extension TextMeaningPracticeView: WordMarkingTextViewTappingDelegate {
    
    @objc dynamic func tapped(at tappedTextRange: UITextRange) {
        
        guard let rangeOfTranslatorIcon = rangeOfTranslatorIcon else {
            return
        }
        
        let tappedRange = textView.nsRange(from: tappedTextRange)
        
        var isMatched = false
        for offset in [0, 1, 2] {
            let r = NSRange(
                location: rangeOfTranslatorIcon.location + offset,
                length: rangeOfTranslatorIcon.length
            )
            if r.location == tappedRange.location {
                isMatched = true
            }
        }
        if !isMatched {
            return
        }
        
        languageSelectionDelegate.showLanguageSelectionController(currentlySelectedLanguage: self.meaningLang)
    }

    func selectionDidClear() {
        if chatTextField.text?.hasPrefix("\"") == true {
            chatTextField.text = ""
            updateChatSendButton()
        }
    }

}

extension TextMeaningPracticeView {
        
    func updateMeaningLang(as language: LangCode) {

        guard language != self.meaningLang else {
            return
        }
        guard self.rangeOfTranslatorIcon != nil else {
            return
        }
        guard self.rangeOfTranslationText != nil else {
            return
        }
        guard let originalMeaning = self.meaning else {
            return
        }
        
        let originalMeaningLang = self.meaningLang
        self.meaningLang = language
        
        textView.isColorAnimating = true
        textView.startTextColorTransitionAnimation(for: self.rangeOfTranslationText!)
        MachineTranslator(
            srcLang: self.textLang,
            trgLang: self.meaningLang
        ).translate(query: self.text) { translations, translatorType in
            
            self.textView.isColorAnimating = false
            // Restore the text color.
            if let rangeOfTranslationText = self.rangeOfTranslationText {
                DispatchQueue.main.async {
                    self.textView.textStorage.setTextColor(
                        for: rangeOfTranslationText,
                        with: self.textView.colorAnimationOriginalColor
                    )
                }
            }
            
            guard let translation = translations.first else {
                self.meaningLang = originalMeaningLang
                return
            }
                                    
            self.meaning = translation
            self.machineTranslatorType = translatorType
            
            // Update the translator icon and the translation text.
            DispatchQueue.main.async {
                
                self.textView.textStorage.replaceCharacters(
                    in: self.rangeOfTranslatorIcon!,
                    with: NSAttributedString.imageAttributedString(
                        icon: self.translatorIcon,
                        font: self.iconFont
                    )
                )
                // Should add attrs for the icon.
                // Else the attrs are lost.
                self.textView.textStorage.addAttributes(
                    self.textView.defaultTextAttributes,
                    range: self.rangeOfTranslatorIcon!
                )
                
                self.textView.textStorage.replaceCharacters(
                    in: self.rangeOfTranslationText!,
                    with: NSAttributedString(
                        string: translation,
                        attributes: self.textView.defaultTextAttributes
                    )
                )
                
                // Seems that it cannot be placed outside the block,
                // else the end of the translation of the original lang
                // will remain if the new translation is shorter.
                self.rangeOfTranslationText = NSRange(
                    location: self.rangeOfTranslationText!.location,
                    length: self.meaning.utf16.count
                )
                
                // Update stuff in the text view.
                
                self.textView.originalTextLength = self.rangeOfTranslationText!.location + self.rangeOfTranslationText!.length
                
                let lengthDiff = translation.utf16.count - originalMeaning.utf16.count
                for (i, info) in self.textView.contentGenerationInfoList.enumerated() {
                    guard info != nil else {
                        continue
                    }
                    self.textView.contentGenerationInfoList[i]!.refreshIconNSRange = NSRange(
                        location: info!.refreshIconNSRange.location + lengthDiff,
                        length: info!.refreshIconNSRange.length
                    )
                    self.textView.contentGenerationInfoList[i]!.contentNSRange = NSRange(
                        location: info!.contentNSRange.location + lengthDiff,
                        length: info!.contentNSRange.length
                    )
                }
                
            }
                                       
        }
        
    }
    
}


extension TextMeaningPracticeView {

    // MARK: - Selectors

    @objc
    private func reinforceButtonTapped() {
        shouldReinforce.toggle()
    }

    @objc
    func chatSendButtonTapped() {
        guard let msg = chatTextField.text?.strip(), !msg.isEmpty else { return }
        chatTextField.text = ""
        chatTextField.resignFirstResponder()
        updateChatSendButton()
        textView.sendChatMessage(msg)
    }

    @objc
    private func chatTextFieldChanged() {
        updateChatSendButton()
    }

    private func updateChatSendButton() {
        let hasText = !(chatTextField.text?.strip().isEmpty ?? true)
        chatSendButton.isEnabled = hasText
        chatSendButton.tintColor = hasText ? Colors.activeSystemButtonColor : Colors.inactiveSystemButtonColor
    }

    @objc
    private func backgroundTapped() {
        chatTextField.resignFirstResponder()
        textView.resignFirstResponder()
        textView.selectedRange = NSRange(location: 0, length: 0)
    }

}

extension TextMeaningPracticeView {

    // MARK: - Chat Bubble Helpers

    private func parseMarkdown(_ text: String, font: UIFont, color: UIColor) -> NSAttributedString {
        let attrText = NSMutableAttributedString(
            string: text,
            attributes: [.font: font, .foregroundColor: color]
        )

        func apply(trait: UIFontDescriptor.SymbolicTraits, pattern: String, markerLen: Int) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators) else { return }
            let matches = regex.matches(in: attrText.string, range: NSRange(location: 0, length: attrText.string.utf16.count))
            var phraseRanges: [NSRange] = []
            var markerPairs: [(NSRange, NSRange)] = []
            for m in matches {
                phraseRanges.append(m.range(at: 2))
                markerPairs.append((m.range(at: 1), m.range(at: 3)))
            }
            for r in phraseRanges {
                let attrs = attrText.attributes(at: r.location, effectiveRange: nil)
                if let f = attrs[.font] as? UIFont,
                   let desc = f.fontDescriptor.withSymbolicTraits(f.fontDescriptor.symbolicTraits.union(trait)) {
                    attrText.addAttribute(.font, value: UIFont(descriptor: desc, size: f.pointSize), range: r)
                }
            }
            var offset = 0
            for (left, right) in markerPairs {
                let l = NSRange(location: left.location + offset, length: left.length)
                attrText.replaceCharacters(in: l, with: "")
                let r = NSRange(location: right.location + offset - markerLen, length: right.length)
                attrText.replaceCharacters(in: r, with: "")
                offset -= markerLen * 2
            }
        }

        apply(trait: .traitBold,   pattern: "(\\*\\*)(.*?)(\\*\\*)", markerLen: 2)
        apply(trait: .traitItalic, pattern: "(\\*)(.*?)(\\*)",       markerLen: 1)
        return attrText
    }

    private func makeBubble(text: String, isUser: Bool) -> (row: UIView, label: UILabel) {
        let font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        let color: UIColor = isUser ? .white : Colors.normalTextColor

        let label = UILabel()
        label.attributedText = parseMarkdown(text, font: font, color: color)
        label.numberOfLines = 0

        let bubble = UIView()
        bubble.backgroundColor = isUser ? Colors.activeSystemButtonColor : Colors.lightGrayBackgroundColor
        bubble.layer.cornerRadius = 12
        bubble.layer.masksToBounds = true
        bubble.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
        }

        let row = UIView()
        row.addSubview(bubble)
        bubble.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            if isUser {
                make.trailing.equalToSuperview()
                make.width.lessThanOrEqualToSuperview().multipliedBy(0.90)
            } else {
                make.leading.equalToSuperview()
                make.width.lessThanOrEqualToSuperview()
            }
        }
        return (row, label)
    }

    private func updateChatBubblesPosition() {
        chatBubblesStack.isHidden = chatBubblesStack.arrangedSubviews.isEmpty
        layoutIfNeeded()
        let bottom = contentScrollView.contentSize.height - contentScrollView.bounds.height
        if bottom > 0 {
            contentScrollView.setContentOffset(CGPoint(x: 0, y: bottom), animated: true)
        }
    }

}

extension TextMeaningPracticeView: WordMarkingTextViewChatDelegate {

    func chatDidSendMessage(_ userMessage: String) {
        let (row, _) = makeBubble(text: userMessage, isUser: true)
        chatBubblesStack.addArrangedSubview(row)
        chatTypingIndicator.startAnimating()
        let (aiRow, aiLabel) = makeBubble(text: "", isUser: false)
        aiRow.isHidden = true
        chatBubblesStack.addArrangedSubview(aiRow)
        currentAIBubbleLabel = aiLabel
        currentAIBubbleText = ""
        updateChatBubblesPosition()
    }

    func chatDidReceiveChunk(_ chunk: String) {
        chatTypingIndicator.stopAnimating()
        if let label = currentAIBubbleLabel {
            currentAIBubbleText += chunk
            label.attributedText = parseMarkdown(
                currentAIBubbleText,
                font: UIFont.systemFont(ofSize: Sizes.smallFontSize),
                color: Colors.normalTextColor
            )
            label.superview?.superview?.isHidden = false
        }
        updateChatBubblesPosition()
    }

    func chatDidFinish() {
        chatTypingIndicator.stopAnimating()
        currentAIBubbleLabel = nil
        currentAIBubbleText = ""
    }

    func chatDidFail() {
        chatTypingIndicator.stopAnimating()
        if let label = currentAIBubbleLabel,
           let row = label.superview?.superview {
            chatBubblesStack.removeArrangedSubview(row)
            row.removeFromSuperview()
        }
        currentAIBubbleLabel = nil
        currentAIBubbleText = ""
    }

}

protocol TextMeaningPracticeViewDelegate {
    func showLanguageSelectionController(currentlySelectedLanguage: LangCode)
}

extension TextMeaningPracticeView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        chatSendButtonTapped()
        return true
    }
}
