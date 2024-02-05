//
//  TranslationPracticeView.swift
//  Polyglot
//
//  Created by Sola on 2023/1/9.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class TranslationPracticeView: UIView, PracticeViewDelegate {
    
    var text: String!
    var meaning: String!
    
    var textLang: String!
    var meaningLang: String!
    
    var textLangFlag: String {
        LangCode.toFlagIcon(langCode: textLang)
    }
    var meaningLangFlag: String {
        LangCode.toFlagIcon(langCode: meaningLang)
    }
    
    // MARK: - Views
    
    var mainView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.lightGrayBackgroundColor
        view.layer.masksToBounds = true
        view.layer.cornerRadius = Sizes.defaultCornerRadius
        view.layer.borderWidth = 2
        view.layer.borderColor = Colors.borderColor.cgColor
        return view
    }()
    
    var textView: NewWordAddingTextView!
    
    // MARK: - Init
    
    init(frame: CGRect = .zero, text: String?, meaning: String?, textLang: String, meaningLang: String) {
        super.init(frame: frame)
        
        if let text = text {
            self.text = text
        }
        if let meaning = meaning {
            self.meaning = meaning
        }
        self.textLang = textLang
        self.meaningLang = meaningLang
        
        textView = NewWordAddingTextView(
            textLang: Variables.lang,
            meaningLang: Variables.pairedLang
        )  // TODO: - is it proper to directly pass langs here?
        textView.attributedText = NSMutableAttributedString(
            string: " ",
            attributes: Attributes.leftAlignedLongTextAttributes
        )
        
        if let text = self.text {
            textView.text = "\(textLangFlag): \(text)"
        } else if let meaning = self.meaning {
            GoogleTranslator(
                srcLang: meaningLang,
                trgLang: textLang
            ).translate(query: meaning) { (res) in
                var textToDisplay: String
                if let translation = res.first {
                    textToDisplay = "(\(Strings.machineTranslationToken)) \(translation)"
                } else {
                    textToDisplay = Strings.machineTranslationErrorToken
                }
                DispatchQueue.main.async {
                    self.textView.text = "\(self.textLangFlag): \(textToDisplay)"
                }
            }
        }
                
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func updateSetups() {
        
    }
    
    private func updateViews() {
        addSubview(mainView)
        mainView.addSubview(textView)
    }
    
    private func updateLayouts() {
        mainView.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        }
        textView.snp.makeConstraints { (make) in
//            make.centerX.centerY.equalToSuperview()
//            make.width.equalToSuperview().multipliedBy(0.9)
//            make.height.equalToSuperview().multipliedBy(0.9)
            make.top.bottom.leading.trailing.equalToSuperview().inset(Sizes.mediumFontSize)
        }
    }
}

extension TranslationPracticeView {
    
    func displayTranslation() {
        
        if let meaning = self.meaning {
            textView.text = "\(textView.text!)\n\n\(meaningLangFlag): \(meaning)"
        } else if let text = self.text {
            GoogleTranslator(
                srcLang: textLang,
                trgLang: meaningLang
            ).translate(query: text) { (res) in
                var meaningToDisplay: String
                if let translation = res.first {
                    meaningToDisplay = "(\(Strings.machineTranslationToken)) \(translation)"
                } else {
                    meaningToDisplay = Strings.machineTranslationErrorToken
                }
                DispatchQueue.main.async {
                    self.textView.text = "\(self.textView.text!)\n\n\(self.meaningLangFlag): \(meaningToDisplay)"
                }
            }
        }
        
        // Restore the highlights.
        textView.highlightAll()
    }
    
}
