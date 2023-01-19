//
//  MeaningFillingPracticeView.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class MeaningFillingPracticeView: UIView {

    private var practiceItem: WordPracticeProducer.Item!
    private var key: String {
        return practiceItem.key
    }
    
    private var answer: String {
        textField.text!.strip()
    }
    
    // MARK: - Controllers
    
    var delegate: WordsPracticeViewController!
    
    // MARK: - Views
    
    private var textField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: Sizes.largeFontSize)
        textField.textColor = Colors.normalTextColor
        textField.textAlignment = .center
        textField.adjustsFontSizeToFitWidth = true
        textField.minimumFontSize = Sizes.smallFontSize
        return textField
    }()
    
    private var bottomLine: Separator = {
        let bottomLine = Separator()
        return bottomLine
    }()
    
    private var referenceLabel: UILabel = {
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
    
    func updateValues(practiceItem: WordPracticeProducer.Item) {
        self.practiceItem = practiceItem
    }
}

extension MeaningFillingPracticeView: PracticeViewDelegate {
    
    // MARK: - Practice Delegate
    
    func check() -> Any {
        textField.resignFirstResponder()
        
        let attributedAnswer = NSMutableAttributedString(string: answer)
        
        let keyComponents = key.normalized.components
        let answerComponents = answer.normalized.components
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
        
        if Correctness.checkCorrectness(key: key, answer: answer) != .correct {
            referenceLabel.isHidden = false
            referenceLabel.text = "\(Strings.meaningFillingPracticeReferenceLabelPrefix)\(practiceItem.key)"
        }
        
        return answer
    }
}

extension MeaningFillingPracticeView {
    
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
    
}

extension MeaningFillingPracticeView: UITextFieldDelegate {
    
    // MARK: - UITextField Delegate
    
    // TODO: - Wrap this feature into a customized text field.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)  // Dismiss the keyboard. https://stackoverflow.com/questions/24126678/close-ios-keyboard-by-touching-anywhere-using-swift
        return true
    }
    
}
