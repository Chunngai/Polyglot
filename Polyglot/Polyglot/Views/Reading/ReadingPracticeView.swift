//
//  ReadingPracticeView.swift
//  Polyglot
//
//  Created by Sola on 2023/1/9.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class ReadingPracticeView: UIView, PracticeViewDelegate {
    
    var text: String!
    var meaning: String?
    
    var isMeaningDisplayed: Bool = false  // Prevent displaying the meaning multiple times.
    
    // MARK: - Views
    
    var mainView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.lightGrayBackgroundColor
        view.layer.masksToBounds = true
        view.layer.cornerRadius = Sizes.defaultCornerRadius
        return view
    }()
    
    var textView: NewWordAddingTextView!
    
    var translateButton: UIButton = {  // TODO: - Use another icon.
        let button = UIButton()
        button.setImage(Icons.translateIcon, for: .normal)
        return button
    }()
    
    // MARK: - Init
    
    init(frame: CGRect = .zero, text: String, textLang: String, meaning: String?, meaningLang: String) {
        super.init(frame: frame)
        
        self.text = text
        self.meaning = meaning
        
        textView = NewWordAddingTextView(textLang: textLang, meaningLang: meaningLang)
        textView.attributedText = NSMutableAttributedString(
            string: text,
            attributes: Attributes.defaultLongTextAttributes
        )
                
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func updateSetups() {
        translateButton.addTarget(
            self,
            action: #selector(translateButtonTapped),
            for: .touchUpInside
        )
    }
    
    private func updateViews() {
        addSubview(mainView)
        addSubview(translateButton)

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
        
        translateButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().inset(15)
        }
    }
}

extension ReadingPracticeView {
    
    // MARK: - Selectors
    
    @objc private func translateButtonTapped() {
        guard !isMeaningDisplayed else {
            return
        }
        
        if let meaning = self.meaning {
            textView.text += "\n\n"
            textView.text += "\(Strings.translationToken):\n"
            textView.text += meaning
            
            textView.highlightAll()
            
            isMeaningDisplayed = true
        } else {
            let completion: ([String]) -> Void = { translations in
                // https://github.com/xmartlabs/Eureka/issues/1351
                DispatchQueue.main.async {
                    let translatedMeaning = translations[0]
                    
                    guard !self.textView.text.contains(translatedMeaning) else {
                        // When the translation button is tapped multiple times
                        // before obtaining the machine translation,
                        // the translation will be displayed multiple times,
                        // since `isMeaningDisplayed` is not set to true
                        // at this moment.
                        // This guard statement is for preventing such situation.
                        return
                    }
                    
                    self.textView.text += "\n\n"
                    self.textView.text += "\(Strings.machineTranslationToken):\n"
                    self.textView.text += translatedMeaning
                    
                    self.textView.highlightAll()
                    
                    self.isMeaningDisplayed = true
                }
            }
            
            GoogleTranslator(
                srcLang: Variables.lang,
                trgLang: Variables.pairedLang
            ).translate(
                query: self.text,
                completion: completion
            )
        }
    }
    
}
