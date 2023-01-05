//
//  ReadingViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/21.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class ReadingViewController: UIViewController {
    
    private var dataSource: [Article]! {
        didSet {
            // Reload table data.
            tableView.reloadData()
        }
    }
    
    // MARK: - Models
    
    private var articles: [Article] = Article.load() {
        didSet {
            Article.save(&articles)
            
            // Also update the data source.
            dataSource = articles
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
        tableView.register(ReadingTableCell.self, forCellReuseIdentifier: ReadingViewController.cellIdentifier)

        searchController.searchResultsUpdater = self
        practiceButtonShadowView.button.delegate = self
        
        // The initial data source is the articles.
        dataSource = articles
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
        
        let readingEditNavController = DefaultNavController(rootViewController: readingEditViewController)
        navigationController?.present(readingEditNavController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            
        // https://www.hackingwithswift.com/example-code/uikit/how-to-swipe-to-delete-uitableviewcells
        
        if editingStyle == .delete {
            if let cell = tableView.cellForRow(at: indexPath) as? ReadingTableCell {
                
                let id = cell.article.id
                articles.removeArticle(of: id)
            }
        }
    }
}

extension ReadingViewController {
    
    // MARK: - Selectors
    
    @objc private func addButtonTapped() {
        
        let readingEditViewController = ReadingEditViewController()
        readingEditViewController.delegate = self
        
        let readingEditNavController = DefaultNavController(rootViewController: readingEditViewController)
        navigationController?.present(readingEditNavController, animated: true, completion: nil)
        
    }
}

extension ReadingViewController: RoundButtonDelegate {
    
    // MARK: - RoundShadowView Delegate
    
    @objc func tapped() {

        let readingPracticeViewController = ReadingPracticeViewController()
        readingPracticeViewController.delegate = self
        
        readingPracticeViewController.updateValues(articles: articles)
        
        let readingPracticeNavController = DefaultNavController(rootViewController: readingPracticeViewController)
        navigationController?.present(readingPracticeNavController, animated: true, completion: nil)
    }
    
}

extension ReadingViewController: ReadingEditViewControllerDelegate {
    
    func add(article: Article) {
        
        // TODO: - Wrap to Article.
        
        articles.append(article)
    }
    
    func edit(articleId: Int, newTitle: String, newBody: String, newSource: String) {
        
        // TODO: - Wrap to Article.
        
        for i in 0..<articles.count {
            if articles[i].id == articleId {
                articles[i].update(newTitle: newTitle, newBody: newBody, newSource: newSource)
            }
        }
    }
}

extension ReadingViewController: UISearchResultsUpdating {
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let keyWord = searchController.searchBar.text else {
            return
        }
        
        if keyWord == "" {
            // If no keyword is provided, load all the articles.
            dataSource = articles
        } else {
            // Obtain all articles containing the keyword.
            var matchedArticles: [Article] = []
            for article in articles {
                if article.query.contains(keyWord) {
                    matchedArticles.append(article)
                }
            }
            dataSource = matchedArticles
        }
    }
    
}

extension ReadingViewController {
    
    // MARK: - Constants
    
    private static let cellIdentifier: String = Identifiers.readingTableCellIdentifier
}
