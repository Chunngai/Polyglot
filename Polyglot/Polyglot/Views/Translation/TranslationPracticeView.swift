//
//  TranslationPracticeView.swift
//  Polyglot
//
//  Created by Sola on 2023/1/9.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class TranslationPracticeView: UIView {

    private var practiceItem: TranslationPracticeProducer.Item! {
        didSet {
            textView.attributedText = NSMutableAttributedString(
                string: practiceItem.text,
                attributes: Attributes.longTextAttributes
            )
        }
    }
    
    // MARK: - Views
    
    var mainView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.weakBackgroundColor
        view.layer.masksToBounds = false
        view.layer.cornerRadius = Sizes.defaultCornerRadius
        return view
    }()
    
    var textView: NewWordAddingTextView = NewWordAddingTextView()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
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
    
    func updateValues(practiceItem: TranslationPracticeProducer.Item) {
        self.practiceItem = practiceItem
    }
}

extension TranslationPracticeView: PracticeViewDelegate {
    
    // MARK: - Practice Delegate
    
    func check() -> Any {
        return ""
    }
}
