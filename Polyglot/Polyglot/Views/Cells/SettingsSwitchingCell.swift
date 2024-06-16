//
//  SettingsSwitchingCell.swift
//  Polyglot
//
//  Created by Ho on 6/11/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class SettingsSwitchingCell: UITableViewCell {
    
    var funcAfterSwitching: ((Bool) -> Void)?
    
    // MARK: - Views
    
    var label: UILabel = {
        let label = UILabel()
        label.textColor = Colors.normalTextColor
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: Sizes.mediumFontSize)
        return label
    }()
    var switchView: UISwitch = {
        let switchView = UISwitch()
        switchView.isOn = true
        return switchView
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
        switchView.addTarget(self, action: #selector(switched), for: .valueChanged)
    }
    
    private func updateViews() {
        selectionStyle = .none
        
        contentView.addSubview(switchView)
        contentView.addSubview(label)
    }
    
    private func updateLayouts() {
        label.snp.makeConstraints { make in
            make.leading.equalTo(imageView!.snp.trailing).offset(15)
            make.centerY.equalToSuperview()
        }
        
        switchView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(20)
        }
    }
    
}

extension SettingsSwitchingCell {
    
    @objc
    private func switched() {
        if let funcAfterSwitching = funcAfterSwitching {
            funcAfterSwitching(switchView.isOn)
        }
    }
    
}
