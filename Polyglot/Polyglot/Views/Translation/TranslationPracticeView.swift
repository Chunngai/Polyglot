//
//  TranslationPracticeView.swift
//  Polyglot
//
//  Created by Sola on 2023/1/9.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class TranslationPracticeView: PracticeViewWithNewWordAddingTextView {
    
    var practice: TranslationPracticeProducer.Item!
    
    var textLangFlag: String {
        LangCode.toFlagIcon(langCode: practice.textLang)
    }
    var meaningLangFlag: String {
        LangCode.toFlagIcon(langCode: practice.meaningLang)
    }
    
    // MARK: - Init
    
    init(frame: CGRect = .zero, practice: TranslationPracticeProducer.Item) {
        super.init(frame: frame)
        
        self.practice = practice
        
        self.updateSetups()
        self.updateViews()
        self.updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func updateViews() {
        super.updateViews()
        
        if let text = practice.text {
            textView.text = "\(textLangFlag): \(text)"
        } else if let meaning = practice.meaning {
            GoogleTranslator(
                srcLang: practice.meaningLang,
                trgLang: practice.textLang
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
    }
}

extension TranslationPracticeView {
    
    func displayTranslation() {
        
        if let meaning = practice.meaning {
            textView.text = "\(textView.text!)\n\n\(meaningLangFlag): \(meaning)"
        } else if let text = practice.text {
            GoogleTranslator(
                srcLang: practice.textLang,
                trgLang: practice.meaningLang
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
