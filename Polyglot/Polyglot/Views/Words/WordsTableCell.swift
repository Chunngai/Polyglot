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
            meaningLabel.text = word.meaning
        }
    }
    
    // MARK: - Views
    
    private var wordLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = Colors.defaultBackgroundColor
        label.textColor = Colors.normalTextColor
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
    
    private func updateSetups() {
      
    }
    
    private func updateViews() {
        selectionStyle = .none
        
        addSubview(wordLabel)
        addSubview(meaningLabel)
    }
    
    private func updateLayouts() {
        let padding = wordLabel.font?.pointSize ?? 20
        
        wordLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(padding)
            make.leading.equalToSuperview().inset(padding)
            make.centerY.equalToSuperview()
        }
        
        meaningLabel.snp.makeConstraints { (make) in
            make.top.equalTo(wordLabel.snp.top)
            make.leading.equalTo(wordLabel.snp.trailing).offset(padding)
            make.centerY.equalToSuperview()
        }
    }
    
    func updateValues(word: Word) {
        self.word = word
    }
}
