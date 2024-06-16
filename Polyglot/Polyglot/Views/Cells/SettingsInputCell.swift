//
//  SettingsInputCell.swift
//  Polyglot
//
//  Created by Ho on 6/7/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class SettingsInputCell: UITableViewCell {
        
    // MARK: - Views
    
    var textField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: Sizes.mediumFontSize)
        textField.textAlignment = .right
        textField.clearButtonMode = .whileEditing
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
    
    private func updateSetups() {
        
    }
    
    private func updateViews() {
        selectionStyle = .none
        contentView.addSubview(textField)
    }
    
    private func updateLayouts() {
        textField.snp.makeConstraints { make in
            make.leading.equalTo(imageView!.snp.trailing).offset(20)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(20)
        }
    }

}
