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
    
    var repetitionIncrement: Int!
    
    var upperString: String!
    var lowerString: String!
    
    var unselectableRanges: [NSRange] = []

    var rangeOfTranslatorIcon: NSRange?
    var rangeOfTranslationText: NSRange?
    
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
        let button = UIButton()
        button.setImage(
            Images.listeningPracticeProduceSpeechImage,
            for: .normal
        )
        return button
    }()
    let speakButton: UIButton = {
        let button = UIButton()
        button.setImage(
            Images.listeningPracticeStartToRecordSpeechImage,
            for: .normal
        )
        return button
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
        self.repetitionIncrement = repetitionIncrement
        
        textView = {
            let textView = WordMarkingTextView(
                textLang: textLang,
                meaningLang: meaningLang
            )
            
            textView.textContainerInset = UIEdgeInsets(
                top: textView.textContainerInset.top,
                left: textView.textContainerInset.left,
                bottom: Sizes.roundButtonRadius,
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
    }
    
    func updateViews() {
        addSubview(mainView)
        mainView.addSubview(textView)
        mainView.addSubview(listenButton)
        mainView.addSubview(speakButton)
        mainView.addSubview(reinforceButton)
        mainView.addSubview(reinforceTextButton)
        mainView.addSubview(repetitionsLabel)
        mainView.addSubview(contentGenerationSpinner)
        
        displayUpper()
    }
    
    func updateLayouts() {
        mainView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        textView.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview().inset(20)
        }
        
        listenButton.snp.makeConstraints { make in
            // Consistent with the done/next buttons.
            make.leading.equalToSuperview().inset(Sizes.roundButtonRadius / 2)
            make.bottom.equalToSuperview().inset(Sizes.roundButtonRadius / 2)
            make.height.equalTo(Sizes.roundButtonRadius)
        }
        speakButton.snp.makeConstraints { make in
            make.leading.equalTo(listenButton.snp.trailing).offset(listenButton.intrinsicContentSize.width * 0.5)
            make.centerY.equalTo(listenButton.snp.centerY)
            make.height.equalTo(Sizes.roundButtonRadius)
        }
        
        reinforceButton.snp.makeConstraints { make in
            make.leading.bottom.equalTo(listenButton)
            make.height.equalTo(Sizes.roundButtonRadius)
        }
        reinforceTextButton.snp.makeConstraints { make in
            make.leading.equalTo(reinforceButton.snp.trailing).offset(5)
            make.centerY.equalTo(reinforceButton.snp.centerY)
        }
        
        repetitionsLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(listenButton.snp.centerY)
        }
        contentGenerationSpinner.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(listenButton.snp.centerY)
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
    }
    
    func submit() -> Any {
        fatalError("submit() has not been implemented.")
    }
    
    func updateViewsAfterSubmission() {
        listenButton.isHidden = true
        speakButton.isHidden = true
        
        reinforceButton.isHidden = false
        reinforceTextButton.isHidden = false
        
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
                textView.selectedRange = NSRange(
                    location: newLocation,
                    length: newLength
                )
                break
            }
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
                self.rangeOfTranslationText = NSRange(
                    location: self.rangeOfTranslationText!.location,
                    length: self.meaning.utf16.count
                )
                
                // TODO: - Proper to write here?
                
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
    
}

protocol TextMeaningPracticeViewDelegate {
    
    func showLanguageSelectionController(currentlySelectedLanguage: LangCode)
    
}
