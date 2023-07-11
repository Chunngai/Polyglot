//
//  WordsEditViewController.swift
//  Polyglot
//
//  Created by Sola on 2023/1/2.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class WordsEditViewController: UIViewController {
    
    var words: [String] {
        wordListTextView.text.split(with: "\n")
    }
    var machineTranslations: [String] {
        get {
            machineTranslationTextView.text.split(with: "\n")
        }
        set {
            machineTranslationTextView.text = newValue.joined(separator: "\n")
        }
    }
    
    // MARK: - Controllers
    
    var delegate: WordsEditViewControllerDelegate!
    
    // MARK: - Views
    
    var mainView: UIView = {
        let view = UIView()
        return view
    }()
    
    var wordListView: UIView = {
        let view = UIView()
        return view
    }()
    var wordListLabel: UIView = {
        let label = UILabel()
        label.text = Strings.wordListPrompt
        label.textColor = Colors.weakTextColor
        label.font = UIFont.systemFont(ofSize: Sizes.largeFontSize)
        return label
    }()
    var wordListTextView: UITextView = {
        let textView = UITextView()
        textView.showsVerticalScrollIndicator = false
        textView.layer.masksToBounds = true
        textView.layer.cornerRadius = Sizes.defaultCornerRadius
        textView.backgroundColor = Colors.lightGrayBackgroundColor
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        textView.typingAttributes = Attributes.defaultLongTextAttributes
        return textView
    }()
    
    var machineTranslationView: UIView = {
        let view = UIView()
        return view
    }()
    var machineTranslationLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.machineTranslationPrompt
        label.textColor = Colors.weakTextColor
        label.font = UIFont.systemFont(ofSize: Sizes.largeFontSize)
        return label
    }()
    var machineTranslationTextView: UITextView = {
        let textView = UITextView()
        textView.showsVerticalScrollIndicator = false
        textView.layer.masksToBounds = true
        textView.layer.cornerRadius = Sizes.defaultCornerRadius
        textView.backgroundColor = Colors.lightGrayBackgroundColor
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        textView.typingAttributes = Attributes.defaultLongTextAttributes
        return textView
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
        
        // Hide the nav bar separator but do not make the nav bar bg transparent.
        // https://stackoverflow.com/questions/61297266/hide-navigation-bar-separator-line-on-ios-13
        navigationController?.navigationBar.isTranslucent = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        navigationController?.navigationBar.isTranslucent = true
    }

    private func updateSetups() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: Icons.cancelIcon,
            style: .plain,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: Icons.doneIcon,
            style: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
        
        wordListTextView.delegate = self
    }
    
    private func updateViews() {
        view.backgroundColor = Colors.defaultBackgroundColor
        view.addSubview(mainView)
        
        mainView.addSubview(wordListView)
        mainView.addSubview(machineTranslationView)
        
        wordListView.addSubview(wordListLabel)
        wordListView.addSubview(wordListTextView)
        
        machineTranslationView.addSubview(machineTranslationLabel)
        machineTranslationView.addSubview(machineTranslationTextView)
    }
    
    private func updateLayouts() {
        mainView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.top.equalToSuperview().inset(navigationController!.navigationBar.frame.maxY)
            make.bottom.equalToSuperview().inset(100)
        }
        
        wordListView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.46)
        }
        wordListLabel.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
        }
        wordListTextView.snp.makeConstraints { (make) in
            make.top.equalTo(wordListLabel.snp.bottom).offset(15)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        machineTranslationView.snp.makeConstraints { (make) in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.46)
        }
        machineTranslationLabel.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
        }
        machineTranslationTextView.snp.makeConstraints { (make) in
            make.top.equalTo(machineTranslationLabel.snp.bottom).offset(15)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    func updateValues() {
        
    }
}

extension WordsEditViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if machineTranslations.count < words.count {
            machineTranslations.append(contentsOf: Array<String>(
                repeating: "\n",
                count: words.count - machineTranslations.count
            ))
        }
        
        for (i, word) in words.enumerated() {
            GoogleTranslator(
                srcLang: Variables.lang,
                trgLang: Variables.pairedLang
            ).translate(query: word) { (res) in
//                var translatedText: String
//                if let translation = res.first {
//                    translatedText = translation
//                } else {
//                    translatedText = Strings.machineTranslationErrorToken
//                }
                let translatedText = res.joined(separator: "; ")
                DispatchQueue.main.async {
                    self.machineTranslations[i] = translatedText
                }
            }
        }
    }
}

extension WordsEditViewController {

    // MARK: - Selectors

    @objc private func cancelButtonTapped() {
        
        if !wordListTextView.text.isEmpty {
            presentExitWithoutSavingAlert(viewController: self) { (isOk) in
                if isOk {
                    self.navigationController?.dismiss(animated: true, completion: nil)
                } else {
                    return
                }
            }
        } else {
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }

    @objc private func doneButtonTapped() {
        var newWords: [Word] = []
        for (word, machineTranslation) in zip(words, machineTranslations) {
            if word.strip().isEmpty {
                continue
            }
            newWords.append(Word(
                text: word,
                meaning: machineTranslation
            ))
        }
        delegate.add(words: newWords)
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

protocol WordsEditViewControllerDelegate {
    
    func add(words: [Word])
    
}
