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
    
    var translationToken: String {
        return "\n\n\(Strings.translationToken):\n"
    }
    
    // MARK: - Views
    
    var mainView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.lightGrayBackgroundColor
        view.layer.masksToBounds = true
        view.layer.cornerRadius = Sizes.defaultCornerRadius
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
        
        textView = NewWordAddingTextView(textLang: Variables.lang, meaningLang: Variables.pairedLang)  // TODO: - is it proper to directly pass langs here?
        textView.attributedText = NSMutableAttributedString(
            string: " ",
            attributes: Attributes.defaultLongTextAttributes
        )
        
        if self.text != nil {
            textView.text = text
        } else if self.meaning != nil {
            GoogleTranslator(
                srcLang: meaningLang,
                trgLang: textLang
            ).translate(query: self.meaning!) { (res) in
                var translatedText: String
                if let translation = res.first {
                    translatedText = translation
                } else {
                    translatedText = Strings.machineTranslationErrorToken
                }
                DispatchQueue.main.async {
                    self.text = "(\(Strings.machineTranslationToken)) \(translatedText)"
                    self.textView.text = "(\(Strings.machineTranslationToken)) \(translatedText)"
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
            make.centerX.centerY.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.9)
            make.height.equalToSuperview().multipliedBy(0.9)
        }
    }
}

extension TranslationPracticeView {
    
    func displayTranslation() {
        
        // Ensure that self.text is not nil.
        if self.text == nil {
            self.text = "[No text]"
        }
        
        if self.meaning != nil {
            textView.text = "\(self.text!)\(translationToken)\(self.meaning!)"
        } else if self.text != nil {
            GoogleTranslator(
                srcLang: textLang,
                trgLang: meaningLang
            ).translate(query: self.text!) { (res) in
                var translatedMeaning: String
                if let translation = res.first {
                    translatedMeaning = translation
                } else {
                    translatedMeaning = Strings.machineTranslationErrorToken
                }
                DispatchQueue.main.async {
                    self.meaning = translatedMeaning
                    self.textView.text = "\(self.text!)\n\n\(Strings.machineTranslationToken):\n\(translatedMeaning)\(self.meaning!)"
                }
            }
        }
        
        // Restore the highlights.
        // TODO: - Simplify here.
        textView.highlightAll()
    }
    
}
