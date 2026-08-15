//
//  PhraseReviewWordSelectionViewController.swift
//  Polyglot
//
//  Created by Ho on 6/28/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import UIKit

// MARK: - Cell

private class WordSelectionCell: UITableViewCell {

    let wordLabel = UILabel()
    let countsLabel = UILabel()
    let meaningLabel = UILabel()
    let dateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        wordLabel.font = UIFont.systemFont(ofSize: 17)
        wordLabel.translatesAutoresizingMaskIntoConstraints = false

        countsLabel.font = UIFont.systemFont(ofSize: 14)
        countsLabel.textAlignment = .right
        countsLabel.translatesAutoresizingMaskIntoConstraints = false

        meaningLabel.font = UIFont.systemFont(ofSize: 14)
        meaningLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        meaningLabel.translatesAutoresizingMaskIntoConstraints = false

        dateLabel.font = UIFont.systemFont(ofSize: 14)
        dateLabel.textAlignment = .right
        dateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        dateLabel.setContentHuggingPriority(.required, for: .horizontal)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(wordLabel)
        contentView.addSubview(countsLabel)
        contentView.addSubview(meaningLabel)
        contentView.addSubview(dateLabel)

        NSLayoutConstraint.activate([
            wordLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            wordLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            wordLabel.trailingAnchor.constraint(equalTo: countsLabel.leadingAnchor, constant: -8),

            countsLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            countsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            countsLabel.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.35),

            meaningLabel.topAnchor.constraint(equalTo: wordLabel.bottomAnchor, constant: 2),
            meaningLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            meaningLabel.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -8),

            dateLabel.topAnchor.constraint(equalTo: wordLabel.bottomAnchor, constant: 2),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            meaningLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Display a counts string like "211" with per-character bold where annotated.
    /// Pass an empty array to hide the label entirely (counts not yet loaded).
    func setCountsText(_ digits: [Int], annotated: [Bool], color: UIColor) {
        guard !digits.isEmpty else {
            countsLabel.isHidden = true
            countsLabel.attributedText = nil
            return
        }
        countsLabel.isHidden = false
        let attr = NSMutableAttributedString()
        for (count, isAnnotated) in zip(digits, annotated) {
            let font: UIFont = isAnnotated
                ? UIFont.systemFont(ofSize: 14, weight: .bold)
                : UIFont.systemFont(ofSize: 14, weight: .regular)
            attr.append(NSAttributedString(
                string: "\(count)",
                attributes: [.font: font, .foregroundColor: color]
            ))
        }
        countsLabel.attributedText = attr
    }
}

// MARK: - Section Header with Practice-Type Icons

private class PhraseReviewSectionHeaderView: UITableViewHeaderFooterView {

    private let titleLabel = UILabel()
    private var iconStack: UIStackView?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, practiceTypes: [WordPractice.PracticeType]) {
        titleLabel.text = title
        iconStack?.removeFromSuperview()

        let icons = practiceTypes.compactMap { type -> UIImage? in
            return PhraseReviewWordSelectionViewController.practiceTypeIcon(for: type)
        }
        guard !icons.isEmpty else { return }

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        for icon in icons {
            let iv = UIImageView(image: icon.withRenderingMode(.alwaysTemplate))
            iv.tintColor = .secondaryLabel
            iv.contentMode = .scaleAspectFit
            iv.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                iv.widthAnchor.constraint(equalToConstant: 16),
                iv.heightAnchor.constraint(equalToConstant: 16),
            ])
            stack.addArrangedSubview(iv)
        }
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        iconStack = stack
    }
}

// MARK: - Entry

private struct WordSelectionEntry {
    let key: String
    let meaning: String
    let periodIndex: Int
    let nextReviewDate: Date
    let practiceCounts: [Int]
    let annotationCompleted: [Bool]  // per-type bold display flag
    let isAnnotationReady: Bool      // true when all existing practices are annotated
    let practiceTypes: [WordPractice.PracticeType]
    var annotatingItems: [String] = []  // non-empty while background annotation is running

    var isAvailable: Bool { nextReviewDate <= Date() }
    var isReadyToPractice: Bool { isAvailable && isAnnotationReady }
}

// MARK: - View Controller

class PhraseReviewWordSelectionViewController: UITableViewController {

    var practiceDuration: Int = 0
    weak var practiceDelegate: HomeViewController?

    private var sections: [(periodIndex: Int, entries: [WordSelectionEntry])] = []
    private var selectedKeys: Set<String> = []
    // Keys where user tapped to see meaning instead of annotation status.
    private var meaningDisplayKeys: Set<String> = []

    private var defaultSelectionCount: Int { LangCode.currentLanguage.configs.phraseReviewDefaultSelectionCount }
    private static let headerReuseId = "phraseReviewHeader"
    private static let cellReuseId = "cell"

    // MARK: - Init

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(WordSelectionCell.self, forCellReuseIdentifier: Self.cellReuseId)
        tableView.register(PhraseReviewSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: Self.headerReuseId)

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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onAnnotationStatusChanged(_:)),
            name: .wordAnnotationStatusChanged,
            object: nil
        )

        // Load and display entries synchronously — fast enough to run on the main thread.
        loadEntries()
        tableView.reloadData()
        updateStartButton()

        // Background: generate missing practices + translations, then refresh counts.
        DispatchQueue.global(qos: .userInitiated).async {
            self.backgroundRefresh()
            self.loadEntries()
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.updateStartButton()
            }
        }
    }

    // MARK: - Data Loading

    private func loadEntries() {
        let lang = LangCode.currentLanguage
        var schedule = EbbinghausSchedule.load(for: lang)
        // Remove corrupted keys that contain spaces (produced by old addAccents bug).
        let corruptedKeys = schedule.keys.filter { $0.contains(" ") }
        if !corruptedKeys.isEmpty {
            for k in corruptedKeys { schedule.removeValue(forKey: k) }
            EbbinghausSchedule.save(&schedule, for: lang)
        }
        let cachedPractices = WordPracticeProducer.loadCachedPractices(for: lang)
        let reinforcementStore = ReinforcementWords.load(for: lang)
        let enabledTypes = lang.configs.phraseReviewEnabledPracticeTypes

        // Derive unique word entries from already-loaded cachedPractices to avoid
        // loading the large cached practices file a second time via uniqueWordEntries().
        let cachedEntries: [(key: String, meaning: String)] = {
            var seen = Set<String>()
            var meaningByKey: [String: String] = [:]
            var result: [(key: String, meaning: String)] = []
            for p in cachedPractices {
                let k = WordPracticeProducer.normalizedKey(from: p.word)
                if seen.insert(k).inserted {
                    result.append((key: k, meaning: ""))
                }
                if meaningByKey[k] == nil {
                    switch (p.practiceType, p.direction) {
                    case (.meaningSelection, .textToMeaning), (.meaningFilling, .textToMeaning):
                        meaningByKey[k] = p.key
                    case (.meaningSelection, .meaningToText), (.meaningFilling, .meaningToText):
                        meaningByKey[k] = p.query
                    default:
                        break
                    }
                }
            }
            return result.map { (key: $0.key, meaning: meaningByKey[$0.key] ?? "") }
        }()

        let allKeys = Set(schedule.keys)

        // Pre-build a lookup: [normalizedKey: [periodIndex: [type: [practice]]]]
        // to avoid O(keys × practices) filter loops below.
        var practicesByKeyAndPeriod: [String: [Int: [WordPractice.PracticeType: [WordPractice]]]] = [:]
        for p in cachedPractices {
            let k = WordPracticeProducer.normalizedKey(from: p.word)
            let period = p.periodIndex ?? 0
            practicesByKeyAndPeriod[k, default: [:]][period, default: [:]][p.practiceType, default: []].append(p)
        }

        var allEntries: [WordSelectionEntry] = []
        for key in allKeys {
            let schedEntry = EbbinghausSchedule.entry(forKey: key, in: schedule)
            if EbbinghausSchedule.isCompleted(schedEntry) { continue }
            if schedule[key] == nil {
                schedule[key] = schedEntry
            }

            // Meaning: prefer reinforcement store, fall back to cached practices.
            let meaning: String
            if let stored = reinforcementStore[key], !stored.meaning.isEmpty {
                meaning = stored.meaning
            } else {
                meaning = cachedEntries.first(where: { $0.key == key })?.meaning ?? ""
            }

            let periodIndex = schedEntry.periodIndex
            let typesForPeriod = EbbinghausSchedule.effectivePracticeTypes(
                for: periodIndex,
                enabledTypes: enabledTypes
            )

            // Count practices per type for this word/period using pre-built lookup.
            let practicesByType = practicesByKeyAndPeriod[key]?[periodIndex] ?? [:]
            let repetitions = lang.configs.wordPracticeRepetition
            var counts: [Int] = []
            var annotatedFlags: [Bool] = []   // for bold display: true only when has practices AND annotated
            var allTypesAnnotated = true       // for isReadyToPractice: empty types don't block
            for type in typesForPeriod {
                let matching = practicesByType[type] ?? []
                let uniqueCount = min(matching.count, repetitions)
                counts.append(uniqueCount)
                let isAnnotated = matching.isEmpty || matching.allSatisfy {
                    ($0.isAccentAnnotationCompleted || !Self.requiresAccentAnnotation(lang))
                    && ($0.isGrammarAnnotationCompleted || !Self.requiresGrammarAnnotation(lang))
                }
                if !isAnnotated { allTypesAnnotated = false }
                // Bold only when annotated AND has practices.
                annotatedFlags.append(isAnnotated && !matching.isEmpty)
            }

            allEntries.append(WordSelectionEntry(
                key: key,
                meaning: meaning,
                periodIndex: periodIndex,
                nextReviewDate: schedEntry.nextReviewDate,
                practiceCounts: counts,
                annotationCompleted: annotatedFlags,
                isAnnotationReady: allTypesAnnotated,
                practiceTypes: typesForPeriod
            ))
        }
        EbbinghausSchedule.save(&schedule, for: lang)

        // Group by periodIndex, sort sections ascending.
        // Within each section: ready-to-practice entries first, then not-ready;
        // within each group sort by nextReviewDate ascending (earlier = created earlier).
        let grouped = Dictionary(grouping: allEntries, by: { $0.periodIndex })
        sections = grouped.keys.sorted().map { period in
            let sorted = grouped[period]!.sorted { a, b in
                if a.isReadyToPractice != b.isReadyToPractice {
                    return a.isReadyToPractice
                }
                return a.nextReviewDate < b.nextReviewDate
            }
            return (periodIndex: period, entries: sorted)
        }

        // Default-select first N ready-to-practice words.
        selectedKeys = selectedKeys.filter { key in
            sections.flatMap { $0.entries }.contains { $0.key == key }
        }
        if selectedKeys.isEmpty {
            var selected = 0
            for section in sections {
                for entry in section.entries where entry.isReadyToPractice {
                    if selected < defaultSelectionCount {
                        selectedKeys.insert(entry.key)
                        selected += 1
                    }
                }
            }
        }
    }

    // MARK: - Background Refresh

    private func backgroundRefresh() {
        let lang = LangCode.currentLanguage
        let words = Word.load(for: lang)
        let articles = Article.load(for: lang)
        let enabledTypes = lang.configs.phraseReviewEnabledPracticeTypes
        let schedule = EbbinghausSchedule.load(for: lang)
        let repetitions = lang.configs.wordPracticeRepetition

        let producer = WordPracticeProducer(words: words, articles: articles)
        let translator = MachineTranslator(srcLang: lang, trgLang: lang.configs.languageForTranslation)

        // Sort all active, available keys by periodIndex ascending (lowest first).
        let sortedKeys = schedule
            .filter { !EbbinghausSchedule.isCompleted($0.value) && EbbinghausSchedule.isAvailable($0.value) }
            .sorted { $0.value.periodIndex < $1.value.periodIndex }
            .map { $0.key }

        for key in sortedKeys {
            let schedEntry = EbbinghausSchedule.entry(forKey: key, in: schedule)
            let periodIndex = schedEntry.periodIndex
            let typesForPeriod = EbbinghausSchedule.effectivePracticeTypes(
                for: periodIndex,
                enabledTypes: enabledTypes
            )

            // (1) Supplement missing practices for this word.
            let cachedPractices = WordPracticeProducer.loadCachedPractices(for: lang)
            let wordPractices = cachedPractices.filter {
                WordPracticeProducer.normalizedKey(from: $0.word) == key
                    && ($0.periodIndex ?? 0) == periodIndex
            }
            let needsGeneration = typesForPeriod.contains { type in
                wordPractices.filter { $0.practiceType == type }.count < repetitions
            }
            if needsGeneration {
                producer.makeAndCachePractices(for: [key], skipDuplicates: true)
            }

            // (2) Supplement missing annotations for this word.
            let practicesAfterGen = WordPracticeProducer.loadCachedPractices(for: lang).filter {
                WordPracticeProducer.normalizedKey(from: $0.word) == key
                    && ($0.periodIndex ?? 0) == periodIndex
            }
            let needsAnnotation = practicesAfterGen.contains {
                !$0.isAccentAnnotationCompleted || !$0.isGrammarAnnotationCompleted
            }
            if needsAnnotation {
                let semaphore = DispatchSemaphore(value: 0)
                producer.annotateExistingPractices(for: key) { semaphore.signal() }
                semaphore.wait()
            }

            // (3) Supplement missing meaning for this word.
            let reinforcementStore = ReinforcementWords.load(for: lang)
            if let entry = reinforcementStore[key], entry.meaning.isEmpty {
                NotificationCenter.default.post(
                    name: .wordAnnotationStatusChanged,
                    object: nil,
                    userInfo: ["key": key, "annotatingItems": [Strings.annotatingMeaning]]
                )
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                translator.translate(query: entry.word) { translations, _ in
                    if let meaning = translations.first, !meaning.isEmpty {
                        ReinforcementWords.updateMeaning(meaning, forWord: key, for: lang)
                    }
                    NotificationCenter.default.post(
                        name: .wordAnnotationStatusChanged,
                        object: nil,
                        userInfo: ["key": key, "annotatingItems": [String]()]
                    )
                    dispatchGroup.leave()
                }
                dispatchGroup.wait()
            }
        }
    }

    // MARK: - Helpers

    static func practiceTypeIcon(for type: WordPractice.PracticeType) -> UIImage? {
        let name: String
        switch type {
        case .meaningSelection:   name = "list.bullet"
        case .meaningFilling:     name = "pencil"
        case .contextSelection:   name = "text.bubble"
        case .reordering:         name = "arrow.left.arrow.right"
        case .phraseConstruction: name = "puzzlepiece"
        case .imageSelection:     name = "photo"
        case .imageFilling:       name = "photo.badge.plus"
        case .accentSelection:    name = "textformat.abc"
        }
        return UIImage(systemName: name)
    }

    private static func requiresAccentAnnotation(_ lang: LangCode) -> Bool {
        return lang == .ja || lang == .ru
    }

    private static func requiresGrammarAnnotation(_ lang: LangCode) -> Bool {
        return lang.configs.shouldShowVerbAspectsInPractices
            || lang.configs.shouldShowNounCasesInPractices
    }

    @objc private func onPracticeCounterUpdated() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.loadEntries()
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.updateStartButton()
            }
        }
    }

    @objc private func onAnnotationStatusChanged(_ notification: Notification) {
//        guard let key = notification.userInfo?["key"] as? String,
//              let items = notification.userInfo?["annotatingItems"] as? [String] else { return }
//
//        DispatchQueue.main.async {
//            for s in 0..<self.sections.count {
//                for r in 0..<self.sections[s].entries.count {
//                    if self.sections[s].entries[r].key == key {
//                        self.sections[s].entries[r].annotatingItems = items
//                        // Clear toggle override when annotation finishes.
//                        if items.isEmpty { self.meaningDisplayKeys.remove(key) }
//                        let indexPath = IndexPath(row: r, section: s)
//                        self.tableView.reloadRows(at: [indexPath], with: .none)
//                        return
//                    }
//                }
//            }
//        }
    }

    private func updateStartButton() {
        navigationItem.rightBarButtonItem?.isEnabled = !selectedKeys.isEmpty
        let count = selectedKeys.count
        title = count > 0
            ? "\(Strings.phraseReview) (\(count))"
            : Strings.phraseReview
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: Self.headerReuseId
        ) as! PhraseReviewSectionHeaderView
        let periodIndex = sections[section].periodIndex
        let title = Strings.periodHeader.replacingOccurrences(of: "#", with: String(periodIndex + 1))
        let enabledTypes = LangCode.currentLanguage.configs.phraseReviewEnabledPracticeTypes
        let types = EbbinghausSchedule.effectivePracticeTypes(for: periodIndex, enabledTypes: enabledTypes)
        header.configure(title: title, practiceTypes: types)
        return header
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].entries.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellReuseId, for: indexPath) as! WordSelectionCell
        let entry = sections[indexPath.section].entries[indexPath.row]

        let attrText = NSMutableAttributedString(
            string: "\(indexPath.row + 1). ",
            attributes: [.foregroundColor: Colors.weakTextColor]
        )
        attrText.append(NSAttributedString(string: entry.key))
        cell.wordLabel.attributedText = attrText
        cell.selectionStyle = .none

        let isReady = entry.isReadyToPractice
        let isAvailable = entry.isAvailable

        // Color scheme:
        // - ready to practice: word=black, others=dark gray
        // - not yet available: all light gray
        let wordColor: UIColor
        let secondaryColor: UIColor
        if isReady {
            wordColor = .label
            secondaryColor = Colors.weakTextColor
        } else {
            wordColor = Colors.inactiveTextColor
            secondaryColor = Colors.inactiveTextColor
        }

        cell.wordLabel.textColor = wordColor
        cell.isUserInteractionEnabled = isReady
        cell.backgroundColor = (isReady && selectedKeys.contains(entry.key)) ? Colors.lightBlue : .clear

        cell.setCountsText(entry.practiceCounts, annotated: entry.annotationCompleted, color: secondaryColor)

        cell.meaningLabel.text = entry.meaning.isEmpty ? " " : entry.meaning
        cell.meaningLabel.textColor = secondaryColor

        if isAvailable {
            cell.dateLabel.text = ""
        } else {
            cell.dateLabel.text = entry.nextReviewDate.repr(of: Date.defaultDateFormat)
        }
        cell.dateLabel.textColor = secondaryColor

        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let entry = sections[indexPath.section].entries[indexPath.row]

        guard entry.isReadyToPractice else { return }
        let key = entry.key
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
                let lang = LangCode.currentLanguage
                WordPracticeProducer.deleteWordPractices(forKey: entry.key, lang: lang)
                var schedule = EbbinghausSchedule.load(for: lang)
                schedule.removeValue(forKey: entry.key)
                EbbinghausSchedule.save(&schedule, for: lang)
                ReinforcementWords.remove(word: entry.key, for: lang)
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
