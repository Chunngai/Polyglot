//
//  HomeScreenTopView.swift
//  Polyglot
//
//  Created by Ho on 5/7/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import UIKit

class HomeScreenTopView: UIView {
    
    // MARK: - Controllers
    
    var delegate: HomeScreenTopViewDelegate!
    
    // MARK: - Views
    
    var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    var languageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: Sizes.largeFontSize)
        label.isUserInteractionEnabled = true
        return label
    }()

    var changeLanguageButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.changeLanguage + " ›", for: .normal)
        button.setTitleColor(Colors.weakTextColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: Sizes.extraSmallFontSize)
        button.contentEdgeInsets = UIEdgeInsets(top: -1, left: 0, bottom: -1, right: 0)
        return button
    }()
    
    var settingsButton: UIButton = {
        let button = UIButton()
        button.setImage(Images.settingsImage, for: .normal)
        // Add border
        button.layer.borderWidth = 1.0  // Set border width
        button.layer.borderColor = UIColor.systemGray3.cgColor  // Set border color
        // Add rounded corners
        button.layer.masksToBounds = true  // This is needed for cornerRadius to work
        button.layer.cornerRadius = Sizes.smallCornerRadius  // Adjust this value to change the roundness
        // Add padding between the border and the image
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return button
    }()
    
    var languageChangingTappingView: UIView = {
        let view = UIView()
        view.backgroundColor = nil
        return view
    }()
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
          
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func updateSetups() {
        
//        imageView.addGestureRecognizer(UITapGestureRecognizer(
//            target: self,
//            action: #selector(changeLanguageButtonTapped)
//        ))
//        languageLabel.addGestureRecognizer(UITapGestureRecognizer(
//            target: self,
//            action: #selector(changeLanguageButtonTapped)
//        ))
//        changeLanguageButton.addTarget(
//            self,
//            action: #selector(changeLanguageButtonTapped),
//            for: .touchUpInside
//        )
        
        languageChangingTappingView.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(changeLanguageButtonTapped)
        ))
        
        settingsButton.addTarget(
            self,
            action: #selector(settingsButtonTapped),
            for: .touchUpInside
        )
        
    }
    
    private func updateViews() {
        
        addSubview(imageView)
        addSubview(languageLabel)
        addSubview(changeLanguageButton)
        addSubview(languageChangingTappingView)
        
        addSubview(settingsButton)
        
    }
    
    private func updateLayouts() {
        
        imageView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
        }
        
        languageLabel.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(10)
            make.top.equalTo(imageView).offset(2)
        }
        
        changeLanguageButton.snp.makeConstraints { make in
            make.leading.equalTo(languageLabel)
            make.bottom.equalTo(imageView).offset(-2)
        }
        
        languageChangingTappingView.snp.makeConstraints { make in
            make.top.leading.bottom.equalTo(imageView)
            make.trailing.equalTo(changeLanguageButton)
        }
        
        settingsButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(imageView)
        }
        
    }

}

extension HomeScreenTopView {
    
    @objc private func changeLanguageButtonTapped() {
        delegate.changeLanguage()
    }
    
    @objc private func settingsButtonTapped() {
        delegate.openSettings()
    }
    
}

protocol HomeScreenTopViewDelegate {
    
    func changeLanguage()
    func openSettings()
    
}
