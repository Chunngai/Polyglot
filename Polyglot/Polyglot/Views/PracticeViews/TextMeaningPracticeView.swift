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
    
    var upperString: String!
    var lowerString: String!
    
    var newWordsInfo: [NewWordInfo] {
        return textView.newWordsInfo
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
        view.backgroundColor = Colors.lightGrayBackgroundColor
        view.layer.masksToBounds = true
        view.layer.cornerRadius = Sizes.defaultCornerRadius
        view.layer.borderWidth = Sizes.defaultBorderWidth
        view.layer.borderColor = Colors.borderColor.cgColor
        return view
    }()
    
    var textView: NewWordAddingTextView!
    
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
        currentRepetition: Int
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
        
        textView = NewWordAddingTextView(
            textLang: textLang,
            meaningLang: meaningLang
        )
        textView.attributedText = NSMutableAttributedString(
            string: " ",
            attributes: Attributes.leftAlignedLongTextAttributes
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
            make.centerX.centerY.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        let inset = (Attributes.leftAlignedLongTextAttributes[NSAttributedString.Key.font] as! UIFont).pointSize
        
        textView.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview().inset(inset)
        }
        
        listenButton.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview().inset(inset)
        }
        speakButton.snp.makeConstraints { make in
            make.leading.equalTo(listenButton.snp.trailing).offset(10)
            make.centerY.equalTo(listenButton.snp.centerY)
        }
        
        reinforceButton.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview().inset(inset)
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
            
            attributedText.append(makeImageAttributedString(with: upperIcon))
            attributedText.append(NSAttributedString(string: " "))
        }
        attributedText.append(NSAttributedString(string: upperString))
        // Without this the text attributes are cleared after attaching the icon.
        attributedText.addAttributes(
            Attributes.leftAlignedLongTextAttributes,
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
            
            attributedText.append(makeImageAttributedString(with: lowerIcon))
            attributedText.append(NSAttributedString(string: " "))
//            attributedText.addAttributes(
//                Attributes.leftAlignedLongTextAttributes,
//                range: NSRange(
//                    location: attributedText.length - 2,
//                    length: 2
//                )
//            )
        }
        attributedText.append(NSAttributedString(string: lowerString))
        attributedText.addAttributes(
            Attributes.leftAlignedLongTextAttributes,
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
    
    func makeImageAttributedString(with icon: UIImage) -> NSAttributedString {
        let textAttachment = NSTextAttachment()
        textAttachment.image = icon
        
        // Use the line height of the font for the image height to align with the text height
        let font = (Attributes.leftAlignedLongTextAttributes[.font] as? UIFont) ?? UIFont.systemFont(ofSize: Sizes.smallFontSize)
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
    
    func highlightExistingPhrases(existingPhraseRanges: [NSRange], existingPhraseMeanings: [String]) {
        for (range, meaning) in zip(existingPhraseRanges, existingPhraseMeanings) {
            guard let textRange = textView.textRange(from: range) else {
                continue
            }
            let text = (textView.text as NSString).substring(with: range)
            textView.newWordsInfo.append(NewWordInfo(
                textRange: textRange,
                word: text,
                meaning: meaning
            ))
        }
        textView.highlightAll()
    }
    
    private func updateRepetitionLabelText() {
        repetitionsLabel.text = "\(currentRepetition!)/\(totalRepetitions!)"
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
