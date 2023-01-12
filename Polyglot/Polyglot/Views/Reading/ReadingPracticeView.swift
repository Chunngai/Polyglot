//
//  ReadingPracticeView.swift
//  Polyglot
//
//  Created by Sola on 2023/1/9.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class ReadingPracticeView: UIView {

    private var practiceItem: ReadingPracticeProducer.Item! {
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
        view.backgroundColor = Colors.lightGrayBackgroundColor
        view.layer.masksToBounds = false
        view.layer.cornerRadius = Sizes.defaultCornerRadius
        return view
    }()
    
    var textView: NewWordAddingTextView = NewWordAddingTextView()
    
    var translateButton: UIButton = {  // TODO: - Use another icon.
        let button = UIButton()
        button.setImage(Icons.translateIcon, for: .normal)
        return button
    }()
    
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
    
    func updateValues(practiceItem: ReadingPracticeProducer.Item) {
        self.practiceItem = practiceItem
    }
}

extension ReadingPracticeView {
    
    // MARK: - Selectors
    
    @objc private func translateButtonTapped() {
        
    }
    
}

extension ReadingPracticeView: PracticeViewDelegate {
    
    // MARK: - Practice Delegate
    
    func check() -> Any {
        return ""
    }
}
