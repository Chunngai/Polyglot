//
//  LanguageCell.swift
//  Polyglot
//
//  Created by Sola on 2022/12/20.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class LanguageButton: UIButton {

    private var lang: String!
    
    // MARK: - Controllers
    private var delegate: MainViewController!
    
    // MARK: - Views
    
    private lazy var flagImageView: UIImageView = UIImageView()
    
    private lazy var languageLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = nil
        return label
    }()
    
    // MARK: - Init
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        
        addSubview(flagImageView)
        addSubview(languageLabel)
        
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func updateViews() {
        backgroundColor = nil
    }
    
    private func updateLayouts() {
        flagImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        languageLabel.snp.makeConstraints { (make) in
            make.top.equalTo(flagImageView.snp.bottom).offset(10)
            make.centerX.equalTo(flagImageView.snp.centerX)
        }
    }
    
    func updateValues(iconName: String, langName: NSAttributedString, delegate: MainViewController) {
        // Infer the language from the icon name.
        // TODO: - Maybe use a language identifier?
        self.lang = iconName
        self.delegate = delegate
        
        flagImageView.image = UIImage(imageLiteralResourceName: iconName).scale(to: Sizes.languageFlagScaleFactor)
        languageLabel.attributedText = langName
    }
}

extension LanguageButton {
    
    // MARK: - Selectors.
    
    @objc private func tapped() {
        delegate.selectLanguage(lang: self.lang)
    }
}

protocol LanguageButtonDelegate {
    
    func selectLanguage(lang: String)
    
}
