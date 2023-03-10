//
//  WordsViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class WordsViewController: ListViewController {
    
    private var dataSource: [GroupedWords]! {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: - Models
    
    private var words: [Word] = Word.load() {
        didSet {
            Word.save(&words)

            // If the search controller is not active,
            // present all words.
            // Otherwise, present the matched words.
            updateSearchResults(for: searchController)
        }
    }
    
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
        
        // Reset a right button item being able to
        // handle tapping and long pressing.
        // https://stackoverflow.com/questions/60596312/how-to-detect-longpress-in-barbuttonitem
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: {
            let button = UIButton()
            button.setImage(Icons.addIcon, for: .normal)
            
            button.addGestureRecognizer(UITapGestureRecognizer(
                target: self,
                action: #selector(addButtonTapped)
            ))
            button.addGestureRecognizer(UILongPressGestureRecognizer(
                target: self,
                action: #selector(addButtonLongPressed)
            ))
            return button
        }())
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
        }
        alert.addTextField { (textField) in
            if let word = word, let note = word.note, !note.isEmpty {
                textField.text = word.note
            } else {
                textField.placeholder = Strings.addingNewWordAlertTextFieldPlaceHolderForNote
            }
        }

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
            if let textField = alert?.textFields?[2] {
                note = textField.text
            }
            
            if let word = word {
                self.words.updateWord(of: word.id, newText: text, newMeaning: meaning, newNote: note)
            } else {
                self.words.add(newWord: Word(text: text, meaning: meaning, note: note))
            }
        }))
        alert.addAction(UIAlertAction(title: Strings.cancel, style: .cancel, handler: { (_) in
            return
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
}

extension WordsViewController {
    
    // MARK: - Selectors
    
    @objc override func addButtonTapped() {
        presentWordEditingAlert()
    }
    
    @objc func addButtonLongPressed() {
        let wordsEditViewController = WordsEditViewController()
        wordsEditViewController.delegate = self
        wordsEditViewController.updateValues()
        
        let navController = NavController(rootViewController: wordsEditViewController)
        navigationController?.present(navController, animated: true, completion: nil)
    }
    
    @objc func tapped() {
        let wordsPracticeViewController = WordsPracticeViewController()
        wordsPracticeViewController.updateValues(words: words)

        let wordsPracticeNavController = NavController(rootViewController: wordsPracticeViewController)
        navigationController?.present(wordsPracticeNavController, animated: true, completion: nil)
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

extension WordsViewController: WordsEditViewControllerDelegate {
    
    // MARK: - WordsEditViewController Delegate
    
    func add(words: [Word]) {
        self.words.add(newWords: words)
    }
}

extension WordsViewController {
    
    // MARK: - Constants
    
    private static let headerIdentifier: String = Identifiers.tableHeaderViewIdentifier
    private static let cellIdentifier: String = Identifiers.wordsTableCellIdentifier
}
