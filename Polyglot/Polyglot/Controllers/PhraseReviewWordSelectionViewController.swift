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
        wordLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        wordLabel.translatesAutoresizingMaskIntoConstraints = false

        countsLabel.font = UIFont.systemFont(ofSize: 14)
        countsLabel.textAlignment = .right
        countsLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        countsLabel.setContentHuggingPriority(.required, for: .horizontal)
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
    let displayWord: String
    let meaning: String
    let periodIndex: Int
    let nextReviewDate: Date
    let practiceCounts: [Int]
    let annotationCompleted: [Bool]  // per-type bold display flag
    let isAnnotationReady: Bool      // true when all existing practices are annotated
    let practiceTypes: [WordPractice.PracticeType]

    var isAvailable: Bool { nextReviewDate <= Date() }
    var hasGeneratedPractices: Bool { practiceCounts.contains(where: { $0 > 0 }) }
    var isReadyToPractice: Bool { isAvailable && isAnnotationReady && !meaning.isEmpty && hasGeneratedPractices }
}

// MARK: - View Controller

class PhraseReviewWordSelectionViewController: UITableViewController {

    var practiceDuration: Int = 0
    weak var practiceDelegate: HomeViewController?

    private var sections: [(periodIndex: Int, entries: [WordSelectionEntry])] = []
    private var selectedKeys: Set<String> = []
    // Freezes each section's on-screen row order across reloads: only newly-appeared
    // keys are positioned by the sort formula, existing ones keep their prior slot so
    // background annotation/generation completing doesn't make rows jump around.
    private var orderedKeysByPeriod: [Int: [String]] = [:]
    // Default selection is computed only once per view-controller lifetime; afterwards
    // background reloads must not re-run it (that caused the selection to keep changing
    // as annotation completed and readiness flipped mid-load).
    private var hasAppliedDefaultSelection = false
    // loadEntries() can be invoked concurrently from multiple background queues
    // (backgroundRefresh's own thread, onPracticeCounterUpdated's notification handler).
    // Serialize the read-modify-write of the state above to avoid races between them.
    private let stateLock = NSLock()
    // Only auto-scroll once, right after the initial load — not on every background
    // reload, otherwise the list would keep jumping back under the user while they're
    // scrolling around.
    private var hasScrolledToSelection = false

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
        // Load and display entries synchronously — fast enough to run on the main thread.
        loadEntries()
        tableView.reloadData()
        updateStartButton()
        scrollToFirstSelectedWordIfNeeded()

        // Background: generate missing practices + translations, then refresh counts.
        DispatchQueue.global(qos: .userInitiated).async {
            self.backgroundRefresh()
            self.loadEntries()
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.updateStartButton()
                self.scrollToFirstSelectedWordIfNeeded()
            }
        }
    }

    // MARK: - Data Loading

    private func loadEntries() {
        let lang = LangCode.currentLanguage
        let schedule = EbbinghausSchedule.load(for: lang)
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
        // `normalizedKey` deliberately strips whitespace around punctuation so words like
        // "a, b" and "a,b" match as the same key -- but that makes the key unsuitable for
        // display (it loses the original spacing). Keep the first raw word seen for each
        // key, so the list can show the original text instead of the matching key.
        var displayWordByKey: [String: String] = [:]
        for p in cachedPractices {
            let k = WordPracticeProducer.normalizedKey(from: p.word)
            let period = p.periodIndex ?? 0
            practicesByKeyAndPeriod[k, default: [:]][period, default: [:]][p.practiceType, default: []].append(p)
            if displayWordByKey[k] == nil {
                displayWordByKey[k] = p.word.replacingOccurrences(of: String(Token.accentSymbol), with: "")
            }
        }

        var allEntries: [WordSelectionEntry] = []
        for key in allKeys {
            let schedEntry = EbbinghausSchedule.entry(forKey: key, in: schedule)
            if EbbinghausSchedule.isCompleted(schedEntry) { continue }
            // Note: `key` ranges over `schedule.keys` itself (via `allKeys`), so
            // `schedEntry` is always already present in `schedule` here -- no write-back needed.

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
                displayWord: displayWordByKey[key] ?? key,
                meaning: meaning,
                periodIndex: periodIndex,
                nextReviewDate: schedEntry.nextReviewDate,
                practiceCounts: counts,
                annotationCompleted: annotatedFlags,
                isAnnotationReady: allTypesAnnotated,
                practiceTypes: typesForPeriod
            ))
        }

        // Group by periodIndex, sort sections ascending.
        // Within each section: ready-to-practice entries first, then not-ready;
        // within each group sort by nextReviewDate ascending (earlier = created earlier).
        let grouped = Dictionary(grouping: allEntries, by: { $0.periodIndex })
        let entryByKey = Dictionary(uniqueKeysWithValues: allEntries.map { ($0.key, $0) })

        stateLock.lock()
        defer { stateLock.unlock() }

        sections = grouped.keys.sorted().map { period in
            let sortedByFormula = grouped[period]!.sorted { a, b in
                if a.isReadyToPractice != b.isReadyToPractice {
                    return a.isReadyToPractice
                }
                if a.nextReviewDate != b.nextReviewDate {
                    return a.nextReviewDate < b.nextReviewDate
                }
                // Deterministic tie-breaker so list order doesn't shuffle across reloads
                // when readiness and nextReviewDate are equal (e.g. both .distantPast).
                return a.key < b.key
            }

            // Freeze row order: keep previously-shown keys in their existing slot
            // (dropping ones that disappeared), and append newly-appeared keys in the
            // order the sort formula would place them. This prevents background
            // annotation/generation completing from re-sorting rows that are already
            // on screen out from under the user.
            let currentKeysInPeriod = Set(grouped[period]!.map { $0.key })
            var previousOrder = (orderedKeysByPeriod[period] ?? []).filter { currentKeysInPeriod.contains($0) }
            let previousOrderSet = Set(previousOrder)
            for entry in sortedByFormula where !previousOrderSet.contains(entry.key) {
                previousOrder.append(entry.key)
            }
            orderedKeysByPeriod[period] = previousOrder

            let orderedEntries = previousOrder.compactMap { entryByKey[$0] }
            return (periodIndex: period, entries: orderedEntries)
        }
        // Drop periods that no longer have any entries.
        let currentPeriods = Set(grouped.keys)
        orderedKeysByPeriod = orderedKeysByPeriod.filter { currentPeriods.contains($0.key) }

        // Default-select first N ready-to-practice words, preferring words with more
        // already-generated practices. Runs only once per view-controller lifetime so
        // the selection doesn't keep changing as background annotation completes.
        selectedKeys = selectedKeys.filter { key in
            sections.flatMap { $0.entries }.contains { $0.key == key }
        }
        if !hasAppliedDefaultSelection {
            let candidates = sections
                .flatMap { $0.entries }
                .filter { $0.isReadyToPractice }
                .sorted { $0.practiceCounts.reduce(0, +) > $1.practiceCounts.reduce(0, +) }
            if !candidates.isEmpty {
                selectedKeys = Set(candidates.prefix(defaultSelectionCount).map { $0.key })
                hasAppliedDefaultSelection = true
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
            let missingTypes = typesForPeriod.filter { type in
                wordPractices.filter { $0.practiceType == type }.count < repetitions
            }
            if !missingTypes.isEmpty {
                print("[backgroundRefresh] \(key): generating missing practices for types \(missingTypes)")
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
                print("[backgroundRefresh] \(key): annotating (accent/grammar)")
                let semaphore = DispatchSemaphore(value: 0)
                producer.annotateExistingPractices(for: key) { semaphore.signal() }
                semaphore.wait()
            }

            // (3) Supplement missing meaning for this word.
            // Meaning may already be present via cached meaningSelection/meaningFilling practices
            // even without a reinforcementStore entry (e.g. words added before the reinforcement
            // flow existed). Only fetch a translation if it's missing everywhere.
            let reinforcementStore = ReinforcementWords.load(for: lang)
            let hasStoredMeaning = !(reinforcementStore[key]?.meaning ?? "").isEmpty
            let hasCachedMeaning = practicesAfterGen.contains { practice in
                switch (practice.practiceType, practice.direction) {
                case (.meaningSelection, .textToMeaning), (.meaningFilling, .textToMeaning):
                    return !practice.key.isEmpty
                case (.meaningSelection, .meaningToText), (.meaningFilling, .meaningToText):
                    return !practice.query.isEmpty
                default:
                    return false
                }
            }
            if !hasStoredMeaning && !hasCachedMeaning {
                print("[backgroundRefresh] \(key): fetching meaning")
                let rawWord = reinforcementStore[key]?.word ?? practicesAfterGen.first?.word ?? key
                let wordToTranslate = rawWord.replacingOccurrences(of: String(Token.accentSymbol), with: "")
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                translator.translate(query: wordToTranslate) { translations, _ in
                    if let meaning = translations.first, !meaning.isEmpty {
                        if reinforcementStore[key] != nil {
                            ReinforcementWords.updateMeaning(meaning, forWord: wordToTranslate, for: lang)
                        } else {
                            ReinforcementWords.add(
                                word: wordToTranslate,
                                contextSentence: "",
                                meaning: meaning,
                                for: lang
                            )
                        }
                    }
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

    private func scrollToFirstSelectedWordIfNeeded() {
        guard !hasScrolledToSelection else { return }
        for (sectionIndex, section) in sections.enumerated() {
            if let rowIndex = section.entries.firstIndex(where: { selectedKeys.contains($0.key) }) {
                hasScrolledToSelection = true
                let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
                // scrollToRow(at: .top) aligns the row with the table's visible top edge,
                // but the section header floats (sticky) at that same edge and would cover
                // the row. Push the row down by the header's height so it lands below it.
                tableView.layoutIfNeeded()
                tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                let headerHeight = tableView.rectForHeader(inSection: sectionIndex).height
                if headerHeight > 0 {
                    let adjustedOffsetY = max(tableView.contentOffset.y - headerHeight, -tableView.contentInset.top)
                    tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x, y: adjustedOffsetY), animated: false)
                }
                return
            }
        }
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
        attrText.append(NSAttributedString(string: entry.displayWord))
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
                EbbinghausSchedule.update(for: lang) { schedule in
                    schedule.removeValue(forKey: entry.key)
                }
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
