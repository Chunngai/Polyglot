//
//  NounCaseSettingsViewController.swift
//  Polyglot
//

import UIKit

protocol NounCaseSettingsViewControllerDelegate: AnyObject {
    func nounCaseSettingsDidUpdate(isOn: Bool, excludedWords: String)
}

class NounCaseSettingsViewController: SettingsViewController {

    weak var delegate: NounCaseSettingsViewControllerDelegate?

    private var isOn: Bool
    private var excludedWords: [String]

    private lazy var toggleCell: SettingsSwitchingCell = {
        let cell = SettingsSwitchingCell(style: .default, reuseIdentifier: "")
        cell.imageView?.image = UIImage(systemName: "n.square")
        cell.label.text = "Show"
        cell.switchView.isOn = isOn
        cell.funcAfterSwitching = { [weak self] on in
            self?.isOn = on
            self?.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        }
        return cell
    }()

    private lazy var addCell: UITableViewCell = {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "")
        cell.imageView?.image = UIImage(systemName: "plus.circle.fill")
        cell.imageView?.tintColor = Colors.activeSystemButtonColor
        cell.textLabel?.text = "Add Word"
        cell.textLabel?.textColor = Colors.activeSystemButtonColor
        cell.textLabel?.font = UIFont.systemFont(ofSize: Sizes.mediumFontSize)
        return cell
    }()

    init(isOn: Bool, excludedWords: String) {
        self.isOn = isOn
        self.excludedWords = excludedWords
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Show Noun Cases"
    }

    override func saveSettings() {
        delegate?.nounCaseSettingsDidUpdate(
            isOn: isOn,
            excludedWords: excludedWords.joined(separator: "\n")
        )
    }

    private func makeWordCell(for word: String) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "")
        cell.textLabel?.text = word
        cell.textLabel?.font = UIFont.monospacedSystemFont(ofSize: Sizes.mediumFontSize, weight: .regular)
        cell.textLabel?.textColor = Colors.normalTextColor
        cell.selectionStyle = .none
        return cell
    }

    // MARK: - UITableViewDataSource overrides

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 1 }
        return isOn ? excludedWords.count + 1 : 0  // +1 for add button
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 { return toggleCell }
        if indexPath.row == excludedWords.count { return addCell }
        return makeWordCell(for: excludedWords[indexPath.row])
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 && isOn { return "Words to Exclude" }
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Sizes.mediumFontSize * 3
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return Sizes.mediumFontSize * 3
    }

}

extension NounCaseSettingsViewController {

    // MARK: - UITableViewDelegate overrides

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1, indexPath.row == excludedWords.count else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        let alert = UIAlertController(title: "Add Word", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.font = UIFont.monospacedSystemFont(ofSize: Sizes.mediumFontSize, weight: .regular)
            tf.autocorrectionType = .no
            tf.autocapitalizationType = .none
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self else { return }
            guard let word = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces),
                  !word.isEmpty else { return }
            excludedWords.append(word)
            tableView.insertRows(
                at: [IndexPath(row: excludedWords.count - 1, section: 1)],
                with: .automatic
            )
        })
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 1, indexPath.row < excludedWords.count else { return nil }
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.excludedWords.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

}
