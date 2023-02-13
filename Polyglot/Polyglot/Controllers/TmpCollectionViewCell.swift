//
//  TmpCollectionViewCell.swift
//  Polyglot
//
//  Created by Sola on 2023/2/12.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class TmpCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Views
    
    lazy var backgroundButton: UIButton = TmpCollectionViewCell.createButton()
    
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
        
        addSubview(backgroundButton)
    }
    
    private func updateLayouts() {
        
        backgroundButton.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

extension TmpCollectionViewCell {
    
    static func createButton() -> UIButton {
        
        // TODO: - Move elsewhere?
        
        let button = UIButton()
        button.backgroundColor = Colors.strongLightBlue
        button.layer.masksToBounds = true
        button.layer.cornerRadius = Sizes.smallCornerRadius
        button.setTitleColor(Colors.normalTextColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: TmpViewController2.labelFontSize)
        button.titleLabel?.textAlignment = .center
        return button
    }
    
}
