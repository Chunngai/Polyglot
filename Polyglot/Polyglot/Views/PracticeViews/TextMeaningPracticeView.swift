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
    
    var upperString: String!
    var lowerString: String!
    
    var wordsInfo: [WordInfo] {
        return textView.wordsInfo
    }
    
    var unselectableRanges: [NSRange] = []
    
    var shouldReinforce: Bool = false {
        didSet {
            if shouldReinforce {
                reinforceButton.tintColor = Colors.inactiveSystemButtonColor
                reinforceTextButton.setTitleColor(Colors.inactiveTextColor, for: .normal)
                
                totalRepetitions += LangCode.currentLanguage.configs.practiceRepetition
            } else {
                reinforceButton.tintColor = Colors.activeSystemButtonColor
                reinforceTextButton.setTitleColor(Colors.activeTextColor, for: .normal)
                
                totalRepetitions -= LangCode.currentLanguage.configs.practiceRepetition
            }
            
            updateRepetitionLabelText()
        }
    }
    
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
    
    var translatorIcon: UIImage {
        switch machineTranslatorType {
        case .google: return Icons.googleTranslateIcon
        case .baidu: return Icons.baiduTranslateIcon
        default: return UIImage.init(systemName: "questionmark.square.dashed")!
        }
    }
    
    var upperIcon: UIImage?
    var lowerIcon: UIImage?
    
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
        textAccentLocs: [Int]
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
        
        textView = WordMarkingTextView(
            textLang: textLang,
            meaningLang: meaningLang
        )
        textView.textContainerInset = UIEdgeInsets(
            top: textView.textContainerInset.top, 
            left: textView.textContainerInset.left,
            bottom: Sizes.defaultCornerRadius * 2,
            right: textView.textContainerInset.right
        )
        textView.defaultTextAttributes = {
            var attrs = Attributes.leftAlignedLongTextAttributes
            attrs[.font] = UIFont.systemFont(ofSize: Sizes.mediumFontSize)
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
        
        updateRepetitionLabelText()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func updateSetups() {
        textView.delegate = self
        
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
    }
    
    func displayUpper() {
        let attributedText = NSMutableAttributedString(string: "")
        if let upperIcon = upperIcon {
            unselectableRanges.append(NSRange(
                location: attributedText.length,
                length: 2  // Icon + space.
            ))
            
            attributedText.append(textView.imageAttributedString(with: upperIcon))
            attributedText.append(NSAttributedString(string: " "))
        }
        attributedText.append(NSAttributedString(string: upperString))
        // Without this the text attributes are cleared after attaching the icon.
        attributedText.addAttributes(
            textView.defaultTextAttributes,
            range: NSRange(
                location: 0,
                length: attributedText.length
            )
        )
        
        textView.attributedText = attributedText
    }
    
    func displayLower() {
        let attributedText = NSMutableAttributedString(attributedString: textView.attributedText!)
        attributedText.append(NSAttributedString(string: "\n"))
        if let lowerIcon = lowerIcon {
            unselectableRanges.append(NSRange(
                location: attributedText.length,
                length: 2  // Icon + space.
            ))
            
            attributedText.append(textView.imageAttributedString(with: lowerIcon))
            attributedText.append(NSAttributedString(string: " "))
        }
        attributedText.append(NSAttributedString(string: lowerString))
        attributedText.addAttributes(
            textView.defaultTextAttributes,
            range: NSRange(
                location: 0,
                length: attributedText.length
            )
        )
        
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

extension TextMeaningPracticeView {
    
    // MARK: - Selectors
    
    @objc
    private func reinforceButtonTapped() {
        
        shouldReinforce.toggle()
        
    }
    
}
