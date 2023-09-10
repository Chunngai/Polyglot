//
//  HomeViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/20.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit
import SnapKit
import NaturalLanguage

class HomeViewController: UIViewController {

    private let learningLanguages = LangCode.loadLearningLanguages()
    
    private var indexOfDisplayingLang: Int! {
        didSet {
            indexOfDisplayingLang = (self.indexOfDisplayingLang) % learningLanguages.count
        }
    }
    private var displayingLang: String {
        return learningLanguages[self.indexOfDisplayingLang]
    }
    
    private var isExecutingTextAnimation: Bool = true
    
    // MARK: - Models
    
    var wordCardEntries: [String: [WordCardEntry]] = [:] {
        didSet {
            for (lang, entries) in wordCardEntries {
                var entries = entries
                WordCardEntry.save(&entries, for: lang)
            }
        }
    }
    
    // MARK: - Views
    
    private lazy var mainView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var promptView: UIView = {
        let view = UIView()
        return view
    }()
    private lazy var primaryPromptLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: Strings._mainPrimaryPrompts[self.displayingLang]!,
            attributes: Attributes.primaryPromptAttributes
        )
        return label
    }()
        
    private var langCollectionView: UICollectionView = {
        
        // https://itisjoe.gitbooks.io/swiftgo/content/uikit/uicollectionview.html
        
        let collectionLayout: UICollectionViewFlowLayout = {
            let layout = UICollectionViewFlowLayout()
            layout.minimumLineSpacing = Sizes.defaultLineSpacing * 2
            layout.minimumInteritemSpacing = Sizes.defaultCollectionLayoutMinimumInteritemSpacing
            layout.itemSize = CGSize(
                width: HomeViewController.cellSize,
                height: HomeViewController.cellSize
            )
            return layout
        }()
        
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: collectionLayout
        )
        collectionView.backgroundColor = Colors.defaultBackgroundColor
        return collectionView
    }()
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
                        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        for learningLanguage in learningLanguages {
            wordCardEntries[learningLanguage] = WordCardEntry.load(for: learningLanguage)
        }
        print(wordCardEntries)
        DispatchQueue.global(qos: .userInitiated).async {
            //            removeAllNotifications()
            self.generateWordcardNotifications()
        }
        
        // https://juejin.cn/post/6905235669758443533
        // https://stackoverflow.com/questions/27501732/stop-and-start-nsthread-in-swift
        Thread.detachNewThreadSelector(#selector(textAnimation), toTarget: self, with: nil)
        isExecutingTextAnimation = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        isExecutingTextAnimation = false
    }
    
    private func updateSetups() {
        
        langCollectionView.dataSource = self
        langCollectionView.delegate = self
        langCollectionView.register(LangCell.self, forCellWithReuseIdentifier: Identifiers.langCellIdentifier)
        
        indexOfDisplayingLang = (0..<learningLanguages.count).randomElement()!
    }
    
    private func updateViews() {
        
        view.backgroundColor = Colors.defaultBackgroundColor
        view.addSubview(mainView)
                
        mainView.addSubview(promptView)
        mainView.addSubview(langCollectionView)

        promptView.addSubview(primaryPromptLabel)
    }
    
    // TODO: - Update the insets and offsets here.
    // TODO: - Use relative insets and offsets instead.
    private func updateLayouts() {
        
        mainView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.top.equalToSuperview().inset(300)
            make.bottom.equalToSuperview()
        }
    
        promptView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.4)
        }
        primaryPromptLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
        }
        
        langCollectionView.snp.makeConstraints { (make) in
            var rowNumber: Int = learningLanguages.count / HomeViewController.numberOfCellsInSection
            if CGFloat(learningLanguages.count).truncatingRemainder(dividingBy: CGFloat(HomeViewController.numberOfCellsInSection)) != 0 {
                rowNumber += 1
            }
            
            let rowHeight = HomeViewController.cellSize
                + (langCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing
            
            make.top.equalTo(promptView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(
                (rowHeight) * CGFloat(rowNumber)
            )
        }
    }
}

extension HomeViewController: UICollectionViewDataSource {
    
    // MARK: - UICollectionView Data Source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return learningLanguages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: Identifiers.langCellIdentifier,
            for: indexPath
        ) as? LangCell else {
            return UICollectionViewCell()
        }
    
        cell.langCode = learningLanguages[indexPath.row]
        cell.langOfLangLabelText = learningLanguages[indexOfDisplayingLang]
        
        return cell
    }
}

extension HomeViewController: UICollectionViewDelegate {
    
    // MARK: - UICollectionView Delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? LangCell else {
            return
        }
        
        Feedbacks.defaultFeedbackGenerator.selectionChanged()
        
        let menuViewController = MenuViewController(lang: cell.langCode)
        menuViewController.delegate = self
        navigationController?.pushViewController(menuViewController, animated: true)
    }
    
}

extension HomeViewController {

    // MARK: - Selectors
    
    @objc func textAnimation() {
        while true {
            // https://stackoverflow.com/questions/3073520/animate-text-change-in-uilabel
            DispatchQueue.main.async {
                
                self.indexOfDisplayingLang += 1
                let displayingLang = self.displayingLang

                UIView.transition(
                    with: self.view,
                    duration: 3,
                    // https://stackoverflow.com/questions/3237431/does-animatewithdurationanimations-block-main-thread
                    // .allowUserInteraction is needed else the button becomes not interactive.
                    options: [.transitionCrossDissolve, .allowUserInteraction],
                    animations: { [weak self] in
                        self?.primaryPromptLabel.text = Strings._mainPrimaryPrompts[displayingLang]
                        
                        if let cells = self?.langCollectionView.visibleCells {
                            for cell in cells {
                                (cell as! LangCell).langOfLangLabelText = displayingLang
                            }
                        }
                    },
                    completion: nil
                )
            }
            Thread.sleep(forTimeInterval: 3)
            
            if !isExecutingTextAnimation {
                Thread.exit()
            }
        }
    }

}

extension HomeViewController {
    
    private func makeLang2rid(from requests: [UNNotificationRequest]) -> [String: [String]] {
        var lang2rid: [String: [String]] = [:]
        for learningLang in self.learningLanguages {
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
        64 / self.learningLanguages.count  // 64: max pending request num.
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
            
            for lang in self.wordCardEntries.keys {
                // Create word cards for 10-22.
                for day in Date().nextNDays(n: 3) {
                    for hour in 10...22 {
                        if lang2rid[lang]!.count >= self.maxRequestPerLang {
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
                        
                        let identifier = self.makeWordCardIdentifier(lang: lang, triggerDateComponents: triggerDateComponents)
                        if lang2rid[lang]!.contains(identifier) {
                            continue
                        }
                        
                        guard let wordCardEntry = self.wordCardEntries[lang]!.popLast() else {
                            continue
                        }
                        
                        let title: String = self.addIcon(of: lang, to: wordCardEntry.title)
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
                        lang2rid[lang]!.append(identifier)
                    }
                }
            }
            print("After:", lang2rid)
        }
    }
    
}

extension HomeViewController {
    
    // MARK: - Constants
    
    static let mainViewWidth: CGFloat = UIScreen.main.bounds.width * 0.8
    static let cellSize: CGFloat = HomeViewController.mainViewWidth / 3.0 * 0.9
    static let numberOfCellsInSection: Int = 3
    
}
