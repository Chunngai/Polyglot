//
//  WordsTableCell.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class WordsTableCell: UITableViewCell {
    
    var wordLabelAttributedText: NSMutableAttributedString {
        
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: Colors.normalTextColor,
            .font: UIFont.systemFont(ofSize: Sizes.smallFontSize)
        ]
        var attrText = NSMutableAttributedString(
            string: word.text,
            attributes: attrs
        )
        
        guard let tokens = word.tokens else {
            return attrText
        }
        guard LangCode.currentLanguage == .ja || LangCode.currentLanguage == .ru else {
            return attrText
        }
            
        if LangCode.currentLanguage == .ja {
            
            let pronunciation: String = tokens.pronunciations.joined(separator: Strings.wordSeparator)
            if pronunciation.normalized(
                caseInsensitive: true,
                diacriticInsensitive: true
            ) == word.text.normalized(
                caseInsensitive: true,
                diacriticInsensitive: true
            ) {  // E.g., japanese words with katakana only.
                
                let accentLocs = calculateAccentLocs(
                    for: pronunciation,
                    with: tokens
                )
                setBoldChars(
                    for: accentLocs,
                    of: attrText
                )
                return attrText
                
            } else {
                
                attrText = NSMutableAttributedString(
                    string: "\(word.text) (\(pronunciation))",
                    attributes: attrs
                )
                
                var accentLocs = calculateAccentLocs(
                    for: pronunciation,
                    with: tokens
                )
                for i in 0..<accentLocs.count {
                    accentLocs[i] += word.text.count + 2  // " ("
                }
                setBoldChars(
                    for: accentLocs,
                    of: attrText
                )
                attrText.setTextColor(
                    for: pronunciation,
                    with: Colors.weakTextColor
                )
                return attrText
                                
            }
            
        } else if LangCode.currentLanguage == .ru {
            
            let accentLocs = calculateAccentLocs(
                for: word.text,
                with: tokens
            )
            setBoldChars(
                for: accentLocs,
                of: attrText
            )
            return attrText
            
        }

        return attrText
    }
    
    // MARK: - Models
    
    var word: Word! {
        didSet {
            wordLabel.attributedText = wordLabelAttributedText
            wordLabel.setLineSpacing(lineSpacing: 3)  // Should be called after text assignment.

            meaningLabel.text = word.meaning
            meaningLabel.setLineSpacing(lineSpacing: 3)
        }
    }
    
    // MARK: - Views
    
    private var padding: CGFloat {
        wordLabel.font?.pointSize ?? 20
    }
    private var wordLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = Colors.defaultBackgroundColor
        label.lineBreakMode = .byTruncatingTail
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
        label.numberOfLines = 0
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

extension WordsTableCell {
    
    // MARK: - Utils
    
    private func setBoldChars(for locations: [Int], of attrStr: NSMutableAttributedString) {
        
        for loc in locations {
            if loc >= attrStr.length {
                continue
            }
            attrStr.bold(for: NSRange(
                location: loc,
                length: 1
            ))
        }
    }
    
}
