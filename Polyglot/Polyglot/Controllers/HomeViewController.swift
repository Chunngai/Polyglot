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
import Alamofire
import AVFoundation

struct HomeItem: Hashable {
    
    let identifier = UUID()

    let image: UIImage?
    let text: String?
    let secondaryText: String?
    let trinaryText: String?
    
    let header: String?
    let lang: LangCode?
    let words: [String]?
    let meanings: [String]?
    let pronunciations: [String]?
    let content: String?
    let contentSource: String?
    
    init(
        image: UIImage? = nil, text: String? = nil, secondaryText: String? = nil, trinaryText: String? = nil,
        header: String? = nil, lang: LangCode? = nil, words: [String]? = nil, meanings: [String]? = nil, pronunciations: [String]? = nil, content: String? = nil, contentSource: String? = nil
    ) {
        self.image = image
        self.text = text
        self.secondaryText = secondaryText
        self.trinaryText = trinaryText
        
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
    
    // MARK: - Top View
    
    var homeScreenTitle: String? {
        Strings.languageNamesOfAllLanguages[LangCode.currentLanguage]?[LangCode.currentLanguage]
    }
    
    var topViewImageScale: CGFloat = HomeViewController.topViewGreatestImageScale
    
    var isScrollViewInitialized = false
    
    // MARK: - Practices
    
    var shouldAddArticle: Bool {
        guard let newestCDateString = articleMetaData["newestCDate"],
              let newestCDate = Date.from(
                string: newestCDateString,
                of: Date.defaultDateFormatter
              )
        else {
            return false
        }
        
        let difference = Calendar.current.dateComponents(
            [.day],
            from: newestCDate,
            to: Date()
        )
        if let days = difference.day, days > 7 {
            return true
        } else {
            return false
        }
    }

    var isVideoShadowingPracticeEnabled: Bool {
        guard
            let videoCountString = articleMetaData["video_count"],
            let videoCount = Int(videoCountString)
        else {
            return false
        }
        if videoCount == 0 {
            return false
        }
        return true
    }
    
    var isPracticeEnabled: Bool {
        let wordCount = Int(wordMetaData["count"] ?? "0")
        let articleCount = Int(articleMetaData["count"] ?? "0")
        if wordCount == 0 || articleCount == 0 {
            return false
        }
        return true
    }

    var wordPracticeCounter: [String: Int] = WordPracticeProducer.countWordPractices(for: LangCode.currentLanguage)
    var isWordPracticeEnabled: Bool {
        return !wordPracticeCounter.isEmpty
    }
    
    // MARK: - Collection view.
    
    var dataSource: UICollectionViewDiffableDataSource<Int, HomeItem>!
    
    var listItems: [HomeItem] {[
        HomeItem(
            image: Images.wordsImage,
            text: Strings.phrases,
            trinaryText: wordMetaData["count"]
        ),
        HomeItem(
            image: Images.articlesImage,
            text: Strings.articles,
            secondaryText: shouldAddArticle && LangCode.currentLanguage.configs.shouldRemindToAddNewArticles ? "⚠︎ \(Strings.articleAdding)" : nil,
            trinaryText: articleMetaData["count"]
        )
    ]}
    
    var phraseReviewItems: [HomeItem] {[
        HomeItem(
            image: Images.wordPracticeImage,
            text: Strings.phraseReview,
            secondaryText: {

                let nWordsToReview = wordPracticeCounter.count
                if nWordsToReview == 0 {
                    return Strings.noPhraseToReview
                }
                                
                var nWordPractices = 0
                for count in wordPracticeCounter.values {
                    nWordPractices += count
                }
                
                var s = Strings.nPhrasesToReview.replacingOccurrences(
                    of: "#",
                    with: String(nWordsToReview)
                )
                if nWordsToReview != 0 {
                    s += " (\(nWordPractices) \(Strings.practices))"
                }
                
                return s
            }()
        )
    ]}
    
    var shadowingItems: [HomeItem] {[
        HomeItem(
            image: Images.listeningPracticeImage,
            text: Strings.textShadowing,
            secondaryText: practiceMetaData["recentListeningPracticeDate"] != nil
            ? "\(Strings.recentPractice): \(practiceMetaData["recentListeningPracticeDate"]!)"
            : nil
        ),
        HomeItem(
            image: Images.videoShadowingPracticeImage,
            text: Strings.videoShadowing,
            secondaryText: practiceMetaData["recentVideoShadowingPracticeDate"] != nil
            ? "\(Strings.recentPractice): \(practiceMetaData["recentVideoShadowingPracticeDate"]!)"
            : nil
        )
    ]}
    
    var practiceItems: [HomeItem] {[
        HomeItem(
            image: Images.translationPracticeImage,
            text: Strings.speaking,
            secondaryText: practiceMetaData["recentTranslationPracticeDate"] != nil
            ? "\(Strings.recentPractice): \(practiceMetaData["recentTranslationPracticeDate"]!)"
            : nil
        ),
        HomeItem(
            image: Images.readingPracticeImage,
            text: Strings.reading,
            secondaryText: practiceMetaData["recentReadingPracticeDate"] != nil
            ? "\(Strings.recentPractice): \(practiceMetaData["recentReadingPracticeDate"]!)"
            : nil
        ),
        HomeItem(
            image: Images.podcastPracticeImage,
            text: Strings.podcast,
            secondaryText: practiceMetaData["recentPodcastPracticeDate"] != nil
            ? "\(Strings.recentPractice): \(practiceMetaData["recentPodcastPracticeDate"]!)"
            : nil
        )
    ]}
    
    var settingsItem: HomeItem {
        HomeItem(
            image: Images.configImage,
            text: Strings.configurations
        )
    }
    
    // MARK: - Models
    
    private var _words: [Word]!
    var words: [Word]! {
        get {
            if self._words == nil {
                print("Reading words.")
                self._words = Word.load(for: LangCode.currentLanguage)
            }
            
            return self._words
        }
        set {
            guard var newValue = newValue else {
                return
            }
            self._words = newValue
            Word.save(&newValue, for: LangCode.currentLanguage)
            
            wordMetaData["count"] = String(newValue.count)
        }
    }
    
    private var _articles: [Article]!
    var articles: [Article]! {
        get {
            if self._articles == nil {
                print("Reading articles.")
                self._articles = Article.load(for: LangCode.currentLanguage)
            }
            
            return self._articles
        }
        set {
            guard var newValue = newValue else {
                return
            }
            self._articles = newValue
            Article.save(&newValue, for: LangCode.currentLanguage)
            
            articleMetaData["count"] = String(newValue.count)
            articleMetaData["video_count"] = String(articles.compactMap({
                $0.isYoutubeVideo ? 1 : nil
            }).count)
            articleMetaData["newestCDate"] = newValue.map({ article in
                article.cDate
            }).max()?.repr(from: Date.defaultDateFormatter)
        }
    }
    
    var shouldNotApplySnapshotsInArticleMetaDataDidSet = false
    
    var wordMetaData: [String:String] = Word.loadMetaData(for: LangCode.currentLanguage) {
        didSet {
            Word.saveMetaData(
                &wordMetaData, 
                for: LangCode.currentLanguage
            )
            DispatchQueue.main.async {  // May be called by the accent retrieving in a closure.
                self.applySnapShots()
            }
        }
    }
    var articleMetaData: [String:String] = Article.loadMetaData(for: LangCode.currentLanguage) {
        didSet {
            Article.saveMetaData(
                &articleMetaData,
                for: LangCode.currentLanguage
            )
            if !shouldNotApplySnapshotsInArticleMetaDataDidSet {
                DispatchQueue.main.async {  // May be called by the accent retrieving in a closure.
                    self.applySnapShots()
                }
            }
        }
    }
    var practiceMetaData: [String:String] = BasePracticeProducer.loadMetaData(for: LangCode.currentLanguage) {
        didSet {
            BasePracticeProducer.saveMetaData(
                &practiceMetaData,
                for: LangCode.currentLanguage
            )
            applySnapShots()
        }
    }
    
    var contentCards: ContentCards!
    var contentCardSnapshots: [String: [
        Int: NSDiffableDataSourceSectionSnapshot<HomeItem>
    ]] = [
        "sentences": [:],
//        "paragraphs": [:],
    ]
    
    // MARK: - CardCell Delegate
    
    // Ref: https://stackoverflow.com/questions/73706115/avspeechsynthesizer-isnt-working-under-ios16-anymore
    var synthesizer = AVSpeechSynthesizer()
    
    var indexPath2TranslationForCellsThatAreDisplayingMeanings: [IndexPath: String] = [:]
    var indexPathForCellThatIsProcudingVoice: IndexPath? = nil
            
    // MARK: - Views
    
    lazy var topView: HomeScreenTopView = {
        let topView = HomeScreenTopView()
        topView.backgroundColor = self.collectionView.backgroundColor
        topView.imageView.image = Images.langImage.scale(to: Self.topViewGreatestImageScale)
        topView.languageLabel.text = homeScreenTitle
        return topView
    }()
    
    var collectionView: UICollectionView!

    // MARK: - Init
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        DispatchQueue.global(qos: .userInitiated).async {
            self.displayContentCards()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.isHidden = true
        UIApplication.shared.statusBarUIView?.backgroundColor = .systemGroupedBackground
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.navigationBar.isHidden = false
        UIApplication.shared.statusBarUIView?.backgroundColor = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
//        uploadFilesToServer()
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    private func updateSetups() {
        // Set up the collection view.
        configureHierarchy()
        configureDataSource()
        applyInitialSnapshots()

        // https://stackoverflow.com/questions/55382533/how-to-observe-the-value-of-a-global-variable-and-act-on-a-change-within-the-vie
        NotificationCenter.default.addObserver(
            forName: .wordPracticeCounterUpdated, 
            object: nil, 
            queue: .main
        ) { notification in
           
            guard 
                let lang = notification.userInfo?["lang"] as? LangCode,
                lang == LangCode.currentLanguage
            else {
                return
            }

            if let wordCountPractice = notification.userInfo?["wordPracticeCounter"] as? [String: Int] {
                self.wordPracticeCounter = wordCountPractice
                self.applySnapShots()
            }
           
        }
        // https://stackoverflow.com/questions/41393754/call-a-uiviewcontroller-method-when-application-goes-background-and-come-to-fore
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appMovedToForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        synthesizer.delegate = self
        topView.delegate = self
        
    }
    
    private func updateViews() {
        
        navigationItem.title = homeScreenTitle
        
        view.addSubview(topView)
        
    }
    
    private func updateLayouts() {
        topView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().offset(UIApplication.shared.statusBarFrame.maxY)
            make.height.equalTo(Self.topViewInitialHeight)
        }
    }
}

extension HomeViewController {
    
    // MARK: - Selectors
    
    @objc private func appMovedToForeground() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.displayContentCards()
        }
    }
    
}

extension HomeViewController {
    
    // MARK: - Content Cards
    
    private func generateContentCardSnapshots() {
        
        for hour in 0...23 {
            
            var sentenceItems:[HomeItem] = []
            for lang in LangCode.learningLanguages {
                guard let entry = contentCards.sentences[hour]?[lang.rawValue] else {
                    continue
                }
                guard let content = entry.content, !content.isEmpty else {
                    continue
                }
                sentenceItems.append(HomeItem(
                    lang: lang,
                    words: [entry.word!.text!],
                    meanings: [entry.word!.meaning!],
                    pronunciations: [entry.word!.pronunciation!],
                    content: content,
                    contentSource: entry.source
                ))
            }
            if !sentenceItems.isEmpty {
                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<HomeItem>()
                sectionSnapshot.append([HomeItem(header: "\(hour):00")])
                sectionSnapshot.append(sentenceItems)
                self.contentCardSnapshots["sentences"]![hour] = sectionSnapshot
            }
            
//            var paragraphItems: [HomeItem] = []
//            for lang in LangCode.learningLanguages {
//                guard let entry = contentCards.paragraphs[hour]?[lang.rawValue] else {
//                    continue
//                }
//                guard let content = entry.content, !content.isEmpty else {
//                    continue
//                }
//                
//                var allWords: [String] = []
//                var allMeanings: [String] = []
//                var allPronunciations: [String] = []
//                for (wordLang, wordEntries) in contentCards.words {
//                    if wordLang != lang.rawValue {
//                        continue
//                    }
//                    for wordEntry in wordEntries {
//                        allWords.append(wordEntry.text!)
//                        allMeanings.append(wordEntry.meaning!)
//                        allPronunciations.append(wordEntry.pronunciation!)
//                    }
//                }
//                
//                paragraphItems.append(HomeItem(
//                    lang: lang,
//                    words: allWords,
//                    meanings: allMeanings,
//                    pronunciations: allPronunciations,
//                    content: content,
//                    contentSource: "chatgpt"
//                ))
//            }
//            if !paragraphItems.isEmpty {
//                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<HomeItem>()
//                sectionSnapshot.append([HomeItem(header: "\(hour):00")])
//                sectionSnapshot.append(paragraphItems)
//                self.contentCardSnapshots["paragraphs"]![hour] = sectionSnapshot
//            }
        }
    }
    
    private func applyContentCardSnapshots() {
        let currentSectionIdentifiers = dataSource.snapshot().sectionIdentifiers
        
        for hour in 0...23 {
            guard let hourOfNow = Int(Date().repr(of: ContentCards.hourFormat)) else {
                continue
            }
            if hourOfNow < hour {
                continue
            }
            
            // Sentences.
            let sentenceSectionIdentifier = ContentCards.sentenceSectionIdentifier(for: hour)
            if currentSectionIdentifiers.contains(sentenceSectionIdentifier) {
                continue
            }
            guard let sentenceSnapShot = contentCardSnapshots["sentences"]![hour] else {
                continue
            }
            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    self.dataSource.apply(
                        sentenceSnapShot,
                        to: sentenceSectionIdentifier
                    )
                }
            }
            
            // Paragraphs.
//            let paragraphSectionIdentifier = ContentCards.paragraphSectionIdentifier(for: hour)
//            if currentSectionIdentifiers.contains(paragraphSectionIdentifier) {
//                continue
//            }
//            guard let paragraphSnapShot = contentCardSnapshots["paragraphs"]![hour] else {
//                continue
//            }
//            DispatchQueue.main.async {
//                UIView.performWithoutAnimation {
//                    self.dataSource.apply(
//                        paragraphSnapShot,
//                        to: paragraphSectionIdentifier
//                    )
//                }
//            }
        }
    }
    
    private func displayContentCards() {
        if contentCards == nil {
            contentCards = ContentCards.load()
        }
        // Date check.
        if contentCards.dateString != Date().repr(of: ContentCards.dateFormat) {
            ContentCards.fetchAndSave { contentCards in
                self.contentCards = contentCards
                self.generateContentCardSnapshots()
                self.applyContentCardSnapshots()
            }
        } else {
            self.generateContentCardSnapshots()
            self.applyContentCardSnapshots()
        }
    }
    
}

extension HomeViewController {
    
    // MARK: - Utils
    
    private func uploadFilesToServer() {
        let serverURL = "http://4o51096o21.zicp.vip/upload"
        let headers: HTTPHeaders = ["Content-Type": "multipart/form-data"]
        
        for fileName in Constants.filesToSend {
            AF.upload(  // TODO: - Cannot upload all files when using mobile data, but ok with wifi.
                multipartFormData: { multipartFormData in
                    if let fileURL = try? constructFileUrl(
                        from: fileName,
                        create: false
                    ) {
                        multipartFormData.append(
                            fileURL,
                            withName: "file",
                            fileName: fileURL.lastPathComponent,
                            mimeType: "text/json"
                        )
                    } else {
                        // Handle any errors related to constructing the file URL
                        print("Failed to construct URL for \(fileName)")
                    }
                },
                to: serverURL,
                method: .post,
                headers: headers
            ).response { response in
                switch response.result {
                case .success:
                    break
                case .failure(let error):
                    print("Error uploading \(fileName) \(error.errorDescription ?? "")")
                }
            }
        }
    }
}

extension HomeViewController: LanguageSelectionViewControllerDelegate {
    
    // MARK: - LanguageSelectionViewController Delegate
    
    func updateLanguage(as language: LangCode) {
        guard language != LangCode.currentLanguage else {
            return
        }
        print("Updating lang to \(language).")
        LangCode.currentLanguage = language
        
        print("Resetting data.")
        self._words = nil
        self._articles = nil
        self.wordMetaData = Word.loadMetaData(for: LangCode.currentLanguage)
        self.articleMetaData = Article.loadMetaData(for: LangCode.currentLanguage)
        self.practiceMetaData = BasePracticeProducer.loadMetaData(for: LangCode.currentLanguage)
        self.wordPracticeCounter = WordPracticeProducer.countWordPractices(for: LangCode.currentLanguage)
        
        self.topView.imageView.image = Images.langImage.scale(to: self.topViewImageScale)
        self.topView.languageLabel.text = homeScreenTitle
        self.topView.changeLanguageButton.setTitle(Strings.changeLanguage, for: .normal)
        // Scroll to top.
        self.collectionView.contentOffset.y = -collectionView.adjustedContentInset.top
        
        applySnapShots()
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
            
            if sectionIndex == HomeViewController.listSection ||
                sectionIndex == HomeViewController.phraseReviewSection ||
                sectionIndex == HomeViewController.shadowingSection ||
                sectionIndex == HomeViewController.practiceSection ||
                sectionIndex == HomeViewController.settingsSection {
                
                let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                
                section = NSCollectionLayoutSection.list(
                    using: configuration,
                    layoutEnvironment: layoutEnvironment
                )
                
                var top: CGFloat = 30
                // Set different content insets for the first section
                if sectionIndex == HomeViewController.listSection {
                    top = Self.topViewInitialHeight + 30
                }
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: top,
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
    
    func createListCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewListCell, HomeItem> {
        return UICollectionView.CellRegistration<UICollectionViewListCell, HomeItem> { (
            cell: UICollectionViewListCell,
            indexPath: IndexPath,
            item: HomeItem
        ) in
            
            var content: UIListContentConfiguration = UIListContentConfiguration.sidebarSubtitleCell()
            content.image = item.image
            content.text = item.text
            content.secondaryText = item.secondaryText
            content.textProperties.color = Colors.normalTextColor
            
            // Set fixed height for the cell
//            let fixedHeight: CGFloat = 60 // Set your desired height here
//            content.directionalLayoutMargins = NSDirectionalEdgeInsets(
//                top: (fixedHeight - content.textProperties.font.lineHeight) / 2,
//                leading: content.directionalLayoutMargins.leading,
//                bottom: (fixedHeight - content.textProperties.font.lineHeight) / 2,
//                trailing: content.directionalLayoutMargins.trailing
//            )
            
            // Add padding to the top and bottom of the cell
            content.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: 
                    content.secondaryTextProperties.font.lineHeight / 2
                + (
                    content.secondaryText == nil
                    ? content.secondaryTextProperties.font.lineHeight / 2
                    : 0
                ), // Increase top padding
                leading: content.directionalLayoutMargins.leading,
                bottom: 
                    content.secondaryTextProperties.font.lineHeight / 2
                + (
                    content.secondaryText == nil
                    ? content.secondaryTextProperties.font.lineHeight / 2
                    : 0
                ), // Increase bottom padding
                trailing: content.directionalLayoutMargins.trailing
            )
            
            if indexPath.section == HomeViewController.listSection && indexPath.row == 1 {
                content.secondaryTextProperties.color = .systemYellow  // Reminder for article adding.
            }
            if indexPath.section == HomeViewController.phraseReviewSection {
                content.textProperties.color = self.isWordPracticeEnabled ? Colors.normalTextColor : Colors.weakTextColor
            }
            if (indexPath.section == HomeViewController.shadowingSection && indexPath.row == 0)
                || indexPath.section == HomeViewController.practiceSection {
                content.textProperties.color = self.isPracticeEnabled ? Colors.normalTextColor : Colors.weakTextColor
            }
            if indexPath.section == Self.shadowingSection && indexPath.row == 1 {
                content.textProperties.color = self.isVideoShadowingPracticeEnabled ? Colors.normalTextColor : Colors.weakTextColor
            }
            cell.contentConfiguration = content
            
            var background = UIBackgroundConfiguration.listPlainCell()
            // https://www.appsloveworld.com/swift/100/44/how-change-the-selection-color-in-compositional-layouts-in-collectionview
            background.backgroundColorTransformer = UIConfigurationColorTransformer { color in
                // Set the selection color to white.
                return .white
            }
            cell.backgroundConfiguration = background
            
            var cellAccessories: [UICellAccessory] = []
            if indexPath.section == HomeViewController.listSection {
                cellAccessories.append(UICellAccessory.customView(configuration: .init(
                    customView: {
                        let trailingLabel = UILabel()
                        trailingLabel.text = item.trinaryText
                        trailingLabel.textColor = .lightGray
                        return trailingLabel
                    }(),
                    placement: .trailing(displayed: .always)
                )))
            }
            if indexPath.section == HomeViewController.listSection
                || indexPath.section == HomeViewController.settingsSection {
                cellAccessories.append(UICellAccessory.disclosureIndicator())
            }
            cell.accessories = cellAccessories
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
            content.indexPath = indexPath
            content.delegate = self
            content.isDisplayMeanings = self.indexPath2TranslationForCellsThatAreDisplayingMeanings.keys.contains(indexPath)
            content.isProducingVoice = self.indexPathForCellThatIsProcudingVoice == indexPath
            if let contentTranslation = self.indexPath2TranslationForCellsThatAreDisplayingMeanings[indexPath] {
                content.contentTranslation = contentTranslation
            }
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
        let listCellRegistration = createListCellRegistration()
        let cardHeaderRegistration = createCardHeaderRegistration()
        let cardCellRegistration = createCardCellRegistration()
        
        dataSource = UICollectionViewDiffableDataSource<Int, HomeItem>(collectionView: collectionView) {
            (collectionView, indexPath, item) -> UICollectionViewCell? in
            
            let section = indexPath.section
            
            if section == HomeViewController.listSection ||
                section == HomeViewController.phraseReviewSection ||
                section == HomeViewController.shadowingSection ||
                section == HomeViewController.practiceSection ||
                section == HomeViewController.settingsSection {
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
            HomeViewController.listSection,
            HomeViewController.phraseReviewSection,
            HomeViewController.shadowingSection,
            HomeViewController.practiceSection,
            HomeViewController.settingsSection
        ]
        var snapshot = NSDiffableDataSourceSnapshot<Int, HomeItem>()
        snapshot.appendSections(sections)
        dataSource.apply(snapshot, animatingDifferences: false)
            
        applySnapShots()
    }
    
    func applySnapShots() {
        for (section, items) in zip(
            [
                HomeViewController.listSection,
                HomeViewController.phraseReviewSection,
                HomeViewController.shadowingSection,
                HomeViewController.practiceSection,
                HomeViewController.settingsSection
            ],
            [
                listItems,
                phraseReviewItems,
                shadowingItems,
                practiceItems,
                [settingsItem]
            ]
        ) {
            var snapshot = dataSource.snapshot(for: section)
            snapshot.deleteAll()
            snapshot.append(items)
            dataSource.apply(
                snapshot,
                to: section,
                animatingDifferences: false
            )
        }
    }
}

extension HomeViewController: UICollectionViewDelegate {
    
    // MARK: - UICollectionView Delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let section = indexPath.section
        let row = indexPath.row
                
        if section == HomeViewController.listSection {
            
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
            
        } else if section == HomeViewController.phraseReviewSection {
            
            guard isWordPracticeEnabled else {
                return
            }
            
            let vc = WordsPracticeViewController()
            vc.practiceDuration = LangCode.currentLanguage.configs.phraseReviewPracticeDuration
            vc.delegate = self
            
            navigationController?.present(
                NavController(rootViewController: vc),
                animated: true,
                completion: nil
            )
            
        } else if section == HomeViewController.shadowingSection
                    || section == HomeViewController.practiceSection {
            
            var vc: PracticeViewController = PracticeViewController()
            if section == Self.shadowingSection {
                if row == 0 {
                    
                    guard isPracticeEnabled else {
                        return
                    }
                    
                    vc = ListeningPracticeViewController()
                    vc.practiceDuration = LangCode.currentLanguage.configs.listeningPracticeDuration
               } else if row == 1 {
                   
                   guard isVideoShadowingPracticeEnabled else {
                       return
                   }
                   
                   vc = VideoShadowingPracticeViewController()
                   vc.practiceDuration = LangCode.currentLanguage.configs.videoShadowingPracticeDuration
               }
            } else if section == Self.practiceSection {
                
                guard isPracticeEnabled else {
                    return
                }
                
                if row == 0 {
                    vc = TranslationPracticeViewController()
                    vc.practiceDuration = LangCode.currentLanguage.configs.speakingPracticeDuration
                } else if row == 1 {
                    vc = ReadingPracticeViewController()
                    vc.practiceDuration = LangCode.currentLanguage.configs.readingPracticeDuration
                } else if row == 2 {
                    vc = PodcastPracticeViewController()
                    vc.practiceDuration = LangCode.currentLanguage.configs.podcastPracticeDuration
                }
            }
                
            vc.delegate = self
            
            navigationController?.present(
                NavController(rootViewController: vc),
                animated: true,
                completion: nil
            )
            
        } else if section == HomeViewController.settingsSection {
            var hasDuolingoArticles: Bool = false
            for article in articles {
                if article.topic?.lowercased().strip() == "duolingo sentences" {
                    hasDuolingoArticles = true
                    break
                }
            }
            let settingsVC = LanguageSettingsViewController()
            settingsVC.hasDuolingoArticles = hasDuolingoArticles
            navigationController?.pushViewController(
                settingsVC,
                animated: true
            )
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        func topViewImageScale(for height: CGFloat) -> CGFloat {
            
            let scaleMin = Self.topViewSmallestImageScale
            let scaleMax = Self.topViewGreatestImageScale
            let hMin = Self.topViewSmallestHeight
            let hMax = Self.topViewInitialHeight
            let normalizedHeight = (height - hMin) / (hMax - hMin)
            let scale = scaleMin + (scaleMax - scaleMin) * normalizedHeight
            return scale
            
        }
        
        func topViewLabelAlpha(for contentOffset: CGFloat) -> CGFloat {
            
            let alphaMin: CGFloat = 0
            let alphaMax: CGFloat = 1
            let cMin = -scrollView.adjustedContentInset.top
            let cMax: CGFloat = Self.scrollViewMaxContentOffsetForHidingTopViewLanguageChangingButton
            let normalizedAlpha = (contentOffset - cMin) / (cMax - cMin)
            let alpha = alphaMin + (alphaMax - alphaMin) * normalizedAlpha
            return 1 - alpha
            
        }
        
        if !isScrollViewInitialized {
            isScrollViewInitialized = true
            return
        }
        
//        print("scrollView.contentOffset.y: \(scrollView.contentOffset.y)")
        
        var isTopBouncing = false
        if scrollView.contentOffset.y < -scrollView.adjustedContentInset.top {
//            print("isTopBouncing")
            isTopBouncing = true
        }
        
//        var isBottomBouncing = false
//        if scrollView.contentOffset.y > (
//            scrollView.contentSize.height
//            - scrollView.bounds.height
//            + scrollView.adjustedContentInset.bottom
//        ) {
//            // Bottom bouncing.
//            // https://stackoverflow.com/questions/20805214/how-to-detect-scrollview-bounce-ios
//            print("isBottomBouncing")
//            isBottomBouncing = true
//        }
        
        let offsetDiff = scrollView.adjustedContentInset.top + scrollView.contentOffset.y
//        print("offsetDiff: \(offsetDiff)")
        
        var languageViewNewHeight = Self.topViewInitialHeight - offsetDiff
        if isTopBouncing {
            languageViewNewHeight = Self.topViewInitialHeight
        }
//        if
//            isBottomBouncing,
//            let navBarHeight = navigationController?.navigationBar.frame.height,
//            languageViewNewHeight < navBarHeight
//        {
//            languageViewNewHeight = navBarHeight
//        }
        if languageViewNewHeight < Self.topViewSmallestHeight
        {
            languageViewNewHeight = Self.topViewSmallestHeight
        }
//        print("languageViewNewHeight: \(languageViewNewHeight)")
        
        topView.snp.updateConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().offset(UIApplication.shared.statusBarFrame.maxY)
            make.height.equalTo(languageViewNewHeight)
        }
        self.topViewImageScale = topViewImageScale(for: languageViewNewHeight)
        topView.imageView.image = Images.langImage.scale(to: self.topViewImageScale)
        topView.changeLanguageButton.alpha = topViewLabelAlpha(for: scrollView.contentOffset.y)
        view.layoutIfNeeded()
//        print("languageView.frame: \(topView.frame)")
//        print("---")
        
    }
    
}

extension HomeViewController: CardCellDelegate {
    
    // MARK: - Card Cell Delegate
    
    func updateCellHeight() {
        // Ref: https://stackoverflow.com/questions/14094684/avoid-animation-of-uicollectionview-after-reloaditemsatindexpaths
        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates(nil, completion: nil)  // For updating the cell height.
        }
    }
    
    func updateIndexPath2TranslationForCellsThatAreDisplayingMeanings(indexPath: IndexPath, isDisplayMeanings: Bool) {
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? CardCell,
              let config = cell.contentConfiguration as? CardCellContentConfiguration else {
            return
        }
        
        func updateConfig(with contentTranslation: String?) {
            config.contentTranslation = contentTranslation
            cell.contentConfiguration = config
            
            self.updateCellHeight()
        }
        
        if isDisplayMeanings {
            // Translation.
            MachineTranslator(
                srcLang: config.lang!,
                trgLang: LangCode.zh
            ).translate(query: config.content!) { translations, _ in
                guard let translation = translations.first else {
                    return
                }
                self.indexPath2TranslationForCellsThatAreDisplayingMeanings[indexPath] = translation
                DispatchQueue.main.async {
                    updateConfig(with: translation)
                }
            }
        } else {
            self.indexPath2TranslationForCellsThatAreDisplayingMeanings.removeValue(forKey: indexPath)
            updateConfig(with: nil)
        }
    }
    
    func updateConfigOfCurrentlyVoiceProducingItemToNotProducing() {
                
        let tmpIndexPathForCellThatIsProcudingVoice = self.indexPathForCellThatIsProcudingVoice
        // Should reset before the guard statement as
        // collectionView.cellForItem() will return nil if the cell is not in the screen!
        self.indexPathForCellThatIsProcudingVoice = nil
        
        guard let indexPathForCellThatIsProcudingVoice = tmpIndexPathForCellThatIsProcudingVoice,
//              let cell = dataSource.collectionView(collectionView, cellForItemAt: indexPathForCellThatIsProcudingVoice) as? CardCell,
              // DON'T USE THE CODE OF THE PREVIOUS LINE, AS IT WILL CALL createCardCellRegistration(),
              // WHICH CALLS apply() OF THE CELL CONTENT VIEW WHEN SCROLLING.
              // THIS MAKES THAT SOMETIMES THE BUTTON IMAGES CANNOT BA UPDATED
              // AND THAT IT REQUIRES collectionView.reloadData() TO MAKE THE UPDATE WORK
              // EACH TIME indexPathForCellThatIsProcudingVoice IS UPDATED.
              let cell = collectionView.cellForItem(at: indexPathForCellThatIsProcudingVoice) as? CardCell,  // NOTE THAT nil WILL BE RETURNED IF THE CELL IS NOT IN THE SCREEN!
              let config = cell.contentConfiguration as? CardCellContentConfiguration else {
            return
        }
        
        // Immediate content view update if the cell is in the screen.
        config.isProducingVoice = false
        cell.contentConfiguration = config
    }
}

extension HomeViewController: AVSpeechSynthesizerDelegate {
    
    // MARK: - AVSpeechSynthesizer Delegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.updateConfigOfCurrentlyVoiceProducingItemToNotProducing()
    }
}

extension HomeViewController: HomeScreenTopViewDelegate {
    
    func changeLanguage() {
        
        let vc = LanguageSelectionViewController()
        vc.delegate = self
        vc.langs = LangCode.learningLanguages
        vc.selectedLang = LangCode.currentLanguage
        navigationController?.pushViewController(
            vc,
            animated: true
        )
        
    }
    
    func openSettings() {
        let settingsVC = GlobalSettingsViewController()
        navigationController?.pushViewController(
            settingsVC,
            animated: true
        )
    }
    
}


extension HomeViewController {
    
    // MARK: - Constants
    
    static let listSection: Int = 0
    static let phraseReviewSection: Int = 1
    static let shadowingSection: Int = 2
    static let practiceSection: Int = 3
    static let settingsSection: Int = 4
    
    static let topViewInitialHeight: CGFloat = 130
    static let topViewSmallestHeight: CGFloat = 60
    static let topViewGreatestImageScale: CGFloat = 0.8
    static let topViewSmallestImageScale: CGFloat = 0.5
    static let scrollViewMaxContentOffsetForHidingTopViewLanguageChangingButton: CGFloat = -30
    
}
