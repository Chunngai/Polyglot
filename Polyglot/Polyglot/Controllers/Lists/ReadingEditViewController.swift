//
//  ReadingEditViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/21.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift

class ReadingEditViewController: UIViewController {
    
    private lazy var cells: [ReadingEditTableCell] = [
        self.cell(for: ReadingEditViewController.titleIdentifier),
        self.cell(for: ReadingEditViewController.topicIdentifier),
        self.cell(for: ReadingEditViewController.sourceIdentifier),
        self.cell(for: ReadingEditViewController.paraSplitingIdentifier),
        self.cell(for: ReadingEditViewController.bodyIdentifier)
    ]
    
    var query: String?
    
    // MARK: - Models
    
    private var article: Article?
    
    // MARK: - Controllers
    
    var delegate: ReadingViewController!
    
    // MARK: - Views
    
    // Do not use a table view controller.
    // The scrolling is weired when the keyboard pops up.
    var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = Colors.defaultBackgroundColor
        tableView.separatorStyle = .none
        tableView.removeRedundantSeparators()
        // https://stackoverflow.com/questions/4399357/hide-keyboard-when-scroll-uitableview
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()
    
    // MARK: - Init
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        IQKeyboardManager.shared.enableAutoToolbar = true
        
        navigationController?.navigationBar.hideBarSeparator()
        // Ensure that the status bar has a bg color in the modal presentation mode.
        UIApplication.shared.statusBarUIView?.backgroundColor = Colors.defaultBackgroundColor
        
        scrollToQuery()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        IQKeyboardManager.shared.enableAutoToolbar = false
        
        navigationController?.navigationBar.showBarSeparator()
        // Reset the status bar bg color.
        UIApplication.shared.statusBarUIView?.backgroundColor = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSetups()
        updateViews()
        updateLayouts()
    }

    private func updateSetups() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            ReadingEditTableCell.self,
            forCellReuseIdentifier: ReadingEditViewController.cellIdentifier
        )
    }
    
    private func updateViews() {
        // Ensure that the nav bar has a bg color in the modal presentation mode.
        navigationController?.navigationBar.isTranslucent = false  // If true, the nav bar is translucent when scrolling.
        navigationController?.navigationBar.backgroundColor = Colors.defaultBackgroundColor
        
        navigationItem.title = Strings.articleEditingTitle
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
        
        view.addSubview(tableView)
    }
    
    private func updateLayouts() {
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    func updateValues(article: Article, query: String?) {
        self.article = article
        self.query = query
    }
}
 
extension ReadingEditViewController: UITableViewDataSource {
    
    // MARK: - UITableView Data Source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 4
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = indexPath.section
        let row = indexPath.row
        
        if section == 0 {
            if row == 0 {
                return cells[ReadingEditViewController.titleIdentifier]
            } else if row == 1 {
                return cells[ReadingEditViewController.topicIdentifier]
            } else if row == 2 {
                return cells[ReadingEditViewController.sourceIdentifier]
            } else if row == 3 {
                return cells[ReadingEditViewController.paraSplitingIdentifier]
            }
        } else if section == 1 {
            return cells[ReadingEditViewController.bodyIdentifier]
        }
        
        fatalError("Not Implemented.")
    }

}

extension ReadingEditViewController: UITableViewDelegate {
    
    // MARK: - UITableView Delegate
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        20
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        0
    }
  
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // For hiding headers.
        UIView()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // For hiding footers.
        UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        guard indexPath.section == 1,
              cells[Self.bodyIdentifier].textView.content.isEmpty else {
            return UITableView.automaticDimension
        }
        
        // When the body is empty.
        return Self.cellHeights[Self.bodyIdentifier] ?? UITableView.automaticDimension
        
    }

}

extension ReadingEditViewController {
    
    // MARK: - Utils
    
    private func cell(for identifier: Int) -> ReadingEditTableCell {
        
        let cell = ReadingEditTableCell()
        cell.delegate = self
        
        let prompt = getPrompt(for: identifier)  // Dynamically loading instead of using constants, coz `lang` will change.
        let text = getText(for: identifier)
        let textAttributes = Self.textAttributes[identifier] ?? [:]
        let promptAttributes = Self.promptAttributes[identifier] ?? [:]
        
        cell.updateValues(
            prompt: prompt,
            text: text,
            promptAttributes: promptAttributes,
            textAttributes: textAttributes,
            textViewTag: identifier
        )
        
        if identifier == Self.paraSplitingIdentifier {
            cell.textView.isEditable = false
            cell.addGestureRecognizer(UITapGestureRecognizer(
                target: self,
                action: #selector(paraSplitingButtonTapped)
            ))
        }

        return cell
    }
    
    private func getPrompt(for identifier: Int) -> String {
        switch identifier {
        case ReadingEditViewController.titleIdentifier: return Strings.articleTitlePrompt
        case ReadingEditViewController.topicIdentifier: return Strings.articleTopicPrompt
        case ReadingEditViewController.sourceIdentifier: return Strings.articleSourcePrompt
        case ReadingEditViewController.paraSplitingIdentifier: return Strings.paraSplitingPrompt
        default: return ""
        }
    }
    
    private func getText(for identifier: Int) -> String? {
        guard let article = article else {
            return ""
        }
        switch identifier {
        case ReadingEditViewController.titleIdentifier: return article.title
        case ReadingEditViewController.topicIdentifier: return article.topic
        case ReadingEditViewController.sourceIdentifier: return article.source
        case ReadingEditViewController.bodyIdentifier: return article.body
        default: return ""
        }
    }
    
    private var content: [String : String] {
        return [
            "title": cells[ReadingEditViewController.titleIdentifier].textView.content,
            "topic": cells[ReadingEditViewController.topicIdentifier].textView.content,
            "source": cells[ReadingEditViewController.sourceIdentifier].textView.content,
            "body": cells[ReadingEditViewController.bodyIdentifier].textView.content
                // Handle Windows and Mac newline symbols.
                .replacingOccurrences(of: Strings.windowsNewLineSymbol, with: "\n")
                .replacingOccurrences(of: Strings.macNewLineSymbol, with: "\n"),
        ]
    }
}

extension ReadingEditViewController {
    
    func scrollToQuery(shouldIgnoreCaseAndAccent: Bool = true) {
        guard var query = query else {
            return
        }
        query = query.normalized(
            caseInsensitive: shouldIgnoreCaseAndAccent,
            diacriticInsensitive: shouldIgnoreCaseAndAccent
        )
        
        let bodyCellTextView = cells[ReadingEditViewController.bodyIdentifier].textView
        let text = bodyCellTextView.text.normalized(
            caseInsensitive: shouldIgnoreCaseAndAccent,
            diacriticInsensitive: shouldIgnoreCaseAndAccent
        )
        
        var matchedText = query
        do {
            let regex = try NSRegularExpression(
                pattern: query,
                options: .caseInsensitive
            )
            if let match = regex.firstMatch(
                in: text,
                options: [],
                range: NSRange(
                    location: 0,
                    length: text.utf16.count
                )
            ) {
                matchedText = (text as NSString).substring(with: match.range)
                print(matchedText)
            }
        } catch {
            
        }
        
        let queryRange = (text as NSString).range(of: matchedText)
        guard queryRange.location != NSNotFound else {
            return
        }
        
        // Highlighting.
        let attributedText = NSMutableAttributedString(attributedString: bodyCellTextView.attributedText)
        attributedText.setBackgroundColor(
            for: matchedText,
            with: Colors.lightBlue,
            ignoreCasing: shouldIgnoreCaseAndAccent,
            ignoreAccents: shouldIgnoreCaseAndAccent
        )
        bodyCellTextView.attributedText = attributedText
        
        // Scrolling.
        if var contentOffset = bodyCellTextView.contentOffset(for: queryRange) {
            contentOffset.y += cells[Self.bodyIdentifier].frame.minY  // Consider the cells above.
            
            var maxOffsetY: CGFloat? = bodyCellTextView.contentSize.height
            - tableView.bounds.height
            + cells[Self.bodyIdentifier].frame.minY
            + bodyCellTextView.textContainerInset.bottom
            if let maxOffsetY_ = maxOffsetY, maxOffsetY_ < 0 {
                maxOffsetY = nil
            }
            
            tableView.scrollTo(
                contentOffset: contentOffset,
                minOffsetY: 0,
                maxOffsetY: maxOffsetY,
                animated: true
            )
        }
        
    }
    
}

extension ReadingEditViewController {
    
    // MARK: - Selectors
    
    @objc private func cancelButtonTapped() {
        
        let oldTitle: String!
        let oldTopic: String!
        let oldSource: String!
        let oldBody: String!
        if let article = article {
            oldTitle = article.title
            oldTopic = article.topic
            oldSource = article.source
            oldBody = article.body
        } else {
            oldTitle = ""
            oldTopic = ""
            oldSource = ""
            oldBody = ""
        }
        
        if oldTitle != content["title"]!
            || oldTopic != content["topic"]!
            || oldSource != content["source"]!
            || oldBody != content["body"]! {
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
                newTopic: content["topic"]!,
                newBody: content["body"]!,
                newSource: content["source"]!
            )
        } else {
            // Add a new article.
            let newArticle = Article(
                title: content["title"]!,
                topic: content["topic"]!,
                body: content["body"]!,
                source: content["source"]!
            )
            delegate.add(article: newArticle)
        }
        
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc private func paraSplitingButtonTapped() {
        self.cells[ReadingEditViewController.bodyIdentifier].textView.text = self.content["body"]?
            .replacingOccurrences(
                of: "\n",
                with: "\n\n"
            )
            .replaceMultipleBlankLinesWithSingleLine()
    }
}

extension ReadingEditViewController {
    
    // MARK: - Constants
    
    private static let cellIdentifier: String = Identifiers.readingEditTableCellIdentifier
    
    private static let titleIdentifier: Int = 0
    private static let topicIdentifier: Int = 1
    private static let sourceIdentifier: Int = 2
    private static let paraSplitingIdentifier: Int = 3
    private static let bodyIdentifier: Int = 4
    
    private static let promptAttributesForText: [NSAttributedString.Key : Any] = {
        var attrs = Attributes.defaultLongTextAttributes(fontSize: Sizes.mediumFontSize)
        attrs[.foregroundColor] = Colors.weakTextColor
        return attrs
    }()
    private static let promptAttributesForButton: [NSAttributedString.Key : Any] = {
        var attrs = Attributes.defaultLongTextAttributes(fontSize: Sizes.mediumFontSize)
        attrs[.font] = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        attrs[.foregroundColor] = Colors.activeSystemButtonColor
        return attrs
    }()
    private static let promptAttributes: [Int: [NSAttributedString.Key : Any]] = [
        ReadingEditViewController.titleIdentifier: ReadingEditViewController.promptAttributesForText,
        ReadingEditViewController.topicIdentifier: ReadingEditViewController.promptAttributesForText,
        ReadingEditViewController.sourceIdentifier: ReadingEditViewController.promptAttributesForText,
        ReadingEditViewController.paraSplitingIdentifier: ReadingEditViewController.promptAttributesForButton,
    ]
    
    private static let textAttributes: [Int: [NSAttributedString.Key : Any]] = [
        ReadingEditViewController.titleIdentifier: {
            var attrs: [NSAttributedString.Key: Any] = Attributes.defaultLongTextAttributes(fontSize: Sizes.mediumFontSize)
            attrs[.font] = UIFont.systemFont(
                ofSize: Sizes.mediumFontSize,
                weight: .bold
            )
            return attrs
        }(),
        ReadingEditViewController.topicIdentifier: Attributes.defaultLongTextAttributes(fontSize: Sizes.mediumFontSize),
        ReadingEditViewController.sourceIdentifier: Attributes.defaultLongTextAttributes(fontSize: Sizes.mediumFontSize),
        ReadingEditViewController.bodyIdentifier: {
            var attrs: [NSAttributedString.Key: Any] = Attributes.defaultLongTextAttributes(fontSize: Sizes.mediumFontSize)
            attrs[.paragraphStyle] = {
                let paraStyle = Attributes.defaultParaStyle(fontSize: Sizes.mediumFontSize)
                paraStyle.paragraphSpacing = 0
                return paraStyle
            }()
            return attrs
        }(),
    ]
    private static let cellHeights: [Int: CGFloat] = [
        ReadingEditViewController.bodyIdentifier: UIScreen.main.bounds.height
    ]
}

protocol ReadingEditViewControllerDelegate {
    
    func add(article: Article)
    func edit(articleId: String, newTitle: String, newTopic: String, newBody: String, newSource: String)
    
}
