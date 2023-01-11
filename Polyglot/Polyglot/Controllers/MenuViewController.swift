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
        return view
    }()
    
    private lazy var promptView: UIView = {
        let view = UIView()
        return view
    }()
    private let primaryPromptLabel: UILabel = {
        let label = UILabel()
        label.attributedText = Strings.menuPrimaryPrompt
        return label
    }()
    private let secondaryPromptLabel: UILabel = {
        let label = UILabel()
        label.attributedText = Strings.menuSecondaryPrompt
        return label
    }()
    private lazy var langImageView: UIImageView = UIImageView()
    
    private lazy var menuButtonStackView: ThreeButtonSelectionStack = {
        let stackView = ThreeButtonSelectionStack()
        stackView.set(texts: [
            Strings.words,
            Strings.reading,
            Strings.translation
        ])
        return stackView
    }()
    
    // MARK: - Init
    
    // https://stackoverflow.com/questions/30679129/how-to-write-init-methods-of-a-uiviewcontroller-in-swift
    
    convenience init(lang: String) {
        self.init(nibName:nil, bundle:nil)
        
        self.lang = lang
        self.langImageView.image = {
            // TODO: - Simplify here.
            switch lang {
            case Strings.en: return Images.enImage
            case Strings.ja: return Images.jaImage
            case Strings.es: return Images.esImage
            default: return UIImage()
            }
        }()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSetups()
        updateViews()
        updateLayouts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Reset the bg color from lightblue to nil.
        navigationController?.navigationBar.backgroundColor = nil
    }
    
    private func updateSetups() {
        menuButtonStackView.delegate = self
    }
    
    private func updateViews() {
        view.backgroundColor = Colors.defaultBackgroundColor
        view.addSubview(backgroundView)
        view.addSubview(mainView)
        
        mainView.addSubview(promptView)
        mainView.addSubview(menuButtonStackView)

        promptView.addSubview(primaryPromptLabel)
        promptView.addSubview(langImageView)
        promptView.addSubview(secondaryPromptLabel)
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
        langImageView.snp.makeConstraints { (make) in
            make.top.equalTo(primaryPromptLabel.snp.top)
            make.left.equalTo(primaryPromptLabel.snp.right).offset(20)
        }
        secondaryPromptLabel.snp.makeConstraints { (make) in
            make.top.equalTo(primaryPromptLabel.snp.bottom).offset(10)
            make.left.equalTo(primaryPromptLabel.snp.left)
        }
        
        menuButtonStackView.snp.makeConstraints { (make) in
            make.top.equalTo(backgroundView.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
        }
    }
}

extension MenuViewController: ThreeItemSelectionStackDelegate {
    
    @objc func buttonSelected(sender: UIButton) {
        
        switch sender.tag {
        case 0: navigationController?.pushViewController(
            WordsViewController(),
            animated: true
        )
        case 1: navigationController?.pushViewController(
            ReadingViewController(),
            animated: true
        )
        case 2:
            // TODO: - Error when articles.count == 0.
            let translationPracticeViewController = TranslationPracticeViewController()
            translationPracticeViewController.updateValues(articles: Article.load())
            
            let navController = NavController(rootViewController: translationPracticeViewController)
            navigationController?.present(navController, animated: true, completion: nil)
        default: return
        }
    }
    
}
