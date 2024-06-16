//
//  SettingsSlidingCell.swift
//  Polyglot
//
//  Created by Ho on 6/11/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class SettingsSlidingCell: UITableViewCell {
    
    var step: Float!
    var formatingFunc: ((Float) -> String) = SettingsSlidingCell.defaultFormattingFunc
        
    // MARK: - Views
    
    var slider: UISlider = {
        let slider = UISlider()
        return slider
    }()
    var label: UILabel = {
        let label = UILabel()
        label.textColor = Colors.weakTextColor
        label.font = UIFont.systemFont(ofSize: Sizes.mediumFontSize)
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
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
    }
    
    private func updateViews() {
        selectionStyle = .none

        contentView.addSubview(slider)
        contentView.addSubview(label)
    }
    
    private func updateLayouts() {
        label.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        slider.snp.makeConstraints { make in
            make.leading.equalTo(imageView!.snp.trailing).offset(15)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(label.snp.leading).offset(-15)
        }
    }

}

extension SettingsSlidingCell {
    
    @objc
    private func sliderValueChanged(_ sender: UISlider) {
        
        // Ref: https://stackoverflow.com/questions/7083375/ios-how-to-make-slider-stop-at-discrete-points
        let roundedValue = round(sender.value / step) * step
        sender.setValue(roundedValue, animated: false)  // Adjust slider to the discrete value
        
        label.text = formatingFunc(slider.value)
    }
    
}

extension SettingsSlidingCell {
    
    static let defaultFormattingFunc: (Float) -> String = { (sliderVal: Float) -> String in
        return String(format: "%.1f", sliderVal)
    }
    
}
