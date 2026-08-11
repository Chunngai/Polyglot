//
//  PhraseReviewWordSelectionViewController.swift
//  Polyglot
//
//  Created by Ho on 6/28/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import UIKit

private class WordSelectionCell: UITableViewCell {

    let wordLabel = UILabel()
    let dateLabel = UILabel()
    let meaningLabel = UILabel()
    let typesLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        wordLabel.font = UIFont.systemFont(ofSize: 17)
        wordLabel.translatesAutoresizingMaskIntoConstraints = false

        dateLabel.font = UIFont.systemFont(ofSize: 14)
        dateLabel.textAlignment = .right
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        meaningLabel.font = UIFont.systemFont(ofSize: 14)
        meaningLabel.translatesAutoresizingMaskIntoConstraints = false

        typesLabel.font = UIFont.systemFont(ofSize: 14)
        typesLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(wordLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(meaningLabel)
        contentView.addSubview(typesLabel)

        NSLayoutConstraint.activate([
            wordLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            wordLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            wordLabel.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -8),

            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dateLabel.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.45),

            meaningLabel.topAnchor.constraint(equalTo: wordLabel.bottomAnchor, constant: 2),
            meaningLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            meaningLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            typesLabel.topAnchor.constraint(equalTo: meaningLabel.bottomAnchor, constant: 2),
            typesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            typesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            typesLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}

private struct WordSelectionEntry {
    let key: String
    let meaning: String
    let periodIndex: Int
    let nextReviewDate: Date
    var isAvailable: Bool { nextReviewDate <= Date() }
}

class PhraseReviewWordSelectionViewController: UITableViewController {

    var practiceDuration: Int = 0
    weak var practiceDelegate: HomeViewController?

    private var sections: [(periodIndex: Int, entries: [WordSelectionEntry])] = []
    private var selectedKeys: Set<String> = []

    private static let defaultSelectionCount = 6

    // MARK: - Init

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.phraseReview
        tableView.register(WordSelectionCell.self, forCellReuseIdentifier: "cell")

        loadEntries()
        DispatchQueue.global(qos: .userInitiated).async {
            self.generatePracticesForAvailableWords()
            DispatchQueue.main.async { self.tableView.reloadData() }
        }

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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onPracticeCounterUpdated),
            name: .wordPracticeCounterUpdated,
            object: nil
        )
    }

    private func loadEntries() {
        let lang = LangCode.currentLanguage
        var schedule = EbbinghausSchedule.load(for: lang)

        // Collect all known word keys: from schedule + from cached practices.
        let cachedEntries = WordPracticeProducer.uniqueWordEntries(for: lang)

        var allKeys = Set(schedule.keys)
        for e in cachedEntries { allKeys.insert(e.key) }

        // Build selection entries.
        var allEntries: [WordSelectionEntry] = []
        for key in allKeys {
            let schedEntry = EbbinghausSchedule.entry(forKey: key, in: schedule)
            // Skip completed words (no longer in schedule after all periods done).
            if EbbinghausSchedule.isCompleted(schedEntry) { continue }
            // Ensure schedule is persisted for words discovered via cached practices.
            if schedule[key] == nil {
                schedule[key] = schedEntry
            }
            let meaning = cachedEntries.first(where: { $0.key == key })?.meaning ?? ""
            allEntries.append(WordSelectionEntry(
                key: key,
                meaning: meaning,
                periodIndex: schedEntry.periodIndex,
                nextReviewDate: schedEntry.nextReviewDate
            ))
        }
        EbbinghausSchedule.save(&schedule, for: lang)

        // Group by periodIndex, sort sections ascending, entries alphabetically.
        let grouped = Dictionary(grouping: allEntries, by: { $0.periodIndex })
        sections = grouped.keys.sorted().map { period in
            let sorted = grouped[period]!.sorted { $0.key < $1.key }
            return (periodIndex: period, entries: sorted)
        }

        // Default-select first N available words.
        var selected = 0
        for section in sections {
            for entry in section.entries where entry.isAvailable {
                if selected < Self.defaultSelectionCount {
                    selectedKeys.insert(entry.key)
                    selected += 1
                }
            }
        }
    }

    private func generatePracticesForAvailableWords() {
        let lang = LangCode.currentLanguage
        let counter = WordPracticeProducer.countWordPractices(for: lang)
        let availableWithoutPractices = sections
            .flatMap { $0.entries }
            .filter { $0.isAvailable && !counter.keys.contains($0.key) }
            .map { $0.key }

        guard !availableWithoutPractices.isEmpty else { return }

        // We need a producer with the full word list to generate practices.
        let words = Word.load(for: lang)
        let articles = Article.load(for: lang)
        let producer = WordPracticeProducer(words: words, articles: articles)
        producer.makeAndCachePractices(for: availableWithoutPractices, skipDuplicates: false)
    }

    @objc private func onPracticeCounterUpdated() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.updateStartButton()
        }
    }

    private func updateStartButton() {
        navigationItem.rightBarButtonItem?.isEnabled = !selectedKeys.isEmpty
    }

    private func practiceTypeLabel(_ type: WordPractice.PracticeType) -> String {
        switch type {
        case .meaningSelection:   return "MeanSel"
        case .meaningFilling:     return "MeanFill"
        case .contextSelection:   return "CtxSel"
        case .reordering:         return "Reorder"
        case .phraseConstruction: return "Phrase"
        case .imageSelection:     return "ImgSel"
        case .imageFilling:       return "ImgFill"
        case .accentSelection:    return "Accent"
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let period = sections[section].periodIndex
        return Strings.periodHeader.replacingOccurrences(of: "#", with: String(period + 1))
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].entries.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! WordSelectionCell
        let entry = sections[indexPath.section].entries[indexPath.row]

        let attrText = NSMutableAttributedString(
            string: "\(indexPath.row + 1). ",
            attributes: [.foregroundColor: Colors.weakTextColor]
        )
        attrText.append(NSAttributedString(string: entry.key))
        cell.wordLabel.attributedText = attrText
        cell.selectionStyle = .none

        let cachedPractices = WordPracticeProducer.loadCachedPractices(for: LangCode.currentLanguage)
        let generatedTypes = cachedPractices
            .filter { WordPracticeProducer.normalizedKey(from: $0.word) == entry.key }
            .map { $0.practiceType }
        let uniqueTypes = Array(NSOrderedSet(array: generatedTypes)) as! [WordPractice.PracticeType]
        let typesText = uniqueTypes.map { practiceTypeLabel($0) }.joined(separator: ", ")

        if entry.isAvailable {
            cell.wordLabel.alpha = 1.0
            cell.isUserInteractionEnabled = true
            cell.accessoryType = selectedKeys.contains(entry.key) ? .checkmark : .none
            cell.dateLabel.text = ""
            cell.dateLabel.textColor = Colors.weakTextColor
            cell.meaningLabel.text = entry.meaning
            cell.meaningLabel.textColor = Colors.weakTextColor
            cell.typesLabel.text = typesText
            cell.typesLabel.textColor = Colors.weakTextColor
        } else {
            cell.wordLabel.alpha = 0.4
            cell.isUserInteractionEnabled = false
            cell.accessoryType = .none
            cell.dateLabel.text = entry.nextReviewDate.repr(of: Date.defaultDateFormat)
            cell.dateLabel.textColor = Colors.inactiveTextColor
            cell.meaningLabel.text = entry.meaning
            cell.meaningLabel.textColor = Colors.inactiveTextColor
            cell.typesLabel.text = typesText
            cell.typesLabel.textColor = Colors.inactiveTextColor
        }

        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let key = sections[indexPath.section].entries[indexPath.row].key
        if selectedKeys.contains(key) {
            selectedKeys.remove(key)
        } else {
            selectedKeys.insert(key)
        }
        tableView.reloadRows(at: [indexPath], with: .none)
        updateStartButton()
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let entry = sections[indexPath.section].entries[indexPath.row]
        guard entry.isAvailable else { return nil }
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
                var schedule = EbbinghausSchedule.load(for: LangCode.currentLanguage)
                schedule.removeValue(forKey: entry.key)
                EbbinghausSchedule.save(&schedule, for: LangCode.currentLanguage)
                self.selectedKeys.remove(entry.key)
                var sectionEntries = self.sections[indexPath.section].entries
                sectionEntries.remove(at: indexPath.row)
                if sectionEntries.isEmpty {
                    self.sections.remove(at: indexPath.section)
                    tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
                    self.updateStartButton()
                } else {
                    self.sections[indexPath.section] = (
                        periodIndex: self.sections[indexPath.section].periodIndex,
                        entries: sectionEntries
                    )
                    tableView.performBatchUpdates({
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }, completion: { _ in
                        let remaining = (0..<sectionEntries.count).map {
                            IndexPath(row: $0, section: indexPath.section)
                        }
                        tableView.reloadRows(at: remaining, with: .none)
                        self.updateStartButton()
                    })
                }
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
