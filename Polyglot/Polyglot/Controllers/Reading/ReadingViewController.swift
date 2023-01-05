//
//  ReadingViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/21.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class ReadingViewController: ListViewController {
    
    private var dataSource: [Article]! {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: - Models
    
    private var articles: [Article] = Article.load() {
        didSet {
            Article.save(&articles)
            
            dataSource = articles
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
        tableView.register(ReadingTableCell.self, forCellReuseIdentifier: ReadingViewController.cellIdentifier)

        searchController.searchResultsUpdater = self
        
        practiceButtonShadowView.delegate = self
        
        dataSource = articles
    }
    
    func updateValues() {
        
    }
}

extension ReadingViewController: UITableViewDataSource {
    
    // MARK: - UITableView Data Source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ReadingViewController.cellIdentifier,
            for: indexPath
        ) as? ReadingTableCell else {
            return UITableViewCell()
        }
        
        let article = dataSource[indexPath.row]
        cell.updateValues(article: article)
        
        return cell
    }

}

extension ReadingViewController: UITableViewDelegate {
    
    // MARK: - UITableView Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let readingEditViewController = ReadingEditViewController()
        readingEditViewController.delegate = self
        readingEditViewController.updateValues(article: articles[indexPath.row])
        
        let readingEditNavController = NavController(rootViewController: readingEditViewController)
        navigationController?.present(readingEditNavController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            
        // https://www.hackingwithswift.com/example-code/uikit/how-to-swipe-to-delete-uitableviewcells
        if editingStyle == .delete {
            if let cell = tableView.cellForRow(at: indexPath) as? ReadingTableCell {
                articles.removeArticle(of: cell.article.id)
            }
        }
    }
}

extension ReadingViewController {
    
    // MARK: - Selectors
    
    @objc override func addButtonTapped() {
        let readingEditViewController = ReadingEditViewController()
        readingEditViewController.delegate = self
        
        let readingEditNavController = NavController(rootViewController: readingEditViewController)
        navigationController?.present(readingEditNavController, animated: true, completion: nil)
        
    }
}

extension ReadingViewController: RoundShadowViewDelegate {
    
    // MARK: - RoundShadowView Delegate
    
    @objc func tapped() {
        let readingPracticeViewController = ReadingPracticeViewController()
        readingPracticeViewController.delegate = self
        readingPracticeViewController.updateValues(articles: articles)
        
        let readingPracticeNavController = NavController(rootViewController: readingPracticeViewController)
        navigationController?.present(readingPracticeNavController, animated: true, completion: nil)
    }
    
}

extension ReadingViewController: ReadingEditViewControllerDelegate {
    
    // MARK: - ReadingEditViewController Delegate
    
    func add(article: Article) {
        articles.add(newArticle: article)
    }
    
    func edit(articleId: Int, newTitle: String, newBody: String, newSource: String) {
        articles.updateArticle(of: articleId, newTitle: newTitle, newBody: newBody, newSource: newSource)
    }
}

extension ReadingViewController: UISearchResultsUpdating {
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let keyWord = searchController.searchBar.text else {
            return
        }
        dataSource = articles.subset(containing: keyWord)
    }
    
}

extension ReadingViewController {
    
    // MARK: - Constants
    
    private static let cellIdentifier: String = Identifiers.readingTableCellIdentifier
}
