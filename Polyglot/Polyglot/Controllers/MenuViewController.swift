//
//  MenuViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/20.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {

    private var lang: String!
    
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
    private let languageFlagImageView: UIImageView = UIImageView()
    private let secondaryPromptLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = nil
        return label
    }()
    
    // TODO: - Maybe convert to a table later?
    private lazy var contentSelectionStackView: ThreeButtonSelectionStack = {
        let stackView = ThreeButtonSelectionStack()
        stackView.updateValues(
            buttonTexts: [
                Strings.words,
                Strings.reading,
                Strings.translation
            ]
        )
        return stackView
    }()
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSetups()
        updateViews()
        updateLayouts()
    }

    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarUIView?.backgroundColor = Colors.weakLightBlue
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.backgroundColor = nil  // Reset the bg color from lightblue to nil.

        UIApplication.shared.statusBarUIView?.backgroundColor = Colors.defaultBackgroundColor
    }
    
    private func updateSetups() {
//        navigationItem.rightBarButtonItem = UIBarButtonItem(
//            image: UIImage(imageLiteralResourceName: Assets.historyIcon),
//            style: .plain,
//            target: self,
//            action: #selector(showHistory)
//        )
        
        contentSelectionStackView.delegate = self
    }
    
    private func updateViews() {
        view.backgroundColor = Colors.defaultBackgroundColor
        view.addSubview(backgroundView)
        view.addSubview(mainView)
        
        mainView.addSubview(promptView)
        mainView.addSubview(contentSelectionStackView)

        promptView.addSubview(primaryPromptLabel)
        promptView.addSubview(languageFlagImageView)
        promptView.addSubview(secondaryPromptLabel)
        
        primaryPromptLabel.attributedText = Strings.menuPrimaryPrompt
        secondaryPromptLabel.attributedText = Strings.menuSecondaryPrompt
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
        languageFlagImageView.snp.makeConstraints { (make) in
            make.top.equalTo(primaryPromptLabel.snp.top)
            make.left.equalTo(primaryPromptLabel.snp.right).offset(20)
        }
        secondaryPromptLabel.snp.makeConstraints { (make) in
            make.top.equalTo(primaryPromptLabel.snp.bottom).offset(10)
            make.left.equalTo(primaryPromptLabel.snp.left)
        }
        
        contentSelectionStackView.snp.makeConstraints { (make) in
            make.top.equalTo(backgroundView.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
        }
    }
    
    func updateValues(lang: String) {
        self.lang = lang
        
        // TODO: - Use the font size of the primary prompt to scale.
        languageFlagImageView.image = UIImage(imageLiteralResourceName: lang).scale(to: Sizes.languageFlagScaleFactor)
    }
}

extension MenuViewController {
    
    // MARK: - Selectors
    
    @objc private func showHistory() {
        let historyViewController = HistoryViewController()
        historyViewController.updateValues()
        navigationController?.pushViewController(historyViewController, animated: true)
    }
}


extension MenuViewController: ThreeItemSelectionStackDelegate {
    
    @objc func buttonSelected(sender: UIButton) {
        if sender.tag == contentSelectionStackView.buttonTags[0] {
            let wordsViewController = WordsViewController()
            wordsViewController.updateValues()
            navigationController?.pushViewController(wordsViewController, animated: true)
        } else if sender.tag == contentSelectionStackView.buttonTags[1] {
            let readingViewController = ReadingViewController()
            readingViewController.updateValues()
            navigationController?.pushViewController(readingViewController, animated: true)
        } else if sender.tag == contentSelectionStackView.buttonTags[2] {
            // TODO: - Error when articles.count == 0.
            
            let translationPracticeViewController = TranslationPracticeViewController()
            translationPracticeViewController.updateValues(articles: Article.load())
            
            let navController = NavController(rootViewController: translationPracticeViewController)
            navigationController?.present(navController, animated: true, completion: nil)
        }
    }
    
}
