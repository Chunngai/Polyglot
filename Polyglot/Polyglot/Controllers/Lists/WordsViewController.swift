//
//  WordsViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class WordsViewController: ListViewController {
    
    // Translation.
    
    private var translations: [String] = []
    private var translationIndex: Int = 0 {
        didSet {
            guard !translations.isEmpty else {
                return
            }
            translationIndex = translationIndex % translations.count
        }
    }
    private var isTranslating: Bool = false {
        didSet {
            if isTranslating {
                wordAddingSecondTextField?.isEnabled = false  // Disable editing.
                wordAddingSecondTextField?.rightView = translationSpinner
                translationSpinner.startAnimating()
            } else {
                wordAddingSecondTextField?.isEnabled = true  // Enable editing.
                translationSpinner.stopAnimating()
                wordAddingSecondTextField?.rightView = translationButton
            }
        }
    }
    
    // Don't use self.presentedController to obtain the alert contrller.
    // When the search controller is active, the alert controller
    // cannot be obtained with this method.
    private var wordAddingFirstTextField: UITextField? {
        return self.lastAlertController?.textFields?[0]
    }
    private var wordAddingSecondTextField: UITextField? {
        return self.lastAlertController?.textFields?[1]
    }
    private var lastlyTypedWord: String = ""
    private var lastAlertController: UIAlertController!
    
    private var isText2Meaning: Bool!
    
    // Table view.
    
    private var dataSource: [GroupedWords]! {
        didSet {
            DispatchQueue.main.async {  // Update the table in the main thread.
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Models
    
    var words: [Word]! {
        didSet {
            delegate.words = words
            
            // If the search controller is not active,
            // present all words.
            // Otherwise, present the matched words.
            self.updateSearchResults(for: self.searchController)
        }
    }
    
    // MARK: - Controllers
    
    override var delegate: HomeViewController! {
        didSet {
            self.words = delegate.words
        }
    }
    
    // MARK: - Views
    
    lazy var translationButton: UIButton = {
        let button = UIButton()
        button.setImage(
            Icons.googleTranslateIcon.scaledToListIconSize(),
            for: .normal
        )
        button.addTarget(
            self,
            action: #selector(self.textFieldTranslateButtonTapped),
            for: .touchUpInside
        )
        return button
    }()
    lazy var translationSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    override func updateSetups() {
        super.updateSetups()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WordsTableCell.self, forCellReuseIdentifier: WordsViewController.cellIdentifier)
        tableView.register(TableHeaderView.self, forHeaderFooterViewReuseIdentifier: WordsViewController.headerIdentifier)
        
        searchController.searchResultsUpdater = self
        
        dataSource = words.grouped()
    }
    
    override func updateViews() {
        super.updateViews()
        
        navigationItem.title = Strings.phrases
    }
}

extension WordsViewController: UITableViewDataSource {
    
    // MARK: - UITableView Data Source

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].words.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: WordsViewController.cellIdentifier,
            for: indexPath
        ) as? WordsTableCell else {
            return UITableViewCell()
        }
        
        let word = dataSource[indexPath.section].words[indexPath.row]
        cell.updateValues(word: word)
        
        return cell
    }
}

extension WordsViewController: UITableViewDelegate {
    
    // MARK: - UITableView Delegate
 
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = TableHeaderView()
        headerView.updateValues(text: dataSource[section].groupId)
        return headerView
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        // https://www.hackingwithswift.com/example-code/uikit/how-to-swipe-to-delete-uitableviewcells
        if editingStyle == .delete {
            if let cell = tableView.cellForRow(at: indexPath) as? WordsTableCell {                
                words.removeWord(of: cell.word.id)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? WordsTableCell {
            presentWordEditingAlert(for: cell.word)
        }
    }
}

extension WordsViewController {
    
    // MARK: - Alerts
    
    private func presentWordEditingAlert(for word: Word? = nil) {
        
        // https://www.zerotoappstore.com/build-an-alert-dialog-box-with-text-input-in-swift.html
        
        let alert = UIAlertController(title: Strings.addingNewWordAlertTitle, message: nil, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.autocorrectionType = .yes
            if let word = word, !word.text.isEmpty {
                textField.text = word.text
            } else {
                textField.placeholder = "\(Strings.addingNewWordAlertTextFieldPlaceholderForText)/\(Strings.addingNewWordAlertTextFieldPlaceHolderForMeaning)"
            }
        }
        alert.addTextField { (textField) in
            textField.autocorrectionType = .yes
            if let word = word, !word.meaning.isEmpty {
                textField.text = word.meaning
            } else {
                textField.placeholder = "\(Strings.addingNewWordAlertTextFieldPlaceHolderForMeaning)/\(Strings.addingNewWordAlertTextFieldPlaceholderForText)"
            }

            // Add a translation button.
            textField.rightView = self.translationButton
            textField.rightViewMode = .always
        }

        alert.addAction(UIAlertAction(title: Strings.done, style: .default, handler: { [weak alert] (_) in
            
            var text: String = ""
            var meaning: String = ""
            if self.isText2Meaning == nil {
                self.isText2Meaning = true
            }
            if let textField = alert?.textFields?[0], let textFieldInput = textField.text {
                if self.isText2Meaning {
                    text = textFieldInput
                } else {
                    meaning = textFieldInput
                }
            }
            if let textField = alert?.textFields?[1], let textFieldInput = textField.text {
                if self.isText2Meaning {
                    meaning = textFieldInput
                } else {
                    text = textFieldInput
                }
            }
            
            let updatedWord: Word!
            if let word = word {
                let _ = self.words.updateWord(of: word.id, newText: text, newMeaning: meaning)
                updatedWord = self.words.getWord(from: word.id)  // TODO: - Speed up.
            } else {
                let newWord = Word(text: text, meaning: meaning)
                let _ = self.words.add(newWord: newWord)
                updatedWord = newWord
            }
            analyzeAccents(for: updatedWord.text) { tokens in
                guard !tokens.isEmpty else {
                    return
                }
                let _ = self.words.updateWord(of: updatedWord.id, newTokens: tokens)
            }
            
            self.clearTranslations()
            self.lastAlertController = nil
        }))
        alert.addAction(UIAlertAction(title: Strings.cancel, style: .cancel, handler: { (_) in
            self.clearTranslations()
            self.lastAlertController = nil
        }))

        self.present(alert, animated: true) {
            self.lastAlertController = alert
        }
    }
    
}

extension WordsViewController {
    
    // MARK: - Selectors
    
    @objc override func addButtonTapped() {
        presentWordEditingAlert()
    }
    
    @objc func textFieldTranslateButtonTapped() -> Void {
        
        guard let firstTextFieldText = wordAddingFirstTextField?.text else {
            return
        }
        // The word to translate should not be empty.
        guard !firstTextFieldText.strip().isEmpty else {
            return
        }
        
        if self.translations.isEmpty || firstTextFieldText != lastlyTypedWord {
            
            clearTranslations()
            
            lastlyTypedWord = firstTextFieldText
    
            // Language detection.
            var srcLang: LangCode
            var trgLang: LangCode
            let firstTextFieldTextLanguage = LangCode(detectedFrom: firstTextFieldText)
            if firstTextFieldTextLanguage == LangCode.currentLanguage
                || firstTextFieldTextLanguage == .undetermined {
                isText2Meaning = true
                srcLang = LangCode.currentLanguage
                trgLang = LangCode.currentLanguage.configs.languageForTranslation
            } else {
                isText2Meaning = false
                srcLang = firstTextFieldTextLanguage
                trgLang = LangCode.currentLanguage
            }
            // Make a translator.
            let translator = MachineTranslator(
                srcLang: srcLang,
                trgLang: trgLang
            )
            // Translation.
            isTranslating = true
            translator.translate(query: firstTextFieldText) { (translations, _) in
                guard !translations.isEmpty else {
                    // The didSet of isTranslating
                    // contains code for updating views,
                    // which requires to be performed in
                    // the main thread.
                    DispatchQueue.main.async {
                        self.isTranslating = false
                    }
                    return
                }
                self.translations = translations
                // Concat all translations as an additional translation.
                self.translations.append(translations.joined(separator: "; "))
                DispatchQueue.main.async {
                    self.isTranslating = false
                    if self.translationIndex < self.translations.count {
                        self.wordAddingSecondTextField?.text = self.translations[self.translationIndex]
                    }
                }
            }
        } else {
            self.translationIndex += 1
            if !translations.isEmpty {
                self.wordAddingSecondTextField?.text = self.translations[self.translationIndex]
            }
        }
        
    }
}

extension WordsViewController {
    
    // MARK: - Utils
    
    private func clearTranslations() {
        self.translations = []
        self.translationIndex = 0
        self.isTranslating = false
        self.lastlyTypedWord = ""
        self.isText2Meaning = nil
    }

}

extension WordsViewController: UISearchResultsUpdating {
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let keyWord = searchController.searchBar.text else {
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.dataSource = self.words.subset(containing: keyWord).grouped()
        }
    }
}

extension WordsViewController {
    
    // MARK: - Constants
    
    private static let headerIdentifier: String = Identifiers.tableHeaderViewIdentifier
    private static let cellIdentifier: String = Identifiers.wordsTableCellIdentifier
}
