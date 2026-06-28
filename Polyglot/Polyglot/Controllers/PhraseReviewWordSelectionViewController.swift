//
//  PhraseReviewWordSelectionViewController.swift
//  Polyglot
//
//  Created by Ho on 6/28/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import UIKit

private class SubtitleCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    required init?(coder: NSCoder) { fatalError() }
}

class PhraseReviewWordSelectionViewController: UITableViewController {

    var practiceDuration: Int = 0
    weak var practiceDelegate: HomeViewController?

    private var entries: [(key: String, meaning: String)] = []
    private var selectedKeys: Set<String> = []

    private static let defaultSelectionCount = 6

    // MARK: - Init

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.phraseReview
        tableView.register(SubtitleCell.self, forCellReuseIdentifier: "cell")

        entries = WordPracticeProducer.uniqueWordEntries(for: LangCode.currentLanguage)
        let defaultSelected = entries.prefix(Self.defaultSelectionCount).map { $0.key }
        selectedKeys = Set(defaultSelected)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: Strings.cancel,
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: Strings.start,
            style: .done,
            target: self,
            action: #selector(startTapped)
        )
        updateStartButton()
    }

    private func updateStartButton() {
        navigationItem.rightBarButtonItem?.isEnabled = !selectedKeys.isEmpty
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let entry = entries[indexPath.row]
        let attrText = NSMutableAttributedString(
            string: "\(indexPath.row + 1). ",
            attributes: [.foregroundColor: Colors.weakTextColor]
        )
        attrText.append(NSAttributedString(string: entry.key))
        cell.textLabel?.attributedText = attrText
        cell.selectionStyle = .none
        cell.detailTextLabel?.text = entry.meaning
        cell.detailTextLabel?.textColor = Colors.weakTextColor
        cell.accessoryType = selectedKeys.contains(entry.key) ? .checkmark : .none
        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let key = entries[indexPath.row].key
        if selectedKeys.contains(key) {
            selectedKeys.remove(key)
        } else {
            selectedKeys.insert(key)
        }
        tableView.reloadRows(at: [indexPath], with: .none)
        updateStartButton()
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let entry = entries[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: Strings.delete) { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            let alert = UIAlertController(
                title: Strings.deleteWordPracticesAlertTitle,
                message: Strings.deleteWordPracticesAlertBody,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: Strings.cancel, style: .cancel) { _ in completion(false) })
            alert.addAction(UIAlertAction(title: Strings.delete, style: .destructive) { _ in
                WordPracticeProducer.deleteWordPractices(forKey: entry.key, lang: LangCode.currentLanguage)
                self.selectedKeys.remove(entry.key)
                self.entries.remove(at: indexPath.row)
                tableView.performBatchUpdates({
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }, completion: { _ in
                    let remaining = (0..<self.entries.count).map { IndexPath(row: $0, section: 0) }
                    tableView.reloadRows(at: remaining, with: .none)
                    self.updateStartButton()
                })
                completion(true)
            })
            self.present(alert, animated: true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func startTapped() {
        let vc = WordsPracticeViewController()
        vc.practiceDuration = practiceDuration
        vc.delegate = practiceDelegate
        vc.selectedWordKeys = selectedKeys
        navigationController?.setViewControllers([vc], animated: true)
    }
}
