//
//  TextMeaningPracticeView.swift
//  Polyglot
//
//  Created by Ho on 2/7/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class TextMeaningPracticeView: UIView, PracticeViewDelegate {
    
    var text: String!
    var meaning: String!
    var textLang: LangCode!
    var meaningLang: LangCode!
    var textSource: TextSource!
    var isTextMachineTranslated: Bool!
    var existingPhraseRanges: [NSRange]!
    var existingPhraseMeanings: [String]!
    
    var newWordsInfo: [NewWordInfo] {
        return textView.newWordsInfo
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
    
    // MARK: - Init
    
    init(
        frame: CGRect = .zero,
        text: String,
        meaning: String,
        textLang: LangCode,
        meaningLang: LangCode,
        textSource: TextSource,
        isTextMachineTranslated: Bool,
        existingPhraseRanges: [NSRange],
        existingPhraseMeanings: [String]
    ) {
        super.init(frame: frame)
        
        self.text = text
        self.meaning = meaning
        self.textLang = textLang
        self.meaningLang = meaningLang
        self.textSource = textSource
        self.isTextMachineTranslated = isTextMachineTranslated
        self.existingPhraseRanges = existingPhraseRanges
        self.existingPhraseMeanings = existingPhraseMeanings
        
        textView = NewWordAddingTextView(
            textLang: textLang,
            meaningLang: meaningLang
        )
        textView.attributedText = NSMutableAttributedString(
            string: " ",
            attributes: Attributes.leftAlignedLongTextAttributes
        )
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func updateSetups() {
        
    }
    
    func updateViews() {
        addSubview(mainView)
        mainView.addSubview(textView)
    }
    
    func updateLayouts() {
        mainView.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        }
        textView.snp.makeConstraints { (make) in
            let inset = (Attributes.leftAlignedLongTextAttributes[NSAttributedString.Key.font] as! UIFont).pointSize
            make.top.bottom.leading.trailing.equalToSuperview().inset(inset)
        }
    }
    
    func displayText() {
        fatalError("displayText() has not been implemented.")
    }
    
    func displayMeaning() {
        fatalError("displayMeaning() has not been implemented.")
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
}
