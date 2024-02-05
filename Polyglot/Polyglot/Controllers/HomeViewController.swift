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
    let lang: String?
    let words: [String]?
    let meanings: [String]?
    let pronunciations: [String]?
    let content: String?
    let contentSource: String?
    
    init(
        image: UIImage? = nil, 
        text: String? = nil, secondaryText: String? = nil,
        header: String? = nil, lang: String? = nil, words: [String]? = nil, meanings: [String]? = nil, pronunciations: [String]? = nil, content: String? = nil, contentSource: String? = nil
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
            
            self.wordMetaData = Word.loadMetaData(for: lang)
            self.articleMetaData = Article.loadMetaData(for: lang)
            
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
//        HomeItem(
//            image: UIImage.init(systemName: "doc"),
//            text: Strings._reading[languageOfTextToDisplay]
//        ),
        HomeItem(
            image: UIImage.init(systemName: "bubble"),
            text: Strings._interpretation[languageOfTextToDisplay]
        )
    ]}
    
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
    
    var contentCards: ContentCards!
    var contentCardSnapshots: [String: [
        Int: NSDiffableDataSourceSectionSnapshot<HomeItem>
    ]] = [
        "sentences": [:],
        "paragraphs": [:],
    ]
    
    // MARK: - CardCell Delegate
    
    // Ref: https://stackoverflow.com/questions/73706115/avspeechsynthesizer-isnt-working-under-ios16-anymore
    var synthesizer = AVSpeechSynthesizer()
    
    var indexPath2TranslationForCellsThatAreDisplayingMeanings: [IndexPath: String] = [:]
    var indexPathForCellThatIsProcudingVoice: IndexPath? = nil {
        didSet {
            self.collectionView.reloadData()  // IMPORTANT!!! WITHOUT THIS THE BUTTON IMAGE MAY NOT BE CHANGED.
        }
    }
        
    // MARK: - Controllers
    
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
            self.displayContentCards()
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
        
        for fileName in self.fileNamesToUpload {
            
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
                print("Failed to construct URL for \(fileName)")
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
    
    private func generateContentCardSnapshots() {
        
        for hour in 0...23 {
            
            var sentenceItems:[HomeItem] = []
            for lang in learningLangs {
                guard let entry = contentCards.sentences[hour]?[lang] else {
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
            
            var paragraphItems: [HomeItem] = []
            for lang in learningLangs {
                guard let entry = contentCards.paragraphs[hour]?[lang] else {
                    continue
                }
                guard let content = entry.content, !content.isEmpty else {
                    continue
                }
                
                var allWords: [String] = []
                var allMeanings: [String] = []
                var allPronunciations: [String] = []
                for (wordLang, wordEntries) in contentCards.words {
                    if wordLang != lang {
                        continue
                    }
                    for wordEntry in wordEntries {
                        allWords.append(wordEntry.text!)
                        allMeanings.append(wordEntry.meaning!)
                        allPronunciations.append(wordEntry.pronunciation!)
                    }
                }
                
                paragraphItems.append(HomeItem(
                    lang: lang,
                    words: allWords,
                    meanings: allMeanings,
                    pronunciations: allPronunciations,
                    content: content,
                    contentSource: "chatgpt"
                ))
            }
            if !paragraphItems.isEmpty {
                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<HomeItem>()
                sectionSnapshot.append([HomeItem(header: "\(hour):00")])
                sectionSnapshot.append(paragraphItems)
                self.contentCardSnapshots["paragraphs"]![hour] = sectionSnapshot
            }
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
            let paragraphSectionIdentifier = ContentCards.paragraphSectionIdentifier(for: hour)
            if currentSectionIdentifiers.contains(paragraphSectionIdentifier) {
                continue
            }
            guard let paragraphSnapShot = contentCardSnapshots["paragraphs"]![hour] else {
                continue
            }
            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    self.dataSource.apply(
                        paragraphSnapShot,
                        to: paragraphSectionIdentifier
                    )
                }
            }
        }
    }
    
    private func displayContentCards() {
        if contentCards == nil {
            contentCards = ContentCards.load()
            generateContentCardSnapshots()
        }
        // Date check.
        if contentCards.dateString != Date().repr(of: ContentCards.dateFormat) {
            ContentCards.fetchAndSave { contentCards in
                self.generateContentCardSnapshots()
            }
        }
        self.applyContentCardSnapshots()
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
    
    private var fileNamesToUpload: [String] {
        var fileNames: [String] = []
        for learningLang in self.learningLangs {
            fileNames.append(Word.fileName(for: learningLang))
            fileNames.append(Article.fileName(for: learningLang))
        }
        return fileNames
    }
    
    private func uploadFilesToServer() {
        let serverURL = "http://4o51096o21.zicp.vip/upload"
        let headers: HTTPHeaders = ["Content-Type": "multipart/form-data"]
        
        for fileName in self.fileNamesToUpload {
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
                    print("\(fileName) uploaded successfully")
                case .failure(let error):
                    print("Error uploading \(fileName): \(error)")
                }
            }
        }
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
        
//        Feedbacks.defaultFeedbackGenerator.selectionChanged()
        
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
        } else if section == HomeViewController.practiceSection {
            
            guard self.lang != nil else {
                return
            }
            
            let vc: PracticeViewController
//            if row == 0 {
//                vc = WordsPracticeViewController()
//            } else if row == 1 {
//                vc = ReadingPracticeViewController()
//            } else if row == 2 {
//                vc = TranslationPracticeViewController()
//            } else {
//                fatalError("Not Implemented.")
//            }
            if row == 0 {
                vc = WordsPracticeViewController()
            } else if row == 1 {
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
        
        // TODO: - Problematic when scrolling. Possibly due to the concurrent execution of createCardCellRegistration and this method.
        
        guard let indexPathForCellThatIsProcudingVoice = indexPathForCellThatIsProcudingVoice,
              let cell = dataSource.collectionView(collectionView, cellForItemAt: indexPathForCellThatIsProcudingVoice) as? CardCell,
              let config = cell.contentConfiguration as? CardCellContentConfiguration else {
            return
        }
        config.isProducingVoice = false
        
        self.indexPathForCellThatIsProcudingVoice = nil
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
