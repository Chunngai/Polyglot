//
//  WordsTableCell.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class WordsTableCell: UITableViewCell {

    // MARK: - Models
    
    var word: Word! {
        didSet {
            wordTextField.text = word.text
            meaningTextField.text = word.meaning
        }
    }
    
    // MARK: - Controllers
    
    var delegate: WordsTableCellDelegate!
    
    // MARK: - Views
    
    private var wordTextField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = Colors.defaultBackgroundColor
        textField.textColor = Colors.defaultTextColor
//        label.lineBreakMode = .byTruncatingTail
        textField.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        textField.textAlignment = .left
        return textField
    }()
    
    private var meaningTextField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = Colors.defaultBackgroundColor
        textField.textColor = Colors.weakTextColor
//        label.lineBreakMode = .byTruncatingTail
        textField.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        textField.textAlignment = .left
        return textField
    }()
    
    // MARK: - Init
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Expand the width so that the text will not move to the left when editing.
        wordTextField.frame = CGRect(
            x: wordTextField.frame.minX,
            y: wordTextField.frame.minY,
            width: wordTextField.frame.width + 10,
            height: wordTextField.frame.height
        )
        meaningTextField.frame = CGRect(
            x: meaningTextField.frame.minX,
            y: meaningTextField.frame.minY,
            width: meaningTextField.frame.width + 10,
            height: meaningTextField.frame.height
        )
    }
    
    private func updateSetups() {
        wordTextField.delegate = self
        meaningTextField.delegate = self
    }
    
    private func updateViews() {
        selectionStyle = .none
        
        addSubview(wordTextField)
        addSubview(meaningTextField)
    }
    
    private func updateLayouts() {
        let padding = wordTextField.font?.pointSize ?? 20
        
        wordTextField.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(padding)
            make.leading.equalToSuperview().inset(padding)
            make.centerY.equalToSuperview()
        }
        
        meaningTextField.snp.makeConstraints { (make) in
            make.top.equalTo(wordTextField.snp.top)
            make.leading.equalTo(wordTextField.snp.trailing).offset(padding)
            make.centerY.equalToSuperview()
        }
    }
    
    func updateValues(word: Word) {
        self.word = word
    }
}

extension WordsTableCell: UITextFieldDelegate {
    
    // MARK: - UITextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate.updateWord(of: word.id, newText: wordTextField.text!, newMeaning: meaningTextField.text!)
        textField.endEditing(true)
        return true
    }
    
}

protocol WordsTableCellDelegate {
    func updateWord(of id: Int, newText: String, newMeaning: String)
}
