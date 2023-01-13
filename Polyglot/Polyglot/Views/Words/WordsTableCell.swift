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
    
    private var mainView: UIView = UIView()
    
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
    
    override func layoutSubviews() {
        let padding = wordLabel.font?.pointSize ?? 20
        
        wordLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        // Before layoutSubview(), the width of the word label is not clear,
        // resulting in a wrong layout of the meaning label.
        meaningLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(wordLabel.snp.trailing).offset(padding)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    
    private func updateSetups() {
      
    }
    
    private func updateViews() {
        selectionStyle = .none
        
        addSubview(mainView)
        
        mainView.addSubview(wordLabel)
        mainView.addSubview(meaningLabel)
    }
    
    private func updateLayouts() {
        mainView.snp.makeConstraints { (make) in
            make.height.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.9)
            make.centerX.centerY.equalToSuperview()
        }
    }
    
    func updateValues(word: Word) {
        self.word = word
    }
}
