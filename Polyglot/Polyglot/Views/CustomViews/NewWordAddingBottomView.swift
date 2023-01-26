//
//  NewWordAddingBottomView.swift
//  Polyglot
//
//  Created by Sola on 2022/12/21.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class NewWordAddingBottomView: UIView {
    
    var word: String = "" {
        didSet {
            wordLabel.text = word
        }
    }
    
    var meaning: String {
        get {
            return meaningTextField.text ?? ""
        }
        set {
            meaningTextField.text = newValue
            delegate.meaningTextFieldEditingChanged()
        }
    }
    
    var offset: CGFloat!
    var isFloatingUp: Bool = false

    private var translator: GoogleTranslator!
    private var translations: [String] = []
    private var translationIndex: Int = 0 {
        didSet {
            guard !translations.isEmpty else {
                return
            }
            
            translationIndex = translationIndex % translations.count
        }
    }
    private var isTranslating: Bool = false {
        didSet {
            if isTranslating {
                meaningTextField.isEnabled = false  // Disable editing.
                translateButton.isHidden = true
                spinner.startAnimating()
            } else {
                meaningTextField.isEnabled = true  // Enable editing.
                spinner.stopAnimating()
                translateButton.isHidden = false
            }
        }
    }
    
    var isAddingNewWord: Bool! {
        didSet {
            doneButton.isHidden = !isAddingNewWord
            deleteButton.isHidden = isAddingNewWord
            translateButton.isHidden = !isAddingNewWord
            
            meaningTextField.isEnabled = isAddingNewWord
        }
    }
    
    // MARK: - Controllers
    
    var delegate: NewWordBottomViewDelegate! {
        didSet {
            meaningTextField.addTarget(delegate, action: #selector(delegate.meaningTextFieldEditingChanged), for: .editingChanged)
        }
    }
    
    // MARK: - Views
    
    private lazy var wordLabel: UILabel = {  // TODO: - Support editing.
        let label = UILabel()
        label.numberOfLines = NewWordAddingBottomView.wordLabelNumberOfLines
        label.lineBreakMode = .byTruncatingTail
        label.font = UIFont.systemFont(ofSize: Sizes.mediumFontSize)
        label.textColor = Colors.normalTextColor
        return label
    }()
    
    private lazy var meaningTextField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        textField.textColor = Colors.weakTextColor
        textField.placeholder = Strings.newWordBottomViewMeaningPrompt
        return textField
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton()
        button.setImage(Icons.doneIcon, for: .normal)
        return button
    }()
    private lazy var deleteButton: UIButton = {
       let button = UIButton()
        button.setImage(Icons.deleteIcon, for: .normal)
        return button
    }()
    
    private lazy var translateButton: UIButton = {
        let button = UIButton()
        button.setImage(Icons.translateIcon, for: .normal)
        return button
    }()
    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    // MARK: - Init
    
    init(frame: CGRect = .zero, wordLang: String, meaningLang: String) {
        super.init(frame: frame)
        
        translator = GoogleTranslator(srcLang: wordLang, trgLang: meaningLang)
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func updateSetups() {
        isAddingNewWord = true
        
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        translateButton.addTarget(self, action: #selector(translateButtonTapped), for: .touchUpInside)
        
        meaningTextField.delegate = self
        
        // TODO: Swipe to float down. If a new word is being added, prohibit the swiping and highlight the text field.
    }
    
    private func updateViews() {
        backgroundColor = Colors.lightBlue
        
        addSubview(wordLabel)
        addSubview(meaningTextField)
        
        addSubview(doneButton)
        addSubview(deleteButton)
        
        addSubview(translateButton)
        addSubview(spinner)
    }
    
    private func updateLayouts() {
        wordLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(20)
            make.left.equalToSuperview().inset(20)
            make.right.equalToSuperview().inset(60)
        }
        
        meaningTextField.snp.makeConstraints { (make) in
            make.top.equalTo(wordLabel.snp.bottom).offset(15)
            make.left.equalTo(wordLabel.snp.left)
            make.right.equalTo(wordLabel.snp.right)
        }
        
        doneButton.snp.makeConstraints { (make) in
            make.top.equalTo(wordLabel.snp.top)
            make.right.equalToSuperview().inset(20)
        }
        deleteButton.snp.makeConstraints { (make) in
            make.top.equalTo(wordLabel.snp.top)
            make.right.equalTo(doneButton.snp.right)
        }
        
        translateButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(meaningTextField.snp.centerY)
            make.centerX.equalTo(doneButton.snp.centerX)
        }
        spinner.snp.makeConstraints { (make) in
            make.centerY.equalTo(translateButton.snp.centerY)
            make.centerX.equalTo(translateButton.snp.centerX)
        }
    }
    
    func updateValues() {
    
    }
}

extension NewWordAddingBottomView {
    
    // MARK: - Floating Functions.
    
    func floatUp(by offset: CGFloat) {
        UIView.animate(
            withDuration: NewWordAddingBottomView.floatingDuration,
            delay: NewWordAddingBottomView.floatingDelay,
            options: [.curveEaseIn],
            animations: {
                self.frame = CGRect(
                    x: self.frame.minX,
                    y: self.frame.minY - offset,
                    width: self.frame.width,
                    height: self.frame.height
                )
                self.layoutIfNeeded()
        })
        
        isFloatingUp = true
    }
    
    func floatUp() {
        self.floatUp(by: offset)
    }
    
    func floatDown(by offset: CGFloat) {
        UIView.animate(
            withDuration: NewWordAddingBottomView.floatingDuration,
            delay: NewWordAddingBottomView.floatingDelay,
            options: [.curveEaseOut],
            animations: {
                self.frame = CGRect(
                    x: self.frame.minX,
                    y: self.frame.minY + offset,
                    width: self.frame.width,
                    height: self.frame.height
                )
                self.layoutIfNeeded()
        })
        
        isFloatingUp = false
    }
    
    func floatDown() {
        self.floatDown(by: offset)
    }
    
    func clear() {
        word = ""
        meaning = ""
        
        translations = []
        translationIndex = 0
        
        isAddingNewWord = true
    }
}

extension NewWordAddingBottomView {
    
    // MARK: - Selectors
    
    @objc private func doneButtonTapped() {
        
        meaningTextField.endEditing(true)  // Dismiss the keyboard.
        delegate.addNewWord()
    }
 
    @objc private func deleteButtonTapped() {
        
        delegate.deleteNewWord()
    }
    
    @objc private func translateButtonTapped() {
        
        if self.translations.isEmpty {
            
            isTranslating = true
            self.translator.translate(query: self.word) { (translations) in
                
                self.translations = translations
                
                // https://stackoverflow.com/questions/58087536/modifications-to-the-layout-engine-must-not-be-performed-from-a-background-thr
                DispatchQueue.main.async {
                    self.isTranslating = false
                    
                    if !translations.isEmpty {
                        self.meaning = translations[self.translationIndex]
                    }
                }
            }
        } else {
            self.translationIndex += 1
            if !translations.isEmpty {
                self.meaning = self.translations[self.translationIndex]
            }
        }
    }
}

extension NewWordAddingBottomView: UITextFieldDelegate {
    
    // MARK: - UITextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
    
}

@objc protocol NewWordBottomViewDelegate {
    
    func meaningTextFieldEditingChanged()
    func addNewWord()
    func deleteNewWord()
    
}

extension NewWordAddingBottomView {
    
    // MARK: - Constants
    
    private static let wordLabelNumberOfLines: Int = 1
    private static let floatingDuration: TimeInterval = 0.3
    private static let floatingDelay: TimeInterval = 0
}
