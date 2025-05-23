//
//  ReadingViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/21.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class ReadingViewController: ListViewController {
    
    private var dataSource: [GroupedArticles]! {
        didSet {
            DispatchQueue.main.async {  // Update the table in the main thread.
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Models
    
    var articles: [Article]! {
        didSet {
            delegate.articles = articles
            
            // If the search controller is not active,
            // present all articles.
            // Otherwise, present the matched articles.
            updateSearchResults(for: searchController)
        }
    }
    
    // MARK: - Controllers
    
    override var delegate: HomeViewController! {
        didSet {
            self.articles = delegate.articles
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
        
        dataSource = articles.groups
    }
    
    override func updateViews() {
        super.updateViews()
        
        navigationItem.title = Strings.articles
    }
}

extension ReadingViewController: UITableViewDataSource {
    
    // MARK: - UITableView Data Source

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].articles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ReadingViewController.cellIdentifier,
            for: indexPath
        ) as? ReadingTableCell else {
            return UITableViewCell()
        }
        
        let article = dataSource[indexPath.section].articles[indexPath.row]
        cell.updateValues(article: article)
        
        return cell
    }

}

extension ReadingViewController: UITableViewDelegate {
    
    // MARK: - UITableView Delegate
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = TableHeaderView()
        
        let topic = dataSource[section].groupId
        let nArticles = dataSource[section].articles.count
        headerView.updateValues(text: "\(topic) (\(nArticles))")
        return headerView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let query = searchController.searchBar.text
        
        if let cell = tableView.cellForRow(at: indexPath) as? ReadingTableCell {
            let readingEditViewController = ReadingEditViewController()
            readingEditViewController.delegate = self
            readingEditViewController.updateValues(article: cell.article, query: query)
            
            let readingEditNavController = NavController(rootViewController: readingEditViewController)
            navigationController?.present(readingEditNavController, animated: true, completion: nil)
        }
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

extension ReadingViewController: ReadingEditViewControllerDelegate {
    
    // MARK: - ReadingEditViewController Delegate
    
    func add(article: Article) {
        articles.add(newArticle: article)
    }
    
    func edit(articleId: String, newTitle: String, newTopic: String, newBody: String, newSource: String) {
        articles.updateArticle(of: articleId, newTitle: newTitle, newTopic: newTopic, newBody: newBody, newSource: newSource)
    }
    
    func edit(articleId: String, newTitle: String, newTopic: String, newCaptionEvents: [YoutubeVideoParser.CaptionEvent], newSource: String) {
        articles.updateArticle(of: articleId, newTitle: newTitle, newTopic: newTopic, newCaptionEvents: newCaptionEvents, newSource: newSource)
    }
    
}

extension ReadingViewController: UISearchResultsUpdating {
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let keyWord = searchController.searchBar.text else {
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {  // Slow.
            self.dataSource = self.articles.subset(containing: keyWord).groups
        }
    }
    
}

extension ReadingViewController {
    
    // MARK: - Constants
    
    private static let headerIdentifier: String = Identifiers.tableHeaderViewIdentifier
    private static let cellIdentifier: String = Identifiers.readingTableCellIdentifier
}
