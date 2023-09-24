//
//  WordsViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class WordsViewController: ListViewController {
    
    private var translator: GoogleTranslator = GoogleTranslator(
        srcLang: Variables.lang,
        trgLang: Variables.pairedLang
    )
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
                wordAddingMeaningTextField?.isEnabled = false  // Disable editing.
                wordAddingMeaningTextField?.rightView = translationSpinner
                translationSpinner.startAnimating()
            } else {
                wordAddingMeaningTextField?.isEnabled = true  // Enable editing.
                translationSpinner.stopAnimating()
                wordAddingMeaningTextField?.rightView = translationButton
            }
        }
    }
    private var wordAddingWordTextField: UITextField? {
        if let presentedViewController = self.presentedViewController {
            if let alertController = presentedViewController as? UIAlertController {
                return alertController.textFields?[0]
            }
        }
        return nil
    }
    
    private var wordAddingMeaningTextField: UITextField? {
        if let presentedViewController = self.presentedViewController {
            if let alertController = presentedViewController as? UIAlertController {
                return alertController.textFields?[1]
            }
        }
        return nil
    }
    private var lastlyTypedWord: String = ""
    
    private var dataSource: [GroupedWords]! {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: - Models
    
    var words: [Word] {
        get {
            return delegate.words
        }
        set {
            delegate.words = newValue
            
            // If the search controller is not active,
            // present all words.
            // Otherwise, present the matched words.
            updateSearchResults(for: searchController)
        }
    }
    
    // MARK: - Controllers
    
    var delegate: MenuViewController!
    
    // MARK: - Views
    
    lazy var translationButton: UIButton = {
        let button = UIButton()
        button.setImage(
            Icons.translateIcon.withTintColor(.lightGray),
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
        
        practiceButtonShadowView.button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        
        dataSource = words.grouped()
    }
    
    override func updateViews() {
        super.updateViews()
        
        navigationItem.title = Strings.wordListNavItemTitle
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
                textField.placeholder = Strings.addingNewWordAlertTextFieldPlaceholderForText
            }
        }
        alert.addTextField { (textField) in
            textField.autocorrectionType = .yes
            if let word = word, !word.meaning.isEmpty {
                textField.text = word.meaning
            } else {
                textField.placeholder = Strings.addingNewWordAlertTextFieldPlaceHolderForMeaning
            }

            // Add a translation button.
            textField.rightView = self.translationButton
            textField.rightViewMode = .always
        }
//        alert.addTextField { (textField) in
//            if let word = word, let note = word.note, !note.isEmpty {
//                textField.text = word.note
//            } else {
//                textField.placeholder = Strings.addingNewWordAlertTextFieldPlaceHolderForNote
//            }
//        }

        alert.addAction(UIAlertAction(title: Strings.done, style: .default, handler: { [weak alert] (_) in
            
            var text: String = ""
            var meaning: String = ""
            var note: String?
            if let textField = alert?.textFields?[0], let textFieldInput = textField.text {
                text = textFieldInput
            }
            if let textField = alert?.textFields?[1], let textFieldInput = textField.text {
                meaning = textFieldInput
            }
//            if let textField = alert?.textFields?[2] {
//                note = textField.text
//            }
            
            let updatedWord: Word!
            if let word = word {
                self.words.updateWord(of: word.id, newText: text, newMeaning: meaning, newNote: note)
                updatedWord = self.words.getWord(from: word.id)  // TODO: - Speed up.
            } else {
                let newWord = Word(text: text, meaning: meaning, note: note)
                self.words.add(newWord: newWord)
                updatedWord = newWord
            }
            
            if Variables.lang == LangCode.ja {
                Word.makeJaTokensFor(jaWord: updatedWord) { tokens in
                    DispatchQueue.main.async {
                        self.words.updateWord(of: updatedWord.id, newTokens: tokens)
                    }
                }
            }
            if Variables.lang == LangCode.ru {
                Word.makeRuTokensFor(ruWord: updatedWord) { tokens in
                    DispatchQueue.main.async {
                        self.words.updateWord(of: updatedWord.id, newTokens: tokens)
                    }
                }
            }
            
            self.clearTranslations()
        }))
        alert.addAction(UIAlertAction(title: Strings.cancel, style: .cancel, handler: { (_) in
            self.clearTranslations()
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
}

extension WordsViewController {
    
    // MARK: - Selectors
    
    @objc override func addButtonTapped() {
        presentWordEditingAlert()
    }
    
    @objc func tapped() {
        let wordsPracticeViewController = WordsPracticeViewController()
        wordsPracticeViewController.delegate = delegate

        let wordsPracticeNavController = NavController(rootViewController: wordsPracticeViewController)
        navigationController?.present(wordsPracticeNavController, animated: true, completion: nil)
    }
    
    @objc func textFieldTranslateButtonTapped() -> Void {
        
        guard let word = wordAddingWordTextField?.text else {
            return
        }
        // The word to translate should not be empty.
        guard !word.strip().isEmpty else {
            return
        }
        
        if self.translations.isEmpty || word != lastlyTypedWord {
            
            lastlyTypedWord = word
            
            isTranslating = true
            self.translator.translate(query: word) { (translations) in
                self.translations = translations
                // Concat all translations as an additional translation.
                self.translations.append(translations.joined(separator: "; "))
                DispatchQueue.main.async {
                    self.isTranslating = false
                    if !translations.isEmpty {
                        self.wordAddingMeaningTextField?.text = translations[self.translationIndex]
                    }
                }
            }
        } else {
            self.translationIndex += 1
            if !translations.isEmpty {
                self.wordAddingMeaningTextField?.text = self.translations[self.translationIndex]
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
    }
    
}

extension WordsViewController: UISearchResultsUpdating {
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let keyWord = searchController.searchBar.text else {
            return
        }
        dataSource = words.subset(containing: keyWord).grouped()
    }
}

extension WordsViewController {
    
    // MARK: - Constants
    
    private static let headerIdentifier: String = Identifiers.tableHeaderViewIdentifier
    private static let cellIdentifier: String = Identifiers.wordsTableCellIdentifier
}
