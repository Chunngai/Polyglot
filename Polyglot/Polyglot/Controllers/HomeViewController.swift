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
    
    let header: String?
    let lang: LangCode?
    let words: [String]?
    let meanings: [String]?
    let pronunciations: [String]?
    let content: String?
    let contentSource: String?
    
    init(
        image: UIImage? = nil, text: String? = nil, secondaryText: String? = nil,
        header: String? = nil, lang: LangCode? = nil, words: [String]? = nil, meanings: [String]? = nil, pronunciations: [String]? = nil, content: String? = nil, contentSource: String? = nil
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
    
    // Collection view.
    
    var dataSource: UICollectionViewDiffableDataSource<Int, HomeItem>!
    
    var languageItem: HomeItem {
        HomeItem(
            image: Images.langImage.scaledToListIconSize(),
            text: Strings.languageNamesOfAllLanguages[LangCode.currentLanguage]![LangCode.currentLanguage]!
        )
    }
    
    var listItems: [HomeItem] {[
        HomeItem(
            image: Images.wordsImage,
            text: Strings.phrases,
            secondaryText: wordMetaData["count"]
        ),
        HomeItem(
            image: Images.articlesImage,
            text: Strings.articles,
            secondaryText: articleMetaData["count"]
        )
    ]}
    
    var practiceItems: [HomeItem] {[
        HomeItem(
            image: Images.wordPracticeImage,
            text: Strings.phraseReview,
            secondaryText: practiceMetaData["recentWordPracticeDate"] != nil
            ? "\(Strings.recentPractice): \(practiceMetaData["recentWordPracticeDate"]!)"
            : nil
        ),
        HomeItem(
            image: Images.listeningPracticeImage,
            text: Strings.listening,
            secondaryText: practiceMetaData["recentListeningPracticeDate"] != nil
            ? "\(Strings.recentPractice): \(practiceMetaData["recentListeningPracticeDate"]!)"
            : nil
        ),
        HomeItem(
            image: Images.translationPracticeImage,
            text: Strings.speaking,
            secondaryText: practiceMetaData["recentTranslationPracticeDate"] != nil
            ? "\(Strings.recentPractice): \(practiceMetaData["recentTranslationPracticeDate"]!)"
            : nil
        )
    ]}
    
    var isPracticeEnabled: Bool {
        let wordCount = Int(wordMetaData["count"] ?? "0")
        let articleCount = Int(articleMetaData["count"] ?? "0")
        if wordCount == 0 || articleCount == 0 {
            return false
        }
        return true
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
        }
    }
    
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
            DispatchQueue.main.async {  // May be called by the accent retrieving in a closure.
                self.applySnapShots()
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
    
    var collectionView: UICollectionView!

    // MARK: - Init
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        DispatchQueue.global(qos: .userInitiated).async {
            self.displayContentCards()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        uploadFilesToServer()
        
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
        
        synthesizer.delegate = self
    }
    
    private func updateViews() {
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.title = Strings.homeTitle
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )
    }
    
    private func updateLayouts() {
        
    }
}

extension HomeViewController {
    
    // MARK: - Selectors
    
    @objc
    private func settingsTapped() {
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(
            settingsVC,
            animated: true
        )
    }
    
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
                    print("Error uploading \(fileName): \(error)")
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
        
        navigationItem.title = Strings.homeTitle
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
            
            if sectionIndex == HomeViewController.languageSection ||
                sectionIndex == HomeViewController.listSection ||
                sectionIndex == HomeViewController.practiceSection {
                
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
    
    func createListCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewListCell, HomeItem> {
        return UICollectionView.CellRegistration<UICollectionViewListCell, HomeItem> { (
            cell: UICollectionViewListCell,
            indexPath: IndexPath,
            item: HomeItem
        ) in
            
            var content: UIListContentConfiguration
            if indexPath.section == HomeViewController.listSection {
                content = UIListContentConfiguration.valueCell()
            } else {
                content = UIListContentConfiguration.sidebarSubtitleCell()
            }
            content.image = item.image
            content.text = item.text
            content.secondaryText = item.secondaryText
            content.textProperties.color = Colors.normalTextColor
            if indexPath.section == HomeViewController.practiceSection {
                content.textProperties.color = self.isPracticeEnabled ? Colors.normalTextColor : Colors.weakTextColor
            }
            cell.contentConfiguration = content
            
            var background = UIBackgroundConfiguration.listPlainCell()
            // https://www.appsloveworld.com/swift/100/44/how-change-the-selection-color-in-compositional-layouts-in-collectionview
            background.backgroundColorTransformer = UIConfigurationColorTransformer { color in
                // Set the selection color to white.
                return .white
            }
            cell.backgroundConfiguration = background
            
            if indexPath.section == HomeViewController.languageSection || indexPath.section == HomeViewController.listSection {
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
            
            if section == HomeViewController.languageSection {
                return collectionView.dequeueConfiguredReusableCell(
                    using: listCellRegistration,
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
            
        applySnapShots()
    }
    
    func applySnapShots() {
        for (section, items) in zip(
            [
                HomeViewController.languageSection,
                HomeViewController.listSection,
                HomeViewController.practiceSection
            ],
            [
                [languageItem],
                listItems,
                practiceItems
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
                
        if section == HomeViewController.languageSection {
            
            let vc = LanguageSelectionViewController()
            vc.delegate = self
            vc.langs = LangCode.learningLanguages
            vc.selectedLang = LangCode.currentLanguage
            navigationController?.pushViewController(
                vc,
                animated: true
            )
            
        } else if section == HomeViewController.listSection {
            
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
            
        } else if section == HomeViewController.practiceSection {
            
            guard isPracticeEnabled else {
                return
            }
            
            let vc: PracticeViewController
            if row == 0 {
                vc = WordsPracticeViewController()
                vc.practiceDuration = LangCode.currentLanguage.configs.phraseReviewPracticeDuration
            } else if row == 1 {
                vc = ListeningPracticeViewController()
                vc.practiceDuration = LangCode.currentLanguage.configs.listeningPracticeDuration
            } else if row == 2 {
                vc = TranslationPracticeViewController()
                vc.practiceDuration = LangCode.currentLanguage.configs.speakingPracticeDuration
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
            GoogleTranslator(
                srcLang: config.lang!,
                trgLang: LangCode.zh
            ).translate(query: config.content!) { translations in
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


extension HomeViewController {
    
    // MARK: - Constants
    
    static let languageSection: Int = 0
    static let listSection: Int = 1
    static let practiceSection: Int = 2
    
}
