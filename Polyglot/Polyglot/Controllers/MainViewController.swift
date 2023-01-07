//
//  ViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/20.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit
import SnapKit

class MainViewController: UIViewController {

    // MARK: - Views
    
    private var backgroundView = BackgroundView()
    
    private lazy var mainView: UIView = {
        let view = UIView()
        view.backgroundColor = nil
        return view
    }()
    
    private lazy var promptView: UIView = {
        let view = UIView()
        view.backgroundColor = nil
        return view
    }()
    private let primaryPromptLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = nil
        return label
    }()
    private let secondaryPromptLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = nil
        return label
    }()
    
    // TODO: - Maybe convert to a table later?
    private lazy var languageButtonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.backgroundColor = nil
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        return stackView
    }()
    // TODO: - Update here.
    private var enButton: LanguageButton = LanguageButton()
    private var jaButton: LanguageButton = LanguageButton()
    private var esButton: LanguageButton = LanguageButton()
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(backgroundView)
        view.addSubview(mainView)
                
        mainView.addSubview(promptView)
        promptView.addSubview(primaryPromptLabel)
        promptView.addSubview(secondaryPromptLabel)
        
        mainView.addSubview(languageButtonStackView)
        languageButtonStackView.addArrangedSubview(enButton)
        languageButtonStackView.addArrangedSubview(jaButton)
        languageButtonStackView.addArrangedSubview(esButton)
        
        updateViews()
        updateLayouts()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Reset the bg color from lightblue to nil.
        navigationController?.navigationBar.backgroundColor = nil
    }
    
    private func updateViews() {
        view.backgroundColor = Colors.defaultBackgroundColor
        
        // The white navi bar shadows the view.
        // Set to the same color to hide it.
        navigationController?.navigationBar.backgroundColor = Colors.weakLightBlue
        
        primaryPromptLabel.attributedText = Strings.mainPrimaryPrompt
        secondaryPromptLabel.attributedText = Strings.mainSecondaryPrompt
        
        enButton.updateValues(lang: Assets.enIcon, langString: Strings.en, delegate: self)
        jaButton.updateValues(lang: Assets.jaIcon, langString: Strings.ja, delegate: self)
        esButton.updateValues(lang: Assets.esIcon, langString: Strings.es, delegate: self)
    }
    
    // TODO: - Update the insets and offsets here.
    // TODO: - Use relative insets and offsets instead.
    private func updateLayouts() {
        backgroundView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(UIScreen.main.bounds.height / 1.8)
        }
        
        mainView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.top.equalToSuperview().inset(243)
            make.bottom.equalToSuperview()
        }
    
        promptView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.4)
        }
        primaryPromptLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
        }
        secondaryPromptLabel.snp.makeConstraints { (make) in
            make.top.equalTo(primaryPromptLabel.snp.bottom).offset(10)
            make.left.equalTo(primaryPromptLabel.snp.left)
        }
        
        languageButtonStackView.snp.makeConstraints { (make) in
            make.top.equalTo(backgroundView.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
        }
    }
}

extension MainViewController: LanguageButtonDelegate {
    
    func selectLanguage(lang: String) {
        let menuViewController = MenuViewController()
        menuViewController.updateValues(lang: lang)
        
        navigationController?.pushViewController(menuViewController, animated: true)
    }
    
}
