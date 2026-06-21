//
//  ArticleSelectionViewController.swift
//  Polyglot
//

import UIKit

class ArticleSelectionViewController: UIViewController {

    enum Filter {
        case videosOnly
        case all
    }

    enum PracticeType {
        case videoShadowing
        case speaking
        case reading
    }

    // MARK: - Config

    var filter: Filter = .all
    var practiceType: PracticeType = .reading
    var onArticleSelected: ((Article) -> Void)?

    // MARK: - Models

    private var allArticles: [Article] = []
    private var paragraphMetaData: [String: String] = [:]
    private var displayedGroups: [GroupedArticles] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Views

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.removeRedundantSeparators()
        return tv
    }()

    private let searchController: UISearchController = {
        let sc = UISearchController()
        sc.obscuresBackgroundDuringPresentation = false
        return sc
    }()

    // MARK: - Init

    convenience init(
        articles: [Article],
        filter: Filter,
        practiceType: PracticeType,
        onArticleSelected: @escaping (Article) -> Void
    ) {
        self.init()
        self.allArticles = filteredArticles(from: articles, filter: filter)
        self.filter = filter
        self.practiceType = practiceType
        self.onArticleSelected = onArticleSelected
        self.paragraphMetaData = loadParagraphMetaData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupLayouts()
        displayedGroups = allArticles.groups
    }

    private func setupViews() {
        view.backgroundColor = Colors.defaultBackgroundColor

        navigationItem.searchController = searchController
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        searchController.searchResultsUpdater = self

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            ReadingTableCell.self,
            forCellReuseIdentifier: Self.cellIdentifier
        )

        view.addSubview(tableView)
    }

    private func setupLayouts() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func filteredArticles(from articles: [Article], filter: Filter) -> [Article] {
        switch filter {
        case .videosOnly:
            return articles.filter { $0.isYoutubeVideo }
        case .all:
            return articles
        }
    }

    private func loadParagraphMetaData() -> [String: String] {
        switch practiceType {
        case .reading:
            return ReadingPracticeProducer.loadParagraphMetaData(for: LangCode.currentLanguage)
        case .speaking:
            return SpeakingPracticeProducer.loadParagraphMetaData(for: LangCode.currentLanguage)
        case .videoShadowing:
            return BasePracticeProducer.loadMetaData(for: LangCode.currentLanguage)
        }
    }

    private func progressText(for article: Article) -> String? {
        switch practiceType {
        case .videoShadowing:
            let videoID = YoutubeVideoParser.getVideoID(from: article.source ?? "") ?? ""
            guard !videoID.isEmpty,
                  let stored = paragraphMetaData[videoID],
                  let seconds = Double(stored),
                  seconds > 0
            else { return nil }
            let total = Int(seconds)
            let h = total / 3600
            let m = (total % 3600) / 60
            let s = total % 60
            return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
        case .reading:
            let key = ReadingPracticeProducer.paragraphMetaKey(for: article.id)
            let current = Int(paragraphMetaData[key] ?? "0") ?? 0
            let total = article.paras.count
            if current >= total { return "\(total)/\(total) ✓" }
            return "\(current + 1)/\(total)"
        case .speaking:
            let key = SpeakingPracticeProducer.paragraphMetaKey(for: article.id)
            let current = Int(paragraphMetaData[key] ?? "0") ?? 0
            let total = article.paras.count
            if current >= total { return "\(total)/\(total) ✓" }
            return "\(current + 1)/\(total)"
        }
    }

    // MARK: - Selectors

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    private func isArticleComplete(_ article: Article) -> Bool {
        switch practiceType {
        case .videoShadowing:
            return false
        case .reading:
            let key = ReadingPracticeProducer.paragraphMetaKey(for: article.id)
            let stored = Int(paragraphMetaData[key] ?? "0") ?? 0
            return stored >= article.paras.count
        case .speaking:
            let key = SpeakingPracticeProducer.paragraphMetaKey(for: article.id)
            let stored = Int(paragraphMetaData[key] ?? "0") ?? 0
            return stored >= article.paras.count
        }
    }

    private func confirmRestart(for article: Article, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: Strings.restartArticleTitle,
            message: Strings.restartArticle(for: article.title),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Strings.ok, style: .default) { [weak self] _ in
            self?.resetProgress(for: article, at: indexPath)
            self?.dismiss(animated: true) {
                self?.onArticleSelected?(article)
            }
        })
        alert.addAction(UIAlertAction(title: Strings.cancel, style: .cancel))
        present(alert, animated: true)
    }

    private func confirmReset(for article: Article, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: Strings.resetProgress,
            message: Strings.resetProgressConfirm(for: article.title),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Strings.resetProgress, style: .destructive) { [weak self] _ in
            self?.resetProgress(for: article, at: indexPath)
        })
        alert.addAction(UIAlertAction(title: Strings.cancel, style: .cancel))
        present(alert, animated: true)
    }

    private func resetProgress(for article: Article, at indexPath: IndexPath) {
        switch practiceType {
        case .reading:
            let key = ReadingPracticeProducer.paragraphMetaKey(for: article.id)
            paragraphMetaData[key] = "0"
            var meta = paragraphMetaData
            ReadingPracticeProducer.saveParagraphMetaData(&meta, for: LangCode.currentLanguage)
        case .speaking:
            let key = SpeakingPracticeProducer.paragraphMetaKey(for: article.id)
            paragraphMetaData[key] = "0"
            var meta = paragraphMetaData
            SpeakingPracticeProducer.saveParagraphMetaData(&meta, for: LangCode.currentLanguage)
        case .videoShadowing:
            let videoID = YoutubeVideoParser.getVideoID(from: article.source ?? "") ?? ""
            guard !videoID.isEmpty else { return }
            paragraphMetaData[videoID] = "0"
            var meta = paragraphMetaData
            BasePracticeProducer.saveMetaData(&meta, for: LangCode.currentLanguage)
        }
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}

// MARK: - UITableViewDataSource

extension ArticleSelectionViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        displayedGroups.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedGroups[section].articles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.cellIdentifier,
            for: indexPath
        ) as? ReadingTableCell else {
            return UITableViewCell()
        }
        let article = displayedGroups[indexPath.section].articles[indexPath.row]
        cell.updateValues(article: article, progressText: progressText(for: article))
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ArticleSelectionViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = TableHeaderView()
        let group = displayedGroups[section]
        header.updateValues(text: "\(group.groupId) (\(group.articles.count))")
        return header
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let article = displayedGroups[indexPath.section].articles[indexPath.row]
        if isArticleComplete(article) {
            confirmRestart(for: article, at: indexPath)
        } else {
            dismiss(animated: true) {
                self.onArticleSelected?(article)
            }
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let article = displayedGroups[indexPath.section].articles[indexPath.row]
        let action = UIContextualAction(style: .destructive, title: Strings.resetProgress) { [weak self] _, _, completion in
            self?.confirmReset(for: article, at: indexPath)
            completion(true)
        }
        action.image = UIImage(systemName: "arrow.counterclockwise")
        return UISwipeActionsConfiguration(actions: [action])
    }
}

// MARK: - UISearchResultsUpdating

extension ArticleSelectionViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let keyword = searchController.searchBar.text ?? ""
        DispatchQueue.global(qos: .userInitiated).async {
            self.displayedGroups = self.allArticles.subset(containing: keyword).groups
        }
    }
}

// MARK: - Constants

extension ArticleSelectionViewController {
    private static let cellIdentifier = Identifiers.readingTableCellIdentifier
}

