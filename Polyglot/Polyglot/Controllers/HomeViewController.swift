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
            layout.minimumLineSpacing = Sizes.defaultLineSpacing
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
        
//        dragAndDropDebug()
        
//        jaPaDebug()
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
    
    // MARK: - Constants
    
    static let mainViewWidth: CGFloat = UIScreen.main.bounds.width * 0.8
    static let cellSize: CGFloat = HomeViewController.mainViewWidth / 3.0 * 0.9
    static let numberOfCellsInSection: Int = 3
    
}

extension HomeViewController {
    
    private func jaPaDebug() {
//        let query = "今ご飯食べてる"  // 今 ご飯 食べる
//        let query = "今ご飯食べてる人"  // 今 ご飯 食べる 人
//        let query = "食べてる物"  // 食べる 物
//        let query = "春"
//        let query = "日本語では、花、鼻の発音が似てる。"  // 日本語 で は 花 鼻 の 発音 が 似る
//        let query = "活発な"
//        let query = "活発な反応"
//        let query = "勉強する人"
//        let query = "肌の美白や保湿をする"
//        let query = "おいしい"
//        let query = "中間試験"
        let query = "出題範囲"
//        let query = "「民は食をもって天となす」と言われるように、中国の大晦日は何と言ってもおいしい料理が主役。春節においしい料理を食べながら一家団欒を楽しむのが恒例行事だ。ただ、体調を崩すことがないよう、特に高血糖や消化器系の弱い人は食べ過ぎや飲み過ぎ、衛生管理などに注意しなければならない。太りすぎることがない程度に、おいしい料理をたくさん食べ、ポジティブな気分で新年を迎えよう！"
        
        JapanesePAAnalyzer().analyze(query: query) { (paInfo) in
            for item in paInfo {
                print(item)
            }
        }
    }
    
//    private func dragAndDropDebug() {
//        let controller = TmpViewController2()
//        controller.updateValues(words: {
//            let tokenizer = NLTokenizer(unit: .word)
//            tokenizer.setLanguage(.japanese)
//            
//            let string = "中国のインターネットで人工知能（AI）を使って制作した絵画やイラストが次々と登場している。"
//            tokenizer.string = string
//            
//            var tokens: [String] = []
//            tokenizer.enumerateTokens(in: string.startIndex..<string.endIndex) { (range, attributes) -> Bool in
//                tokens.append(String(string[range]))
//                return true
//            }
//            
//            return tokens
//        }())  // May contain random words.
//        navigationController?.pushViewController(controller, animated: true)
//    }
}
