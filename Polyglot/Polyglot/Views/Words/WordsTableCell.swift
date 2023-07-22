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
            wordLabel.text = word.text
            tokensLabel.text = {
                if let tokens = word.tokens {
                    let textOfTokensLabel = tokens.pronunciationWithAccentList.joined(separator: Strings.wordSeparator)
                    if textOfTokensLabel.normalized(
                        caseInsensitive: true,
                        diacriticInsensitive: true
                    ) == word.text.normalized(
                        caseInsensitive: true,
                        diacriticInsensitive: true
                    ) {  // E.g., russian words, japanese words with katakana only.
                        wordLabel.text = textOfTokensLabel
                        return nil
                    } else {
                        return "(\(textOfTokensLabel))"
                    }
                } else {
                    return nil
                }
            }()
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
        label.textColor = Colors.normalTextColor
        label.lineBreakMode = .byTruncatingTail
        label.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        label.textAlignment = .left
        return label
    }()
    
    private var tokensLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = Colors.defaultBackgroundColor
        label.textColor = Colors.weakTextColor
        label.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        label.textAlignment = .left
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
    
    override func layoutSubviews() {
        super.layoutSubviews()  // Don't forget it, or the separator will not be displayed.
        
        wordLabel.frame = CGRect(
            x: wordLabel.frame.minX,
            y: wordLabel.frame.minY,
            width: min(wordLabel.intrinsicContentSize.width, contentView.frame.width - padding * 2),  // Fix the width.
            height: wordLabel.intrinsicContentSize.height
        )
        tokensLabel.frame = CGRect(
            x: wordLabel.frame.maxX + padding / 2,
            y: tokensLabel.frame.minY,
            width: frame.maxX - (wordLabel.frame.maxX + padding / 2) - padding,  // Update the width.
            height: tokensLabel.frame.height
        )
        
        //        let padding = wordLabel.font?.pointSize ?? 20
        //
        //        // Use updateConstraints instead of makeConstraints,
        //        // else the text will be truncated after scrolling.
        //        wordLabel.snp.updateConstraints { (make) in
        //            make.leading.equalToSuperview()
        //            make.centerY.equalToSuperview()
        //            make.width.equalTo(wordLabel.intrinsicContentSize.width)
        //        }
        //
        //        tokensLabel.snp.updateConstraints { (make) in
        //            make.leading.equalTo(wordLabel.snp.trailing).offset(5)
        //            make.centerY.equalToSuperview()
        //            make.width.lessThanOrEqualTo(tokensLabel.intrinsicContentSize.width)
        //        }
        //
        //        // Before layoutSubview(), the width of the word label is not clear,
        //        // resulting in a wrong layout of the meaning label.
        //        meaningLabel.snp.makeConstraints { (make) in
        //            make.leading.equalTo(tokensLabel.snp.trailing).offset(padding)
        //            make.trailing.equalToSuperview()
        //            make.centerY.equalToSuperview()
        //        }
    }
    
    private func updateSetups() {
        
    }
    
    private func updateViews() {
        selectionStyle = .none
        
        addSubview(wordLabel)
        addSubview(tokensLabel)
        addSubview(meaningLabel)
    }
    
    private func updateLayouts() {
        wordLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(padding)
            make.leading.equalToSuperview().inset(padding)
        }
        
        tokensLabel.snp.updateConstraints { (make) in
            make.top.equalTo(wordLabel.snp.top)
            make.leading.equalTo(wordLabel.snp.trailing).offset(5)
            make.trailing.equalToSuperview().inset(padding)
        }
        
        meaningLabel.snp.updateConstraints { (make) in
            make.top.equalTo(wordLabel.snp.bottom).offset(padding / 2)
            make.leading.equalTo(wordLabel.snp.leading)
            make.trailing.equalTo(tokensLabel.snp.trailing)
            make.bottom.equalToSuperview().inset(padding)
        }
    }
    
    func updateValues(word: Word) {
        self.word = word
    }
}
