//
//  NewHomeViewController.swift
//  Polyglot
//
//  Created by Ho on 9/28/23.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit
import SnapKit

struct HomeItem: Hashable {
    
    private let identifier = UUID()

    let image: UIImage?
    let text: String?
    let secondaryText: String?
    
    init(image: UIImage? = nil, text: String? = nil, secondaryText: String? = nil) {
        self.image = image
        self.text = text
        self.secondaryText = secondaryText
    }
}

class HomeViewController: UIViewController {
    
    // Langauges.
    
    var learningLangs = LangCode.loadLearningLanguages()
    
    var lang: String! {
        didSet {
            guard let lang = lang, Variables.lang != lang else {
                return
            }
            print("Updating lang to \(lang)")
            
            Variables.lang = lang
            
            self.wordCardEntries = WordCardEntry.load(for: lang)
            self.wordMetaData = Word.loadMetaData(for: lang)
            self.articleMetaData = Article.loadMetaData(for: lang)
            
            self.updateTexts()
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.generateWordcardEntries()
                
                // removeAllNotifications()
                self.generateWordcardNotifications()
            }
        }
    }
    
    // Collection view stuff.
    
    enum Section: Int, CaseIterable {
        
        case languages
        case lists
        case practices
        
        var description: String {
            switch self {
            case .languages: return "Languages"
            case .lists: return "Lists"
            case .practices: return "Practices"
            }
        }
    }
    
    var dataSource: UICollectionViewDiffableDataSource<Section, HomeItem>!
    
    let languageItems = LangCode.loadLearningLanguages().map { langCode in
        return HomeItem(
            image: Images.langImages[langCode], 
            text: LangCode.toFlagIcon(langCode: langCode)
        )
    }
    
    lazy var listItems = [
        HomeItem(
            image: UIImage.init(systemName: "list.bullet"),
            text: Strings._phrases[learningLangs[0]]
        ),
        HomeItem(
            image: UIImage.init(systemName: "books.vertical"),
            text: Strings._articles[learningLangs[0]]
        )
    ]
    
    lazy var practiceItems = [
        HomeItem(
            image: UIImage.init(systemName: "square.and.pencil"),
            text: Strings._phraseReview[learningLangs[0]]
        ),
        HomeItem(
            image: UIImage.init(systemName: "doc"),
            text: Strings._reading[learningLangs[0]]
        ),
        HomeItem(
            image: UIImage.init(systemName: "bubble"),
            text: Strings._interpretation[learningLangs[0]]
        )
    ]
        
    // MARK: - Models
    
    var words: [Word]! {
        get {
            return Word.load(for: self.lang)
        }
        set {
            guard var newValue = newValue else {
                return
            }
            Word.save(&newValue, for: self.lang)
            
            let newWordNumber = newValue.count
            wordMetaData["count"] = String(newWordNumber)
            updateTexts()
        }
    }
    var articles: [Article]! {
        get {
            return Article.load(for: self.lang)
        }
        set {
            guard var newValue = newValue else {
                return
            }
            Article.save(&newValue, for: self.lang)
            
            let newArticleNumber = newValue.count
            articleMetaData["count"] = String(newArticleNumber)
            updateTexts()
        }
    }
    
    var wordCardEntries: [WordCardEntry]! {
        didSet {
            WordCardEntry.save(&wordCardEntries, for: self.lang)
        }
    }
    
    var wordMetaData: [String:String]! {
        didSet {
            Word.saveMetaData(&wordMetaData, for: self.lang)
        }
    }
    var articleMetaData: [String:String]! {
        didSet {
            Article.saveMetaData(&articleMetaData, for: self.lang)
        }
    }
    
    // MARK: - Controllers
    
    // MARK: - Views
    
    var collectionView: UICollectionView!

    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    private func updateSetups() {
        // Set up the collection view.
        configureHierarchy()
        configureDataSource()
        applyInitialSnapshots()
    }
    
    private func updateViews() {
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.title = "Home"  // TODO: - animation.
        navigationItem.largeTitleDisplayMode = .always
    }
    
    private func updateLayouts() {
        
    }
}

extension HomeViewController {
    
    // MARK: - Utils
    
    private func updateCell(at indexPath: IndexPath, text: String, secondaryText: String? = nil) {
        if let cell = collectionView.cellForItem(at: indexPath) as? UICollectionViewListCell {
            if var config = cell.contentConfiguration as? UIListContentConfiguration {
                config.text = text
                config.secondaryText = secondaryText
                // Enable to display lists or practice.
                config.textProperties.color = Colors.normalTextColor
                cell.contentConfiguration = config
            }
        }
    }
    
    private func updateTexts() {
        navigationItem.title = Strings.homeTitle
        
        updateCell(
            at: IndexPath(row: 0, section: 1),
            text: Strings.phrases,
            secondaryText: wordMetaData["count"]
        )
        updateCell(
            at: IndexPath(row: 1, section: 1),
            text: Strings.articles,
            secondaryText: articleMetaData["count"]
        )
        
        updateCell(
            at: IndexPath(row: 0, section: 2),
            text: Strings.phraseReview
        )
        updateCell(
            at: IndexPath(row: 1, section: 2),
            text: Strings.reading
        )
        updateCell(
            at: IndexPath(row: 2, section: 2),
            text: Strings.interpretation
        )
    }
    
}

extension HomeViewController {
    
    // MARK: - Collection View Config
    
    func configureHierarchy() {
        collectionView = UICollectionView(
            frame: view.bounds,
            collectionViewLayout: createLayout()
        )
        collectionView.autoresizingMask = [
            .flexibleWidth,
            .flexibleHeight
        ]
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        view.addSubview(collectionView)
    }
    
    func createLayout() -> UICollectionViewLayout {
        
        return UICollectionViewCompositionalLayout { (
            sectionIndex: Int,
            layoutEnvironment: NSCollectionLayoutEnvironment
        ) -> NSCollectionLayoutSection? in
            
            guard let sectionKind = Section(rawValue: sectionIndex) else {
                return nil
            }
            
            let section: NSCollectionLayoutSection
            
            if sectionKind == .languages {
                
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0 / 3.0),
                    heightDimension: .fractionalHeight(1.0)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalWidth(0.23)
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    repeatingSubitem: item,
                    count: 3
                )
                group.interItemSpacing = .flexible(10)
                
                section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 10
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 20,
                    leading: 20,
                    bottom: 0,
                    trailing: 20
                )
            } else if sectionKind == .lists || sectionKind == .practices {
                let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                
                section = NSCollectionLayoutSection.list(
                    using: configuration,
                    layoutEnvironment: layoutEnvironment
                )
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 30,
                    leading: 20,
                    bottom: 0,
                    trailing: 20
                )
            } else {
                fatalError("Unknown section!")
            }
            
            return section
        }
    }
    
    func createGridCellRegistration() -> UICollectionView.CellRegistration<LangCell, HomeItem> {
        return UICollectionView.CellRegistration<LangCell, HomeItem> { (
            cell: LangCell,
            indexPath: IndexPath,
            item: HomeItem
        ) in
            
            let content = LangCellContentConfiguration()
            content.langImage = item.image
//            content.text = item.text
//            content.textProperties.font = .boldSystemFont(ofSize: 38)
//            content.textProperties.alignment = .center
//            content.directionalLayoutMargins = .zero
            cell.contentConfiguration = content
            
            var background = UIBackgroundConfiguration.listPlainCell()
            background.cornerRadius = 8
            // https://www.appsloveworld.com/swift/100/44/how-change-the-selection-color-in-compositional-layouts-in-collectionview
            background.backgroundColorTransformer = UIConfigurationColorTransformer { color in
                // Set the selection color to white.
                return .white
            }
            cell.backgroundConfiguration = background
        }
    }
    
    func createListCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewListCell, HomeItem> {
        return UICollectionView.CellRegistration<UICollectionViewListCell, HomeItem> { (
            cell: UICollectionViewListCell,
            indexPath: IndexPath,
            item: HomeItem
        ) in
            
            var content = UIListContentConfiguration.valueCell()
            content.image = item.image
            content.text = item.text
            content.secondaryText = item.secondaryText
            content.textProperties.color = .lightGray
            cell.contentConfiguration = content
            
            var background = UIBackgroundConfiguration.listPlainCell()
            // https://www.appsloveworld.com/swift/100/44/how-change-the-selection-color-in-compositional-layouts-in-collectionview
            background.backgroundColorTransformer = UIConfigurationColorTransformer { color in
                // Set the selection color to white.
                return .white
            }
            cell.backgroundConfiguration = background
            
            if indexPath.section == Section.lists.rawValue {
                cell.accessories = [UICellAccessory.disclosureIndicator()]
            }
        }
    }
    
    func configureDataSource() {
        let gridCellRegistration = createGridCellRegistration()
        let listCellRegistration = createListCellRegistration()
        
        dataSource = UICollectionViewDiffableDataSource<Section, HomeItem>(collectionView: collectionView) {
            (collectionView, indexPath, item) -> UICollectionViewCell? in
            
            guard let section = Section(rawValue: indexPath.section) else {
                fatalError("Unknown section")
            }
            
            switch section {
            case .languages:
                return collectionView.dequeueConfiguredReusableCell(
                    using: gridCellRegistration,
                    for: indexPath,
                    item: item
                )
            case .lists:
                return collectionView.dequeueConfiguredReusableCell(
                    using: listCellRegistration,
                    for: indexPath,
                    item: item
                )
            case .practices:
                return collectionView.dequeueConfiguredReusableCell(
                    using: listCellRegistration,
                    for: indexPath,
                    item: item
                )
            }
        }
    }
    
    func applyInitialSnapshots() {

        let sections = Section.allCases
        var snapshot = NSDiffableDataSourceSnapshot<Section, HomeItem>()
        snapshot.appendSections(sections)
        dataSource.apply(snapshot, animatingDifferences: false)
            
        var languagesSnapShot = NSDiffableDataSourceSectionSnapshot<HomeItem>()
        languagesSnapShot.append(languageItems)
        dataSource.apply(languagesSnapShot, to: .languages, animatingDifferences: false)
        
        var listsSnapshot = NSDiffableDataSourceSectionSnapshot<HomeItem>()
        listsSnapshot.append(listItems)
        dataSource.apply(listsSnapshot, to: .lists, animatingDifferences: false)
        
        var practicesSnapShot = NSDiffableDataSourceSectionSnapshot<HomeItem>()
        practicesSnapShot.append(practiceItems)
        dataSource.apply(practicesSnapShot, to: .practices, animatingDifferences: false)
    }
}

extension HomeViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let section = Section(rawValue: indexPath.section) else {
            return
        }
        let row = indexPath.row
        
        var cell = collectionView.cellForItem(at: indexPath)
        if section == .lists || section == .practices {
            cell = cell as? UICollectionViewListCell
        }
        guard let cell = cell else {
            return
        }
        
        Feedbacks.defaultFeedbackGenerator.selectionChanged()
        
        if section == .languages {
            
            cell.backgroundConfiguration?.strokeColor = .systemGray3
            cell.backgroundConfiguration?.strokeWidth = 2
            // Change the view of other language cells
            // into the deselected status.
            // Cannot do this in collectionView(didDeselectItemAt:)
            // because doing so will deselect the selected
            // language cell if a cell in other lists
            // is selected, which is not expected.
            for i in 0..<learningLangs.count {
                if i == indexPath.row {
                    continue
                }
                let indexPathToDeselect = IndexPath(row: i, section: 0)
                if let cell = collectionView.cellForItem(at: indexPathToDeselect) {
                    cell.backgroundConfiguration?.strokeColor = .clear
                    cell.backgroundConfiguration?.strokeWidth = .zero
                }
            }
            
            // Update the current language.
            self.lang = self.learningLangs[indexPath.row]
            
        } else if section == .lists {
                    
            guard self.lang != nil else {
                return
            }
            
            let vc: ListViewController
            if row == 0 {
                vc = WordsViewController()
            } else if row == 1 {
                vc = ReadingViewController()
            } else {
                fatalError("Not Implemented.")
            }
            vc.delegate = self
            
            navigationController?.pushViewController(
                vc,
                animated: true
            )
        } else if section == .practices {
            
            guard self.lang != nil else {
                return
            }
            
            let vc: PracticeViewController
            if row == 0 {
                vc = WordsPracticeViewController()
            } else if row == 1 {
                vc = ReadingPracticeViewController()
            } else if row == 2 {
                vc = TranslationPracticeViewController()
            } else {
                fatalError("Not Implemented.")
            }
            vc.delegate = self
            
            navigationController?.present(
                NavController(rootViewController: vc),
                animated: true,
                completion: nil
            )
        }
    }
}

extension HomeViewController {
    
    func createWordCardContent() -> (
        word: Word,
        content: String,
        shouldObtainAccent: Bool
    ) {
        let word = self.words.randomElement()!
        
        var shouldObtainAccent = false
        if self.lang == LangCode.ja && (word.tokens == nil || word.isOldJaAccents) {
            shouldObtainAccent = true
        }
        if self.lang == LangCode.ru && word.tokens == nil {
            shouldObtainAccent = true
        }
        
        let candidates = articles.paraCandidates(
            for: word,
            shouldIgnoreCase: true
        )
        guard let candidate = candidates.randomElement() else {
            return (
                word: word,
                content: word.meaning,
                shouldObtainAccent: shouldObtainAccent
            )
        }
        
        let sentences = candidate.text.components(from: Variables.tokenizerOfLang(of: .sentence))
        guard let targetSentence = sentences.first(where: { (sentence) -> Bool in
            sentence.contains(word.text)
        }) else {
            return (
                word: word,
                content: word.meaning,
                shouldObtainAccent: shouldObtainAccent
            )
        }
        
        return (
            word: word,
            content: targetSentence.replacingOccurrences(
                of: word.text,
                with: "#\(word.text)#"
            ),
            shouldObtainAccent: shouldObtainAccent
        )
    }
    
    func makeWordCardTitle(word: Word) -> String {
        return word.accentedText(tokenSeparator: Strings.wordSeparator)
    }
    
    func generateWordcardEntries() {
        guard !words.isEmpty else {
            return
        }
        
        while wordCardEntries.count < WordCardEntry.maxEntryNumber {
            let wordCardContent = self.createWordCardContent()
            let title = makeWordCardTitle(word: wordCardContent.word)
            let body: String = wordCardContent.content
            
            wordCardEntries.append(WordCardEntry(
                title: title,
                body: body
            ))
            let index = wordCardEntries.count - 1
                
            if body == wordCardContent.word.meaning {
                // Make content with ChatGPT.
                ContentCreator().createContent(
                    for: wordCardContent.word.text,
                    in: lang
                ) { (sentence: String?) in
                    guard let sentence = sentence else {
                        return
                    }
                    let newBody = "[ChatGPT] " + sentence.replacingOccurrences(
                        of: wordCardContent.word.text,
                        with: "#\(wordCardContent.word.text)#",
                        options: [.caseInsensitive]
                    )
                    if index >= self.wordCardEntries.count {
                        // TODO: - will happen occasionally
                        return
                    }
                    self.wordCardEntries[index].body = newBody
                }
            }
            
            if wordCardContent.shouldObtainAccent {
                if Variables.lang == LangCode.ja {
                    Word.makeJaTokensFor(jaWord: wordCardContent.word) { tokens in
                        if let updatedWord = self.words.updateWord(of: wordCardContent.word.id, newTokens: tokens) {
                            let newTitle: String = self.makeWordCardTitle(word: updatedWord)
                            self.wordCardEntries[index].title = newTitle
                        }
                    }
                }
                if Variables.lang == LangCode.ru {
                    Word.makeRuTokensFor(ruWord: wordCardContent.word) { tokens in
                        if let updatedWord = self.words.updateWord(of: wordCardContent.word.id, newTokens: tokens) {
                            let newTitle: String = self.makeWordCardTitle(word: updatedWord)
                            self.wordCardEntries[index].title = newTitle
                        }
                    }
                }
            }
        }
    }
}

extension HomeViewController {
    
    private func makeLang2rid(from requests: [UNNotificationRequest]) -> [String: [String]] {
        var lang2rid: [String: [String]] = [:]
        for learningLang in self.learningLangs {
            lang2rid[learningLang] = []
        }
        for request in requests {
            print("title:", request.content.title)
            print("body:", request.content.body)
            
            let rid = request.identifier
            let langCode = rid.split(with: Constants.notificationRequestIdentifierSeparator)[0]
            lang2rid[langCode]!.append(rid)
        }
        
        return lang2rid
    }
    
    private var maxRequestPerLang: Int {
        64 / self.learningLangs.count  // 64: max pending request num.
    }
    
    private func makeWordCardIdentifier(lang: String, triggerDateComponents: DateComponents) -> String {
        "\(lang):" + "\(triggerDateComponents.year!)\(triggerDateComponents.month!)\(triggerDateComponents.day!)\(triggerDateComponents.hour!)"
    }
    
    private func addIcon(of langCode: String, to title: String) -> String {
        return "\(LangCode.toFlagIcon(langCode: langCode)) \(title)"
    }
    
    private func generateWordcardNotifications() {
        
        // https://stackoverflow.com/questions/40270598/ios-10-how-to-view-a-list-of-pending-notifications-using-unusernotificationcente
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getPendingNotificationRequests { requests in
            var lang2rid: [String: [String]] = self.makeLang2rid(from: requests)
            print("Before:", lang2rid)
            
            // Create word cards for 10-22.
            for day in Date().nextNDays(n: 3) {
                for hour in 10...22 {
                    if lang2rid[self.lang]!.count >= self.maxRequestPerLang {
                        // Cannot be outside the loops
                        // as new notifications will be added inside the loops.
                        continue
                    }
                    
                    let triggerDateComponents = DateComponents(
                        year: day.get(.year),
                        month: day.get(.month),
                        day: day.get(.day),
                        hour: hour
                    )
                    if let triggerDate = Date.fromComponents(components: triggerDateComponents), triggerDate < Date() {
                        continue
                    }
                    
                    let identifier = self.makeWordCardIdentifier(lang: self.lang, triggerDateComponents: triggerDateComponents)
                    if lang2rid[self.lang]!.contains(identifier) {
                        continue
                    }
                    
                    guard let wordCardEntry = self.wordCardEntries.popLast() else {
                        continue
                    }
                    
                    let title: String = self.addIcon(of: self.lang, to: wordCardEntry.title)
                    let body: String = wordCardEntry.body
                    
                    print("Adding a word card.")
                    print("  [title] \(title)")
                    print("  [body] \(body)")
                    print("  [trigger date components] \(triggerDateComponents)")
                    print("  [identifier] \(identifier)")
                    let notificationRequest = makeNotificationRequest(
                        title: title,
                        body: body,
                        triggerDateComponents: triggerDateComponents,
                        identifier: identifier
                    )
                    notificationCenter.add(notificationRequest)
                    lang2rid[self.lang]!.append(identifier)
                }
            }
            
            print("After:", lang2rid)
        }
    }
    
}
