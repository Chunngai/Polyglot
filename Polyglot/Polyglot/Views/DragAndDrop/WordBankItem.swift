//
//  WordBankItem.swift
//  Polyglot
//
//  Created by Sola on 2023/2/12.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class WordBankItem: UICollectionViewCell {
    
    // MARK: - Views
    
    // TODO: - Update here.
    static func makeLabel() -> UILabel {
        let label = UILabel()
        label.backgroundColor = Colors.lightBlue
        label.layer.masksToBounds = true
        label.layer.cornerRadius = Sizes.smallCornerRadius
        label.textColor = Colors.normalTextColor
        label.font = WordBankItem.labelFont
        label.textAlignment = .center
        return label
    }
    
    lazy var label: UILabel = WordBankItem.makeLabel()
    
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
        addSubview(label)
    }
    
    private func updateLayouts() {
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

extension WordBankItem {
    
    // MARK: - Constants
    
    static let labelFont: UIFont = UIFont.systemFont(ofSize: Sizes.wordPracticeFontSize)
}
