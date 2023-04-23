//
//  FillingPracticeView.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit
import NaturalLanguage

class FillingPracticeView: UIView {
    
    var answer: String {
        textField.text!.strip()
    }
    
    // MARK: - Controllers
    
    var delegate: WordsPracticeViewController!
    
    // MARK: - Views
    
    var textField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: Sizes.largeFontSize)
        textField.textColor = Colors.normalTextColor
        textField.textAlignment = .center
        textField.adjustsFontSizeToFitWidth = true
        textField.minimumFontSize = Sizes.smallFontSize
        return textField
    }()
    
    var bottomLine: Separator = {
        let bottomLine = Separator()
        return bottomLine
    }()
    
    var referenceLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.normalTextColor
        label.font = UIFont.systemFont(ofSize: Sizes.mediumFontSize)
        label.isHidden = true
        label.numberOfLines = 0
        return label
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
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)
        
        addGestureRecognizer({
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
            return recognizer
        }())
    }
    
    private func updateViews() {
        
        addSubview(textField)
        addSubview(bottomLine)
        addSubview(referenceLabel)
    }
    
    private func updateLayouts() {
        textField.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        bottomLine.snp.makeConstraints { (make) in
            make.top.equalTo(textField.snp.bottom)
            make.width.equalTo(textField.snp.width)
            make.height.equalTo(1)
            make.centerX.equalTo(textField.snp.centerX)
        }
        
        referenceLabel.snp.makeConstraints { (make) in
            make.top.equalTo(bottomLine.snp.bottom).offset(5)
            make.left.equalTo(bottomLine.snp.left)
            make.width.equalTo(bottomLine.snp.width)
        }
    }
}

extension FillingPracticeView: WordPracticeViewDelegate {
    
    // MARK: - WordPracticeView Delegate
    
    func submit() -> String {
        textField.resignFirstResponder()
        textField.isEnabled = false
   
        return answer
    }
    
    func updateViews(for correctness: WordPractice.Correctness, key: String, tokenizer: NLTokenizer) {
        
        let attributedAnswer = NSMutableAttributedString(string: answer)
        
        let keyComponents = key.normalized(caseInsensitive: true, diacriticInsensitive: true).components(from: tokenizer)
        let answerComponents = answer.normalized(caseInsensitive: true, diacriticInsensitive: true).components(from: tokenizer)
        // Highlight overlap chars.
        for keyComponent in keyComponents {
            if answerComponents.contains(keyComponent) {
                attributedAnswer.setTextColor(
                    for: keyComponent,
                    with: Colors.strongCorrectColor,
                    ignoreCasing: true,
                    ignoreAccents: true
                )
            }
        }
        
        textField.attributedText = attributedAnswer
        
        if correctness != .correct {
            referenceLabel.isHidden = false
            referenceLabel.text = "\(Strings.referenceLabelPrefix)\(key)"
        }
    }
}

extension FillingPracticeView {
    
    // MARK: - Selectors
    
    @objc private func textFieldEditingChanged() {
        guard let text = textField.text else {
            return
        }
        
        if !text.strip().isEmpty {
            delegate.practiceStatus = .afterAnswering
        } else {
            delegate.practiceStatus = .beforeAnswering
        }
        
        return
    }
    
    @objc private func tapped() {
        textField.resignFirstResponder()
    }
}

extension FillingPracticeView: UITextFieldDelegate {
    
    // MARK: - UITextField Delegate
    
    // TODO: - Wrap this feature into a customized text field.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)  // Dismiss the keyboard. https://stackoverflow.com/questions/24126678/close-ios-keyboard-by-touching-anywhere-using-swift
        return true
    }
    
}
