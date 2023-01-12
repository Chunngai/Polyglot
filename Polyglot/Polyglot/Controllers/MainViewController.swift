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

    private var isExecutingTextAnimation: Bool = true
    
    // MARK: - Views
    
    private var backgroundView = BackgroundView()
    
    private lazy var mainView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var promptView: UIView = {
        let view = UIView()
        return view
    }()
    private let primaryPromptLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: Strings.mainPrimaryPrompt,
            attributes: Attributes.primaryPromptAttributes
        )
        return label
    }()
    private let secondaryPromptLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: Strings.mainSecondaryPrompt,
            attributes: Attributes.secondaryPromptAttributes
        )
        return label
    }()
    
    // TODO: - Maybe convert to a table later?
    private lazy var languageButtonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        return stackView
    }()
    private var enButton: LanguageButton = {
        let button = LanguageButton(langCode: LangCodes.en)
        button.set(attributedText: NSAttributedString(
            string: Strings.enString,
            attributes: Attributes.langStringAttrs
        ))
        button.set(image: Images.enImage)
        return button
    }()
    private var jaButton: LanguageButton = {
           let button = LanguageButton(langCode: LangCodes.ja)
           button.set(attributedText: NSAttributedString(
               string: Strings.jaString,
               attributes: Attributes.langStringAttrs
           ))
           button.set(image: Images.jaImage)
           return button
       }()
    private var esButton: LanguageButton = {
           let button = LanguageButton(langCode: LangCodes.es)
           button.set(attributedText: NSAttributedString(
               string: Strings.esString,
               attributes: Attributes.langStringAttrs
           ))
           button.set(image: Images.esImage)
           return button
       }()
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // https://juejin.cn/post/6905235669758443533
        // https://stackoverflow.com/questions/27501732/stop-and-start-nsthread-in-swift
        Thread.detachNewThreadSelector(#selector(textAnimation), toTarget: self, with: nil)
        isExecutingTextAnimation = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Reset the bg color from lightblue to nil.
        // Without resetting, the nav bar looks ugly
        // when switching from main view to menu view.
        navigationController?.navigationBar.backgroundColor = nil
        
        isExecutingTextAnimation = false
    }
    
    private func updateSetups() {
        enButton.delegate = self
        jaButton.delegate = self
        esButton.delegate = self
    }
    
    private func updateViews() {
        // The white navi bar shadows the background view.
        // Set to the same color to hide it.
        navigationController?.navigationBar.backgroundColor = Colors.lightBlue
        
        view.backgroundColor = Colors.defaultBackgroundColor
        view.addSubview(backgroundView)
        view.addSubview(mainView)
                
        mainView.addSubview(promptView)
        mainView.addSubview(languageButtonStackView)

        promptView.addSubview(primaryPromptLabel)
        promptView.addSubview(secondaryPromptLabel)
        
        languageButtonStackView.addArrangedSubview(enButton)
        languageButtonStackView.addArrangedSubview(jaButton)
        languageButtonStackView.addArrangedSubview(esButton)
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

extension MainViewController {

    // MARK: - Selectors
    
    @objc func textAnimation() {
        var langCodeIndex: Int = 0
        while true {
            // https://stackoverflow.com/questions/3073520/animate-text-change-in-uilabel
            DispatchQueue.main.async {
                
                let langCode = LangCodes.codes[langCodeIndex]
                langCodeIndex = (langCodeIndex + 1) % LangCodes.codes.count

                UIView.transition(
                    with: self.view,
                    duration: 3,
                    // https://stackoverflow.com/questions/3237431/does-animatewithdurationanimations-block-main-thread
                    // .allowUserInteraction is needed else the button becomes not interactive.
                    options: [.transitionCrossDissolve, .allowUserInteraction],
                    animations: { [weak self] in
                        self?.primaryPromptLabel.text = Strings._mainPrimaryPrompts[langCode]
                        self?.secondaryPromptLabel.text = Strings._mainSecondaryPrompts[langCode]
                        
                        self?.enButton.set(text: Strings._enStrings[langCode])
                        self?.jaButton.set(text: Strings._jaStrings[langCode])
                        self?.esButton.set(text: Strings._esStrings[langCode])
                    }, completion: nil
                )
            }
            Thread.sleep(forTimeInterval: 3)
            
            if !isExecutingTextAnimation {
                Thread.exit()
            }
        }
    }

}

extension MainViewController: LanguageButtonDelegate {
    
    // MARK: - LanguageButton Delegate
    
    func selectLanguage(lang: String) {
        let menuViewController = MenuViewController(lang: lang)
        navigationController?.pushViewController(menuViewController, animated: true)
    }
    
}
