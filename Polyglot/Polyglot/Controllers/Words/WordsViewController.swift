//
//  WordsViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class WordsViewController: UIViewController {
    
    struct GroupedWords {
        
        // For storing words grouped by group identifiers.
        
        var groupIdentifier: String
        var words: [Word]
    }
    
    // TODO: - Simplify here.
    // TODO: - Don't make it a computed property. Too time-consuming.
    // TODO: - Sort by date.
    private var groupedWords: [GroupedWords] {
        var groups: [String: [Word]] = [:]
        for word in words {
            let groupIdentifier = word.groupIdentifier
            if !groups.keys.contains(groupIdentifier) {
                groups[groupIdentifier] = []  // TODO: - Simplify here.
            }
            
            groups[groupIdentifier]?.append(word)
        }
        
        var groupedWords: [GroupedWords] = []
        for (groupIdentifier, words) in groups {
            groupedWords.append(GroupedWords(groupIdentifier: groupIdentifier, words: words))
        }
        groupedWords.sort { (item1, item2) -> Bool in  // TODO: - Update here.
            item1.words[0].creationDate != item2.words[0].creationDate
            ? item1.words[0].creationDate > item2.words[0].creationDate
            : item1.groupIdentifier < item2.groupIdentifier
        }
        return groupedWords
    }
    
    private var dataSource: [GroupedWords]! {
        didSet {
            // Reload table data.
            tableView.reloadData()
        }
    }
    
    // MARK: - Models
    
    private var words: [Word] = Word.load() {  // TODO: - load here?
        didSet {
            Word.save(&words)
                        
            // Also update the data source.
            dataSource = groupedWords
        }
    }
    
    // MARK: - Controllers
    
    private var searchController: UISearchController = {
        let searchController = UISearchController()
        searchController.obscuresBackgroundDuringPresentation = false
        return searchController
    }()
    
    // MARK: - Views
    
    private var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = Colors.defaultBackgroundColor
        return tableView
    }()
    
    private var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchTextField.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        return searchBar
    }()
    
    private var practiceButtonShadowView: RoundShadowView = {
        let roundShadowView = RoundShadowView()
        roundShadowView.button.setImage(
            Icons.practiceIcon,
            for: .normal
        )
        roundShadowView.button.backgroundColor = Colors.defaultBackgroundColor
        return roundShadowView
    }()
    
    private lazy var navigationBarAddButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        return button
    }()
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    private func updateSetups() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WordsTableCell.self, forCellReuseIdentifier: WordsViewController.cellIdentifier)
        tableView.register(WordsTableHeaderView.self, forHeaderFooterViewReuseIdentifier: WordsViewController.headerIdentifier)
        
        searchController.searchResultsUpdater = self
        practiceButtonShadowView.button.delegate = self
        
        // The initial data source is the grouped words.
        dataSource = groupedWords
    }
    
    private func updateViews() {
        view.backgroundColor = Colors.defaultBackgroundColor
        
        navigationItem.rightBarButtonItem = navigationBarAddButton
        navigationItem.searchController = searchController
        
        view.addSubview(tableView)
        tableView.removeRedundantSeparators()
        
        view.addSubview(practiceButtonShadowView)
    }
    
    private func updateLayouts() {
        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(navigationController!.navigationBar.frame.height + searchController.searchBar.frame.height)
            make.bottom.equalToSuperview()
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        practiceButtonShadowView.snp.makeConstraints { (make) in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(10)
        }
    }
    
    func updateValues() {
        
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
        
        cell.delegate = self
        let word = dataSource[indexPath.section].words[indexPath.row]
        cell.updateValues(word: word)
        
        return cell
    }
}

extension WordsViewController: UITableViewDelegate {
    
    // MARK: - UITableView Delegate
 
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = WordsTableHeaderView()
        headerView.updateValues(text: dataSource[section].groupIdentifier)
        return headerView
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        // https://www.hackingwithswift.com/example-code/uikit/how-to-swipe-to-delete-uitableviewcells
        
        if editingStyle == .delete {
            if let cell = tableView.cellForRow(at: indexPath) as? WordsTableCell {
//                tableView.deleteRows(at: [indexPath], with: .fade)
                
                let id = cell.word.id
                words.removeWord(of: id)
            }
        }
    }
}

extension WordsViewController {
    
    // MARK: - Selectors
    
    @objc private func addButtonTapped() {
        
        let wordsEditViewController = WordsEditViewController()
        wordsEditViewController.delegate = self
        wordsEditViewController.updateValues()
        
        let navController = DefaultNavController(rootViewController: wordsEditViewController)
        navigationController?.present(navController, animated: true, completion: nil)
        
    }
}

extension WordsViewController: UISearchResultsUpdating {
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let keyWord = searchController.searchBar.text else {
            return
        }
        
        if keyWord == "" {
            // If no keyword is provided, load all the words.
            dataSource = groupedWords
        } else {
            // Obtain all words containing the keyword.
            var matchedWords: [Word] = []  // TODO: - Store word ids instead.
            for word in words {
                if word.query.contains(keyWord) {
                    matchedWords.append(word)
                }
            }
            dataSource = [GroupedWords(groupIdentifier: "", words: matchedWords)]
        }
    }
}

extension WordsViewController: RoundButtonDelegate {
    
    // MARK: - RoundShadowView Delegate

    @objc func tapped() {

        let wordsPracticeViewController = WordsPracticeViewController()
        wordsPracticeViewController.delegate = self
        wordsPracticeViewController.updateValues(words: words)

        let wordsPracticeNavController = DefaultNavController(rootViewController: wordsPracticeViewController)
        navigationController?.present(wordsPracticeNavController, animated: true, completion: nil)
    }

}

extension WordsViewController: WordsEditViewControllerDelegate {
    
    // MARK: - WordsEditViewController Delegate
    
    func add(words: [Word]) {
        self.words.append(contentsOf: words)
    }
}

extension WordsViewController: WordsTableCellDelegate {
    
    // MARK: - WordsTableCell Delegate
    
    func updateWord(of id: Int, newText: String, newMeaning: String) {
        
        words.updateWord(of: id, newText: newText, newMeaning: newMeaning)
        
    }
    
    
}

extension WordsViewController {
    
    // MARK: - Constants
    
    private static let cellIdentifier: String = Identifiers.wordsTableCellIdentifier
    static let headerIdentifier: String = Identifiers.wordsTableHeaderViewIdentifier  // TODO: - change to private later.
}
