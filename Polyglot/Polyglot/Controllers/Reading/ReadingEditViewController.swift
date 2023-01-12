//
//  ReadingEditViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/21.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class ReadingEditViewController: UITableViewController {
    
    private lazy var cells: [ReadingEditTableCell] = [
        self.cell(for: ReadingEditViewController.titleIdentifier),
        self.cell(for: ReadingEditViewController.bodyIdentifier),
        self.cell(for: ReadingEditViewController.sourceIdentifier)
    ]
    
    // MARK: - Models
    
    private var article: Article?
    
    // MARK: - Controllers
    
    var delegate: ReadingViewController!
    
    // MARK: - Init
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Due to the hidden nav bar separator,
        // table content will be displayed under the status bar.
        // Assigning a bg color for the status bar
        // can solve the problem.
        UIApplication.shared.statusBarUIView?.backgroundColor = Colors.defaultBackgroundColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Reset the bg color.
        UIApplication.shared.statusBarUIView?.backgroundColor = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSetups()
        updateViews()
        updateLayouts()
    }

    private func updateSetups() {
        tableView.register(ReadingEditTableCell.self, forCellReuseIdentifier: ReadingEditViewController.cellIdentifier)
    }
    
    private func updateViews() {
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
        
        tableView.separatorStyle = .none
    }
    
    private func updateLayouts() {
        
    }
    
    func updateValues(article: Article) {
        self.article = article
    }
}
 
extension ReadingEditViewController {
    
    // MARK: - UITableView Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: - Increase the height of body text view.
        // TODO: - Prohibit to select the prompt.
        
        return cells[indexPath.row]
    }

}
 
extension ReadingEditViewController {
    
    // MARK: - Utils
    
    private func cell(for identifier: Int) -> ReadingEditTableCell {
        let cell = ReadingEditTableCell()
        cell.delegate = self
        
        let prompt = getPrompt(for: identifier)  // Dynamically loading instead of using constants, coz `lang` will change.
        let text = getText(for: identifier)
        let attributes = ReadingEditViewController.attributes[identifier]
        
        cell.updateValues(prompt: prompt, text: text, attributes: attributes, textViewTag: identifier)
        return cell
    }
    
    private func getPrompt(for identifier: Int) -> String {
        switch identifier {
        case ReadingEditViewController.titleIdentifier: return Strings.articleTitlePrompt
        case ReadingEditViewController.bodyIdentifier: return Strings.articleBodyPrompt
        case ReadingEditViewController.sourceIdentifier: return Strings.articleSourcePrompt
        default: return ""
        }
    }
    
    private func getText(for identifier: Int) -> String? {
        guard let article = article else {
            return ""
        }
        switch identifier {
        case ReadingEditViewController.titleIdentifier: return article.title
        case ReadingEditViewController.bodyIdentifier: return article.body
        case ReadingEditViewController.sourceIdentifier: return article.source
        default: return ""
        }
    }
    
    private var content: [String : String] {
        return [
            "title": cells[ReadingEditViewController.titleIdentifier].textView.content,
            "body": cells[ReadingEditViewController.bodyIdentifier].textView.content,
            "source": cells[ReadingEditViewController.sourceIdentifier].textView.content
        
        ]
    }
}

extension ReadingEditViewController {
    
    // MARK: - Selectors
    
    @objc private func cancelButtonTapped() {
        
        let oldTitle: String!
        let oldBody: String!
        let oldSource: String!
        if let article = article {
            oldTitle = article.title
            oldBody = article.body
            oldSource = article.source
        } else {
            oldTitle = ""
            oldBody = ""
            oldSource = ""
        }
        
        if oldTitle != content["title"]!
            || oldBody != content["body"]!
            || oldSource != content["source"]! {
            // Edits have been made.
            presentExitWithoutSavingAlert(viewController: self) { (isOk) in
                if isOk {
                    self.navigationController?.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            // No edits made.
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func doneButtonTapped() {

        // TODO: - Ensure that the article body is not empty.
        
        if let article = article {
            // Edit an existing article.
            delegate.edit(
                articleId: article.id,
                newTitle: content["title"]!,
                newBody: content["body"]!,
                newSource: content["source"]!
            )
        } else {
            // Add a new article.
            let newArticle = Article(
                title: content["title"]!,
                body: content["body"]!,
                source: content["source"]!
            )
            delegate.add(article: newArticle)
        }
        
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension ReadingEditViewController {
    
    // MARK: - Constants
    
    private static let cellIdentifier: String = Identifiers.readingEditTableCellIdentifier
    
    private static let titleIdentifier: Int = 0
    private static let bodyIdentifier: Int = 1
    private static let sourceIdentifier: Int = 2
    private static let attributes: [[NSAttributedString.Key : Any]] = [
        Attributes.newArticleTitleAttributes,
        Attributes.newArticleBodyAttributes,
        Attributes.newArticleSourceAttributes
    ]
    
}

protocol ReadingEditViewControllerDelegate {
    
    func add(article: Article)
    func edit(articleId: Int, newTitle: String, newBody: String, newSource: String)
    
}
