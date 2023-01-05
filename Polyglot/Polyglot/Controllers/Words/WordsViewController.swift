//
//  WordsViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

struct GroupedWords {
    
    // For storing words grouped by group identifiers.
    var groupId: String
    var words: [Word]
    
    init(groupId: String, words: [Word]) {
        self.groupId = groupId
        self.words = words
    }
    
    init(groupId: String) {
        self.init(groupId: groupId, words: [])
    }
    
    static func group(_ allWords: [Word]) -> [GroupedWords] {
        var groupedWordsMapping: [String: GroupedWords] = [:]
        for word in allWords {
            let groupId = word.groupId
            
            groupedWordsMapping.setDefault(value: GroupedWords(groupId: groupId), for: groupId)
            groupedWordsMapping[groupId]?.words.append(word)
        }
        
        var groupedWords = Array<GroupedWords>(groupedWordsMapping.values)
        groupedWords.sort { (item1, item2) -> Bool in
            item1.words[0].cDate != item2.words[0].cDate
            ? item1.words[0].cDate > item2.words[0].cDate  // First, sort by date.
            : item1.groupId < item2.groupId  // Then, sort by groupId.
        }
        return groupedWords
    }
}

class WordsViewController: ListViewController {
        
    // TODO: - Don't make it a computed property. Too time-consuming.
    private var groupedWords: [GroupedWords] {
        return GroupedWords.group(words)
    }
    
    private var dataSource: [GroupedWords]! {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: - Models
    
    private var words: [Word] = Word.load() {
        didSet {
            Word.save(&words)
                        
            dataSource = groupedWords
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
        tableView.register(WordsTableHeaderView.self, forHeaderFooterViewReuseIdentifier: WordsViewController.headerIdentifier)
        
        searchController.searchResultsUpdater = self
        
        practiceButtonShadowView.delegate = self
        
        dataSource = groupedWords
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
}

extension WordsViewController {
    
    // MARK: - Selectors
    
    @objc override func addButtonTapped() {
        
        let wordsEditViewController = WordsEditViewController()
        wordsEditViewController.delegate = self
        wordsEditViewController.updateValues()
        
        let navController = NavController(rootViewController: wordsEditViewController)
        navigationController?.present(navController, animated: true, completion: nil)
        
    }
}

extension WordsViewController: UISearchResultsUpdating {
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let keyWord = searchController.searchBar.text else {
            return
        }
        dataSource = [GroupedWords(groupId: "", words: words.subset(containing: keyWord))]
    }
}

extension WordsViewController: RoundShadowViewDelegate {
    
    // MARK: - RoundShadowView Delegate

    @objc func tapped() {

        let wordsPracticeViewController = WordsPracticeViewController()
        wordsPracticeViewController.delegate = self
        wordsPracticeViewController.updateValues(words: words)

        let wordsPracticeNavController = NavController(rootViewController: wordsPracticeViewController)
        navigationController?.present(wordsPracticeNavController, animated: true, completion: nil)
    }

}

extension WordsViewController: WordsEditViewControllerDelegate {
    
    // MARK: - WordsEditViewController Delegate
    
    func add(words: [Word]) {
        self.words.add(newWords: words)
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
