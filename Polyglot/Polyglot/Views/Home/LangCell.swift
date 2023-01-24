//
//  LangCell.swift
//  Polyglot
//
//  Created by Sola on 2023/1/25.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class LangCell: UICollectionViewCell {
    
    var langCode: String! {
        didSet {
            
            langLabelTexts = Strings.langStrings(for: langCode)
            
            langImageView.image = Images.langImages[langCode]!
        }
    }
    
    private var langLabelTexts: [String: String]!  // Language name in different languages.
    var langOfLangLabelText: String! {
        didSet {
            langLabel.attributedText = NSAttributedString(
                string: langLabelTexts[langOfLangLabelText]!,
                attributes: Attributes.langStringAttrs
            )
        }
    }
    
    // MARK: - Views
    
    private lazy var langImageView: UIImageView = UIImageView()
    
    private lazy var langLabel: UILabel = UILabel()
    
    // MARK: - Init
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
                
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateSetups() {
    }
    
    private func updateViews() {
        addSubview(langImageView)
        addSubview(langLabel)
    }
    
    private func updateLayouts() {
        langImageView.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview()
        }
        
        langLabel.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.centerX.equalTo(langImageView.snp.centerX)
        }
    }
}
