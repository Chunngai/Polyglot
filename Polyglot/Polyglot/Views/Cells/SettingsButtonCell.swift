//
//  SettingsButtonCell.swift
//  Polyglot
//
//  Created by Ho on 6/7/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class SettingsButtonCell: UITableViewCell {
    
    var buttonFunc: (() -> Void)!
    
    // MARK: - Views
    
    var button: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: Sizes.mediumFontSize)
        button.setTitleColor(Colors.activeSystemButtonColor, for: .normal)
        button.contentHorizontalAlignment = .right
        return button
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
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    private func updateViews() {
        selectionStyle = .none
        contentView.addSubview(button)
    }
    
    private func updateLayouts() {
        button.snp.makeConstraints { make in
            make.leading.equalTo(imageView!.snp.trailing).offset(20)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(20)
        }
    }

}

extension SettingsButtonCell {
    
    @objc
    private func buttonTapped() {
        self.buttonFunc()
    }
    
}
