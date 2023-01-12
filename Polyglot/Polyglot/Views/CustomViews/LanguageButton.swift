//
//  LanguageCell.swift
//  Polyglot
//
//  Created by Sola on 2022/12/20.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class LanguageButton: UIButton {

    private var langCode: String!
    
    // MARK: - Controllers
    
    var delegate: HomeViewController!
    
    // MARK: - Views
    
    private lazy var langImageView: UIImageView = UIImageView()
    
    private lazy var langLabel: UILabel = UILabel()
    
    // MARK: - Init
        
    init(frame: CGRect = .zero, langCode: String) {
        super.init(frame: frame)
        
        self.langCode = langCode
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func updateSetups() {
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }
    
    private func updateViews() {
        addSubview(langImageView)
        addSubview(langLabel)
    }
    
    private func updateLayouts() {
        langImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        langLabel.snp.makeConstraints { (make) in
            make.top.equalTo(langImageView.snp.bottom).offset(10)
            make.centerX.equalTo(langImageView.snp.centerX)
        }
    }
    
    func updateValues(lang: String, langString: NSAttributedString, delegate: HomeViewController) {
        self.delegate = delegate
        
    }
}

extension LanguageButton {
    
    // MARK: - Selectors.
    
    @objc private func tapped() {
        delegate.selectLanguage(lang: self.langCode)
    }
}

extension LanguageButton {
    
    func set(text: String? = nil, attributedText: NSAttributedString? = nil) {
        if let text = text {
            langLabel.text = text
        }
        if let attributedText = attributedText {
            langLabel.attributedText = attributedText
        }
    }
    
    func set(image: UIImage) {
        langImageView.image = image
    }
    
}

protocol LanguageButtonDelegate {
    
    func selectLanguage(lang: String)
    
}
