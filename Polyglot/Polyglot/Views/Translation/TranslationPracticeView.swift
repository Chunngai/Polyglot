//
//  TranslationPracticeView.swift
//  Polyglot
//
//  Created by Sola on 2023/1/9.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class TranslationPracticeView: UIView, PracticeViewDelegate {
    
    // MARK: - Views
    
    var mainView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.lightGrayBackgroundColor
        view.layer.masksToBounds = false
        view.layer.cornerRadius = Sizes.defaultCornerRadius
        return view
    }()
    
    var textView: NewWordAddingTextView!
    
    // MARK: - Init
    
    init(frame: CGRect = .zero, text: String, textLang: String, meaningLang: String) {
        super.init(frame: frame)
        
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
