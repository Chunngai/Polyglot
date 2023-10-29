//
//  NewHomeViewController.swift
//  Polyglot
//
//  Created by Ho on 9/28/23.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit
import SnapKit
import MessageUI

struct HomeItem: Hashable {
    
    let identifier = UUID()

    let image: UIImage?
    
    let text: String?
    let secondaryText: String?
    
    let header: String?
    let lang: String?
    let words: [String]?
    let meanings: [String]?
    let pronunciations: [String]?
    let content: String?
    let contentSource: ContentCard.ContentSource?
    
    init(
        image: UIImage? = nil, 
        text: String? = nil, secondaryText: String? = nil,
        header: String? = nil, lang: String? = nil, words: [String]? = nil, meanings: [String]? = nil, pronunciations: [String]? = nil, content: String? = nil, contentSource: ContentCard.ContentSource? = nil
    ) {
        self.image = image
        
        self.text = text
        self.secondaryText = secondaryText
        
        self.header = header
        self.lang = lang
        self.words = words
        self.meanings = meanings
        self.pronunciations = pronunciations
        self.content = content
        self.contentSource = contentSource
    }
}

class HomeViewController: UIViewController {
    
    // Langauges.
    
    var learningLangs: [String] = {
        var learningLanguages = LangCode.loadLearningLanguages()
        return learningLanguages
    }()
    
    var lang: String! {
        didSet {
            guard let lang = lang, Variables.lang != lang else {
                return
            }
            print("Updating lang to \(lang)")
            
            Variables.lang = lang
                        
            print("Resetting data.")
            self._words = nil
            self._articles = nil
            self._contentCards = nil
            
            self.wordMetaData = Word.loadMetaData(for: lang)
            self.articleMetaData = Article.loadMetaData(for: lang)
            self.contentCardMetaData = ContentCard.loadMetaData(for: lang)
            
            self.contentCreator = ContentCreator(lang: lang)

            self.updateTexts()
        }
    }
    
    // Collection view.
    
    var dataSource: UICollectionViewDiffableDataSource<Int, HomeItem>!
    
    let languageItems = LangCode.loadLearningLanguages().map { langCode in
        return HomeItem(
            image: Images.langImages[langCode], 
            text: LangCode.toFlagIcon(langCode: langCode)
        )
    }
    
    var languageOfTextToDisplay: String {
        if self.lang != nil {
            return self.lang
        } else {
            if !learningLangs.isEmpty {
                return learningLangs[0]
            } else {
                // Default val.
                return LangCode.en
            }
        }
    }
    var listItems: [HomeItem] {[
        HomeItem(
            image: UIImage.init(systemName: "list.bullet"),
            text: Strings._phrases[languageOfTextToDisplay],
            secondaryText: wordMetaData?["count"]
        ),
        HomeItem(
            image: UIImage.init(systemName: "books.vertical"),
            text: Strings._articles[languageOfTextToDisplay],
            secondaryText: articleMetaData?["count"]
        )
    ]}
    
    var practiceItems: [HomeItem] {[
        HomeItem(
            image: UIImage.init(systemName: "square.and.pencil"),
            text: Strings._phraseReview[languageOfTextToDisplay]
        ),
        HomeItem(
            image: UIImage.init(systemName: "doc"),
            text: Strings._reading[languageOfTextToDisplay]
        ),
        HomeItem(
            image: UIImage.init(systemName: "bubble"),
            text: Strings._interpretation[languageOfTextToDisplay]
        )
    ]}
    
    // Content cards.
    
    var contentCreator: ContentCreator!
    
    var contentCardsOfTheDay: [(
        dateString: String,
        contentCards: [ContentCard]
    )]!
    
    private var shouldUpdateContentCardsOfTheDay: Bool {
        if self.contentCardsOfTheDay == nil {
            return true
        }
        if self.contentCardsOfTheDay.isEmpty {
            return true
        }
        if contentCardsOfTheDay[0].dateString != Date().repr(of: ContentCard.dateRepr) {
            return true
        }
        return false
    }
    
    // MARK: - Models
    
    private var _words: [Word]!
    private var _wordCount: Int!
    var words: [Word]! {
        get {
            if self._words == nil {
                print("Reading words.")
                self._words = Word.load(for: self.lang)
                self._wordCount = self._words.count
            }
            
            return self._words
        }
        set {
            guard var newValue = newValue else {
                return
            }
            self._words = newValue  // !
            
            guard abs(newValue.count - _wordCount) <= 30 else {
                return
            }
            print("Word count: \(_wordCount ?? -1) -> \(newValue.count)")
            _wordCount = newValue.count
            
            Word.save(&newValue, for: self.lang)
            
            wordMetaData["count"] = String(newValue.count)
            DispatchQueue.main.async {  // May be called by the accent retrieving in a closure.
                self.updateTexts()
            }
        }
    }
    
    private var _articles: [Article]!
    private var _articleCount: Int!
    var articles: [Article]! {
        get {
            if self._articles == nil {
                print("Reading articles.")
                self._articles = Article.load(for: self.lang)
                self._articleCount = self._articles.count
            }
            
            return self._articles
        }
        set {
            guard var newValue = newValue else {
                return
            }
            self._articles = newValue  // !
            
            guard abs(newValue.count - _articleCount) <= 3 else {
                return
            }
            print("Article count: \(_articleCount ?? -1) -> \(newValue.count)")
            _articleCount = newValue.count
            
            Article.save(&newValue, for: self.lang)
            
            articleMetaData["count"] = String(newValue.count)
            DispatchQueue.main.async {  // May be called by the accent retrieving in a closure.
                self.updateTexts()
            }
        }
    }
    
    private var _contentCards: [ContentCard]!
    private var _contentCardCount: Int!
    var contentCards: [ContentCard]! {
        get {
            if self._contentCards == nil {
                print("Reading content cards.")
                self._contentCards = ContentCard.load(for: self.lang)
                self._contentCardCount = self._contentCards.count
            }
            
            return self._contentCards
        }
        set {
            guard var newValue = newValue else {
                return
            }
            self._contentCards = newValue  // !
            
            guard abs(newValue.count - _contentCardCount) <= 3 else {
                return
            }
            print("Card count: \(_contentCardCount ?? -1) -> \(newValue.count)")
            _contentCardCount = newValue.count
            
            ContentCard.save(&newValue, for: self.lang)
            
            contentCardMetaData["count"] = String(newValue.count)
            DispatchQueue.main.async {
                self.updateTexts()
            }
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
    var contentCardMetaData: [String:String]! {
        didSet {
            ContentCard.saveMetaData(&contentCardMetaData, for: self.lang)
        }
    }
    
    // MARK: - Controllers
    
    // MARK: - Views
    
    var collectionView: UICollectionView!

    // MARK: - Init
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        DispatchQueue.global(qos: .userInitiated).async {
            if self.shouldUpdateContentCardsOfTheDay {
                self.updateContentCardsOfTheDay()
            }
            self.displayContentCardsOfTheDay()
        }
    }
    
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
        
        // https://stackoverflow.com/questions/41393754/call-a-uiviewcontroller-method-when-application-goes-background-and-come-to-fore
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appMovedToForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    private func updateViews() {
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.title = Strings._homeTitles[learningLangs[0]]
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage.init(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(emailAnCopy)
        )
    }
    
    private func updateLayouts() {
        
    }
}

extension HomeViewController {
    
    // MARK: - Selectors
    
    @objc private func appMovedToForeground() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.shouldUpdateContentCardsOfTheDay {
                self.updateContentCardsOfTheDay()
            }
            self.displayContentCardsOfTheDay()
        }
    }
    
    @objc private func emailAnCopy() {
        guard MFMailComposeViewController.canSendMail() else {
            // Handle the case where the device can't send emails, e.g., display an alert.
            print("Cannot send email.")
            return
        }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        
        var fileNames: [String] = []
        for learningLang in self.learningLangs {
            fileNames.append(Word.fileName(for: learningLang))
            fileNames.append(Article.fileName(for: learningLang))
        }
        
        for fileName in fileNames {
            
            if let fileURL = try? constructFileUrl(
                from: fileName,
                create: false
            ) {
                if let data = try? Data(contentsOf: fileURL) {
                    mailComposer.addAttachmentData(
                        data,
                        mimeType: "application/json",
                        fileName: fileName
                    )
                } else {
                    // Handle the case where reading the file data failed.
                    print("Failed to read data from \(fileName)")
                    return
                }
            } else {
                // Handle any errors related to constructing the file URL
                print("Filed to construct URL for \(fileName)")
                return
            }
            
        }
        
        mailComposer.setToRecipients([Config.defaultEmail])
        mailComposer.setSubject("Data Copy \(Date().repr())")
        mailComposer.setMessageBody("", isHTML: false)
        
        // Present the mail composer view controller
        self.present(mailComposer, animated: true, completion: nil)
        
    }
}

extension HomeViewController {
    
    // MARK: - Content Cards
    
    private func updateContentCardsOfTheDay() {
        var dateStringToContentCards: [String: [ContentCard]] = [:]
        for lang in self.learningLangs {
            for contentCard in ContentCard.load(for: lang) {
                if Calendar.current.isDate(
                    contentCard.date,
                    inSameDayAs: Date()
                ) {
                    let dateString = contentCard.date.repr(of: ContentCard.dateRepr)
                    
                    dateStringToContentCards.setDefault(
                        value: [],
                        for: dateString
                    )
                    dateStringToContentCards[dateString]!.append(contentCard)
                }
            }
        }
        
        self.contentCardsOfTheDay = dateStringToContentCards.map {(
            dateString: $0,
            contentCards: $1
        )}.sorted { $0.dateString > $1.dateString }
    }
    
    private func displayContentCardsOfTheDay() {
        var sections: [(
            header: HomeItem,
            items: [HomeItem]
        )] = []
        for (dateString, contentCards) in contentCardsOfTheDay {
            guard let hourOfDateString = Int(dateString.split(with: ":")[0]) else {
                continue
            }
            guard let hourOfNow = Int(Date().repr(of: ContentCard.dateRepr).split(with: ":")[0]) else {
                continue
            }
            if hourOfDateString > hourOfNow {
                continue
            }
            
            var items: [HomeItem] = []
            for contentCard in contentCards {
                if contentCard.content.isEmpty {
                    continue
                }
                
                items.append(HomeItem(
                    lang: contentCard.lang,
                    words: contentCard.words,
                    meanings: contentCard.meanings,
                    pronunciations: contentCard.pronunciations,
                    content: contentCard.content,
                    contentSource: contentCard.contentSource
                ))
            }
            if !items.isEmpty {
                sections.append((
                    header: HomeItem(header: dateString),
                    items: items
                ))
            }
        }
        
        for (i, section) in sections.enumerated() {
            var sectionSnapShot = NSDiffableDataSourceSectionSnapshot<HomeItem>()
            
            sectionSnapShot.append([section.header])
            sectionSnapShot.append(section.items)
            // sectionSnapShot.expand([headerItem])
            
            DispatchQueue.main.async {
                self.dataSource.apply(sectionSnapShot, to: i + 3)
            }
        }
    }
    
    private func generateContentCards() {
        let now = Date()
        
        var date2indexForContentCardsAfterNow: [Date: Int] = [:]
        for (i, contentCard) in self.contentCards.enumerated() {
            if contentCard.date >= now {
                date2indexForContentCardsAfterNow[contentCard.date] = i
            }
        }
        
        for day in now.nextNDays(n: 3) {
        hourLoop: for hour in 10...22 {
            let dateComponents = DateComponents(
                year: day.get(.year),
                month: day.get(.month),
                day: day.get(.day),
                hour: hour
            )
            guard let date = Date.fromComponents(components: dateComponents) else {
                continue
            }
            
            if date < now {
                continue
            }
            
            for (dateOfContentCardAfterNow, indexOfContentCardAfterNow) in date2indexForContentCardsAfterNow {
                if dateOfContentCardAfterNow == date {  // A content card for the date has been generated.
                    guard indexOfContentCardAfterNow < self.contentCards.count else {  // Index out of range when quickly switching languages.
                        continue hourLoop
                    }
                    let contentCard = self.contentCards[indexOfContentCardAfterNow]
                    if contentCard.contentSource == .chatgpt && contentCard.content.isEmpty {  // Content creation with chatgpt failed.
                        print("Re-creating the content for: \(contentCard)")
                        self.contentCreator.createContent(for: contentCard.words) { [langForContentCard = self.lang] (content: String?) in
                            guard self.lang == langForContentCard else {
                                return
                            }
                            guard let content = content else {
                                return
                            }
                            self.contentCards[indexOfContentCardAfterNow].content = content
                        }
                    }
                    
                    continue hourLoop
                }
            }
            
            print("Generating a content card for \(date)")
            
            // Generate a content card.
            if let randomWord = self.words.randomElement(),
               let randomPara = self.articles.paraCandidates(
                for: randomWord,
                shouldIgnoreCase: true
               ).randomElement(),
               let content = randomPara.text.components(from: Variables.tokenizerOfLang(of: .sentence))
                .first(where: { (sentence) -> Bool in
                    sentence.contains(randomWord.text)
                }) {
                
                // Obtain all words that are in the content.
                var containedWords: [Word] = [randomWord]
                for word in self.words {
                    if word.text.lowercased() != randomWord.text.lowercased()
                        && content.lowercased().contains(word.text.lowercased())
                        && !Tokens.wordsToFilterInContentCardGeneration.contains(word.text.lowercased()) {
                        containedWords.append(word)
                    }
                }
                
                // Ensure that the words in the content are really words
                // instead of substrings in certain words.
                // Note that the current solution cannot handle the situation where
                // e.g., 동의어 in 동의어를
                var pseudoWords: [Word] = []
                let contentWoPunct = content.removePunctuation()
                let lowercasedContentWords = contentWoPunct
                    .split(separator: Strings.wordSeparator)  // Don't use String.split(with:), it's not working properly with "" being the separator.
                    .map { $0.lowercased() }
                for containedWord in containedWords {
                    let containedWordWoPunct = containedWord.text.removePunctuation()
                    let lowercasedWordsInContainedWord = containedWordWoPunct
                        .split(separator: Strings.wordSeparator)
                        .map { $0.lowercased() }
                    if !lowercasedContentWords.contains(lowercasedWordsInContainedWord) {
                        pseudoWords.append(containedWord)
                        print("[x] Pseudo word \"\(containedWord.text)\" in \(content)")
                    }
                }
                
                // Resolve conflicted words.
                var conflictedWords: [Word] = []
                for longerWord in containedWords {
                    for shorterWord in containedWords {
                        if longerWord.text.lowercased() != shorterWord.text.lowercased()
                            && longerWord.text.lowercased().contains(shorterWord.text.lowercased()) {
                            conflictedWords.append(shorterWord)
                            print("[x] Confliction. \"\(longerWord.text.lowercased())\" contains \"\(shorterWord.text.lowercased())\"")
                        }
                    }
                }
                
                // Filtering.
                containedWords = containedWords.compactMap { word in
                    if word.text == randomWord.text {
                        return word
                    }
                    
                    if !pseudoWords.contains(word) && !conflictedWords.contains(word) {
                        return word
                    } else {
                        return nil
                    }
                }
                
                let contentCard = ContentCard(
                    date: date,
                    lang: self.lang,
                    words: containedWords.map{ $0.text },
                    meanings: containedWords.map{ $0.meaning },
                    pronunciations: containedWords.map{ $0.accentedPronunciation },
                    content: content,
                    contentSource: .articles
                )
                self.contentCards.append(contentCard)
                print("Generated: \(contentCard)")
                
                updateAccents(for: containedWords)
            } else {
                var randomWords: [Word] = []
                for _ in 0 ... 6 {
                    guard let randomWord = self.words.randomElement() else {
                        continue
                    }
                    if !randomWords.contains(randomWord) {
                        randomWords.append(randomWord)
                    }
                }
                
                var contentCardWords: [String] = []
                var contentCardMeanings: [String] = []
                var contentCardPronunciations: [String] = []
                for word in randomWords {
                    contentCardWords.append(word.text)
                    contentCardMeanings.append(word.meaning)
                    contentCardPronunciations.append(word.accentedPronunciation)
                }
                
                let contentCard = ContentCard(
                    date: date,
                    lang: self.lang,
                    words: contentCardWords,
                    meanings: contentCardMeanings,
                    pronunciations: contentCardPronunciations,
                    content: "",
                    contentSource: .chatgpt
                )
                self.contentCards.append(contentCard)
                print("Generated: \(contentCard)")
                
                self.contentCreator.createContent(for: randomWords.map{ $0.text }) { [
                    langForContentCard = self.lang,
                    contentCardId = contentCard.id
                ] (content: String?) in
                    guard self.lang == langForContentCard else {
                        return
                    }
                    guard let content = content else {
                        return
                    }
                    // TODO: - Improve here.
                    // Not working properly with count - 1?
                    for i in 0 ..< self.contentCards.count {
                        if self.contentCards[i].id == contentCardId {
                            self.contentCards[i].content = content
                            break
                        }
                    }
                }
                
                updateAccents(for: randomWords)
            }
        }
        }
    }
    
    private func updateAccents(for words: [Word]) {
        if self.lang == LangCode.ja {
            for word in words {
                if word.tokens == nil || JapaneseAccentAnalyzer.isOldAccents(word) {
                    JapaneseAccentAnalyzer.makeTokens(for: word) { tokens in
                        guard self.lang == LangCode.ja else {
                            return
                        }
                        self.words.updateWord(of: word.id, newTokens: tokens)
                    }
                }
            }
        }
        
        if self.lang == LangCode.ru {
            for word in words {
                if word.tokens == nil {
                    RussianAccentAnalyzer.makeTokens(for: word) { tokens in
                        guard self.lang == LangCode.ru else {
                            return
                        }
                        self.words.updateWord(of: word.id, newTokens: tokens)
                    }
                }
            }
        }
    }
    
}

extension HomeViewController {
    
    // MARK: - Utils
    
    private func updateTexts() {
        navigationItem.title = Strings.homeTitle
        
        var listsSnapshot = dataSource.snapshot(for: HomeViewController.listSection)
        listsSnapshot.deleteAll()
        listsSnapshot.append(listItems)
        dataSource.apply(
            listsSnapshot,
            to: HomeViewController.listSection,
            animatingDifferences: false
        )
        
        var practicesSnapShot = dataSource.snapshot(for: HomeViewController.practiceSection)
        practicesSnapShot.deleteAll()
        practicesSnapShot.append(practiceItems)
        dataSource.apply(
            practicesSnapShot,
            to: HomeViewController.practiceSection,
            animatingDifferences: false
        )
    }
}

extension HomeViewController: MFMailComposeViewControllerDelegate {
    
    // MARK: - MFMailCompose ViewController Delegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        
        switch result {
        case .sent:
            // Handle the email sent successfully
            print("Email sent successfully")
        case .saved:
            // Handle the email being saved as a draft
            print("Email saved as draft")
        case .cancelled:
            // Handle the user canceling the email composition
            print("Email composition canceled")
        case .failed:
            // Handle the case where the email failed to send
            if let error = error {
                print("Email send error: \(error.localizedDescription)")
            }
        @unknown default:
            break
        }
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
            
            let section: NSCollectionLayoutSection
            
            if sectionIndex == HomeViewController.languageSection {
                
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
            } else if sectionIndex == HomeViewController.listSection || sectionIndex == HomeViewController.practiceSection {
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
                // Cards.
                
                var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                configuration.headerMode = .firstItemInSection
                
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
            cell.contentConfiguration = content
            
            var background = UIBackgroundConfiguration.listPlainCell()
            background.cornerRadius = 8
            // https://www.appsloveworld.com/swift/100/44/how-change-the-selection-color-in-compositional-layouts-in-collectionview
            background.backgroundColorTransformer = UIConfigurationColorTransformer { color in
                // Set the selection color to white.
                return .white
            }

            if self.learningLangs[indexPath.row] == self.lang {
                background.strokeColor = .black
                background.strokeWidth = 2
            } else {
                background.strokeColor = .clear
                background.strokeWidth = .zero
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
            content.textProperties.color = self.lang != nil ? Colors.normalTextColor : Colors.inactiveTextColor
            cell.contentConfiguration = content
            
            var background = UIBackgroundConfiguration.listPlainCell()
            // https://www.appsloveworld.com/swift/100/44/how-change-the-selection-color-in-compositional-layouts-in-collectionview
            background.backgroundColorTransformer = UIConfigurationColorTransformer { color in
                // Set the selection color to white.
                return .white
            }
            cell.backgroundConfiguration = background
            
            if indexPath.section == HomeViewController.listSection {
                cell.accessories = [UICellAccessory.disclosureIndicator()]
            } else {
                cell.accessories = []
            }
        }
    }
    
    func createCardHeaderRegistration() -> UICollectionView.CellRegistration<CardCell, HomeItem> {
        return UICollectionView.CellRegistration<CardCell, HomeItem> { (
            cell: CardCell,
            indexPath: IndexPath,
            item: HomeItem
        ) in
            
            let content = CardCellContentConfiguration()
            content.header = item.header
            cell.contentConfiguration = content
            
            let background = UIBackgroundConfiguration.listGroupedHeaderFooter()
            cell.backgroundConfiguration = background
        }
    }
    
    func createCardCellRegistration() -> UICollectionView.CellRegistration<CardCell, HomeItem> {
        return UICollectionView.CellRegistration<CardCell, HomeItem> { (
            cell: CardCell,
            indexPath: IndexPath,
            item: HomeItem
        ) in
            
            let content = CardCellContentConfiguration()
            content.lang = item.lang
            content.words = item.words
            content.meanings = item.meanings
            content.pronunciations = item.pronunciations
            content.content = item.content
            content.contentSource = item.contentSource
            cell.contentConfiguration = content
                 
            var background = UIBackgroundConfiguration.listPlainCell()
            // https://www.appsloveworld.com/swift/100/44/how-change-the-selection-color-in-compositional-layouts-in-collectionview
            background.backgroundColorTransformer = UIConfigurationColorTransformer { color in
                // Set the selection color to white.
                return .white
            }
            cell.backgroundConfiguration = background
        }
    }
    
    func configureDataSource() {
        let gridCellRegistration = createGridCellRegistration()
        let listCellRegistration = createListCellRegistration()
        let cardHeaderRegistration = createCardHeaderRegistration()
        let cardCellRegistration = createCardCellRegistration()
        
        dataSource = UICollectionViewDiffableDataSource<Int, HomeItem>(collectionView: collectionView) {
            (collectionView, indexPath, item) -> UICollectionViewCell? in
            
            let section = indexPath.section
            
            if section == HomeViewController.languageSection {
                return collectionView.dequeueConfiguredReusableCell(
                    using: gridCellRegistration,
                    for: indexPath,
                    item: item
                )
            } else if section == HomeViewController.listSection {
                return collectionView.dequeueConfiguredReusableCell(
                    using: listCellRegistration,
                    for: indexPath,
                    item: item
                )
            } else if section == HomeViewController.practiceSection {
                return collectionView.dequeueConfiguredReusableCell(
                    using: listCellRegistration,
                    for: indexPath,
                    item: item
                )
            } else {
                let registration: UICollectionView.CellRegistration<CardCell, HomeItem>
                if indexPath.row == 0 {
                    registration = cardHeaderRegistration
                } else {
                    registration = cardCellRegistration
                }
                return collectionView.dequeueConfiguredReusableCell(
                    using: registration,
                    for: indexPath,
                    item: item
                )
            }
        }
    }
    
    func applyInitialSnapshots() {

        let sections: [Int] = [
            HomeViewController.languageSection,
            HomeViewController.listSection,
            HomeViewController.practiceSection,
        ]
        var snapshot = NSDiffableDataSourceSnapshot<Int, HomeItem>()
        snapshot.appendSections(sections)
        dataSource.apply(snapshot, animatingDifferences: false)
            
        var languagesSnapShot = NSDiffableDataSourceSectionSnapshot<HomeItem>()
        languagesSnapShot.append(languageItems)
        dataSource.apply(
            languagesSnapShot,
            to: HomeViewController.languageSection,
            animatingDifferences: false
        )
        
        var listsSnapshot = NSDiffableDataSourceSectionSnapshot<HomeItem>()
        listsSnapshot.append(listItems)
        dataSource.apply(
            listsSnapshot,
            to: HomeViewController.listSection,
            animatingDifferences: false
        )
        
        var practicesSnapShot = NSDiffableDataSourceSectionSnapshot<HomeItem>()
        practicesSnapShot.append(practiceItems)
        dataSource.apply(
            practicesSnapShot,
            to: HomeViewController.practiceSection,
            animatingDifferences: false
        )
    }
}

extension HomeViewController: UICollectionViewDelegate {
    
    // MARK: - UICollectionView Delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }
        
        let section = indexPath.section
        let row = indexPath.row
        
        Feedbacks.defaultFeedbackGenerator.selectionChanged()
        
        if section == HomeViewController.languageSection {
            
            cell.backgroundConfiguration?.strokeColor = .black
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
            
        } else if section == HomeViewController.listSection {
                    
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
            
            // Generate content cards here.
            DispatchQueue.global(qos: .userInitiated).async {
                self.generateContentCards()
            }
            
        } else if section == HomeViewController.practiceSection {
            
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
        } else {
            if let cell = cell as? CardCell,
                let configuration = cell.contentConfiguration as? CardCellContentConfiguration {
                
                configuration.shouldDisplayMeanings.toggle()
                cell.contentConfiguration = configuration
                
                collectionView.performBatchUpdates(nil, completion: nil)  // For updating the cell height.
            }
        }
    }
}

extension HomeViewController {
    
    // MARK: - Constants
    
    static let languageSection: Int = 0
    static let listSection: Int = 1
    static let practiceSection: Int = 2
    
}
