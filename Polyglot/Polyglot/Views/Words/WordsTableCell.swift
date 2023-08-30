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
            let wordLabelText: NSMutableAttributedString = NSMutableAttributedString(string: word.accentedText(tokenSeparator: Strings.wordSeparator))
            wordLabelText.setTextColor(for: word.text, with: Colors.normalTextColor)
            wordLabel.attributedText = wordLabelText
            wordLabel.setLineSpacing(lineSpacing: 3)  // Should be called after text assignment.

            meaningLabel.text = word.meaning
        }
    }
    
    // MARK: - Views
    
    private var padding: CGFloat {
        wordLabel.font?.pointSize ?? 20
    }
    private var wordLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = Colors.defaultBackgroundColor
        label.textColor = Colors.weakTextColor
        label.lineBreakMode = .byTruncatingTail
        label.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    private var meaningLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = Colors.defaultBackgroundColor
        label.textColor = Colors.weakTextColor
        label.lineBreakMode = .byTruncatingTail
        label.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        label.textAlignment = .left
        return label
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
    
    private func updateSetups() {
        
    }
    
    private func updateViews() {
        selectionStyle = .none
        
        addSubview(wordLabel)
        addSubview(meaningLabel)
    }
    
    private func updateLayouts() {
        wordLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(padding)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        
        meaningLabel.snp.updateConstraints { (make) in
            make.top.equalTo(wordLabel.snp.bottom).offset(padding / 2)
            make.leading.equalTo(wordLabel.snp.leading)
            make.trailing.equalTo(wordLabel.snp.trailing)
            make.bottom.equalToSuperview().inset(padding)
        }
    }
    
    func updateValues(word: Word) {
        self.word = word
    }
}
