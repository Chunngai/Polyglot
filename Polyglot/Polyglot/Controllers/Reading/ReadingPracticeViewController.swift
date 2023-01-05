//
//  ReadingPracticeViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/21.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class ReadingPracticeViewController: UIViewController {
    
    private var allNewWordsInfo: [Int : [NewWordInfo]] = [:]
    
    private var practiceProducer: ReadingPracticeProducer!
    private var practiceList: [ReadingPracticeProducer.ReadingPracticeItem]!
    private var currentPracticeIndex: Int!
    private var currentText: String {
        return practiceList[currentPracticeIndex].text
    }
        
    // MARK: - Controllers
    
    var delegate: ReadingViewController!
    
    // MARK: - Views
    
    private var mainView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.weakBackgroundColor
        view.layer.masksToBounds = false
        view.layer.cornerRadius = Sizes.defaultCornerRadius
        return view
    }()
    
    private var textView: NewWordAddingTextView = NewWordAddingTextView()
    
    private var translateButton: UIButton = {  // TODO: - Use another icon.
        let button = UIButton()
        button.setImage(Icons.translateIcon, for: .normal)
        return button
    }()
    
    private var previousButton: RoundButton = {
        let button = RoundButton(radius: Sizes.roundButtonRadius)
        button.setImage(Icons.previousIcon, for: .normal)
        button.backgroundColor = Colors.weakLightBlue
        return button
    }()
    private var nextButton: RoundButton = {
        let button = RoundButton(radius: Sizes.roundButtonRadius)
        button.setImage(Icons.nextIcon, for: .normal)
        button.backgroundColor = Colors.weakLightBlue
        return button
        
    }()
    
    private var timingBar: TimingBar = {
        let bar = TimingBar(duration: Vars.practiceDuration)
        return bar
    }()
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    override func viewDidLayoutSubviews() {
        // https://stackoverflow.com/questions/55492684/how-to-get-the-frame-of-a-uiview-that-has-been-setup-through-snapkit
        textView.newWordBottomView.offset = UIScreen.main.bounds.maxY - mainView.frame.maxY
    }
    
    private func updateSetups() {
        translateButton.addTarget(self, action: #selector(translateButtonTapped), for: .touchUpInside)
        
        previousButton.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        
        timingBar.delegate = self
        
        solveKeyboardLocation(view: self.view)
    }
    
    private func updateViews() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: Icons.cancelIcon,
            style: .plain,
            target: self,
            action: #selector(cancelButtonTapped)
        )
                 
        view.backgroundColor = Colors.defaultBackgroundColor

        view.addSubview(mainView)
        
        mainView.addSubview(textView)
        textView.newWordBottomView.frame = CGRect(
            x: view.frame.minX,
            y: view.frame.maxY,
            width: view.frame.width,
            height: view.frame.height
        )
        
        mainView.addSubview(translateButton)
        
        view.addSubview(previousButton)
        view.addSubview(nextButton)
        
        view.addSubview(textView.newWordBottomView)
        
        navigationItem.titleView = timingBar
    }
    
    private func updateLayouts() {
        mainView.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalToSuperview().multipliedBy(0.7)
        }
        
        textView.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.9)
            make.height.equalToSuperview().multipliedBy(0.9)
        }
        
        translateButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().inset(15)
        }
        
        previousButton.snp.makeConstraints { (make) in
            make.left.equalTo(mainView.snp.left).offset(50)
            make.top.equalTo(mainView.snp.bottom).offset(15)
            make.width.height.equalTo(previousButton.radius)
        }
        nextButton.snp.makeConstraints { (make) in
            make.right.equalTo(mainView.snp.right).offset(-50)
            make.top.equalTo(previousButton.snp.top)
            make.width.height.equalTo(nextButton.radius)
        }
    }
    
    func updateValues(articles: [Article]) {
        practiceProducer = ReadingPracticeProducer(articles: articles)
        practiceList = practiceProducer.make()
        currentPracticeIndex = 0
        
        updateText()
    }
}

extension ReadingPracticeViewController {
    
    // MARK: - Utils
    
    private func updateText() {
        
        // Clean up.
        // TODO: - Update here.
        if textView.currentNewWordInfo != nil {
            textView.currentNewWordInfo = nil
        }
        textView.newWordsInfo = []
        if textView.currentSelectedTextRange != nil {
            textView.currentSelectedTextRange = nil
        }
        if textView.isAddingNewWord != nil {
            textView.isAddingNewWord = false
        }
        textView.newWordBottomView.clear()

        // Update the text.
        textView.attributedText = NSMutableAttributedString(
            string: currentText,
            attributes: Attributes.longTextAttributes
        )
        
        // Recover new words of the current text, if any.
        if allNewWordsInfo.keys.contains(currentPracticeIndex) {
            textView.newWordsInfo = allNewWordsInfo[currentPracticeIndex]!
            textView.highlightAll()  // TODO: - Wrap?
        }
    }
}

extension ReadingPracticeViewController {
    
    // MARK: - Selectors
    
    @objc private func cancelButtonTapped() {
        
        // TODO: - Alert.
        
        stopPracticing()
        
        navigationController?.dismiss(animated: true, completion: nil)

    }
    
    @objc private func translateButtonTapped() {
        print("translate")
    }
    
    @objc private func previousButtonTapped() {
        // Store new words of the previous text.
        // TODO: - Merge with the line in nextButtonTapped
        allNewWordsInfo[currentPracticeIndex] = textView.newWordsInfo

        currentPracticeIndex -= 1
        if currentPracticeIndex < 0 {
            currentPracticeIndex += 1  // Recover the index.
            return
        }
        
        updateText()
    }
    
    @objc private func nextButtonTapped() {
        // Store new words of the previous text.
        allNewWordsInfo[currentPracticeIndex] = textView.newWordsInfo
        
        currentPracticeIndex += 1
        if currentPracticeIndex >= practiceList.count {
            practiceList.append(contentsOf: practiceProducer.make())
        }
        
        updateText()
    }
}

extension ReadingPracticeViewController: TimingBarDelegate {
    
    // MARK: - TimeBar Delegate
    
    func stopPracticing() {
        
        // TODO: - Move elsewhere
        // New words are saved only the next button is pressed.
        // If the button is not pressed, the new words will not be saved.
        allNewWordsInfo[currentPracticeIndex] = textView.newWordsInfo
        
        // TODO: - Merge.
        func saveNewWords() {
            var newWords: [Word] = []
            for (practiceItemIndex, newWordsInfo) in allNewWordsInfo {
                let articleId = practiceList[practiceItemIndex].practice.articleAndParaIds[0]
                let article = Article.getArticle(from: articleId)
                let articleTitle = article?.title
                for newWordInfo in newWordsInfo {
                    newWords.append(Word(
                        word: newWordInfo.word,
                        meaning: newWordInfo.meaning,
                        groupNote: articleTitle ?? ""
                    ))
                }
            }
            
            var loadedWords = Word.load()  // TODO: - Update.
            loadedWords.append(contentsOf: newWords)  // TODO: - Don't load every time.
            Word.save(&loadedWords)
        }
        
        // TODO: - Merge.
        func saveHistoryRecords() {
            var historyRecords: [HistoryRecord] = []
            for i in 0...currentPracticeIndex {
                historyRecords.append(HistoryRecord(practice: practiceList[i].practice))
            }
            
            var loadedHistory = HistoryRecord.load()  // TODO: - Update.
            loadedHistory.append(contentsOf: historyRecords)  // TODO: - Don't load every time.
            HistoryRecord.save(&loadedHistory)
        }
        
        saveNewWords()
        saveHistoryRecords()
        
        nextButton.isHidden = true
//        navigationController?.dismiss(animated: true, completion: nil)
        
        // TODO: - Display another view later.
        //        displaySaveNewWordsAlert(
        //            newWordNumber: self.newWordsInfo.count,
        //            completion: nil  self.navigationController?.dismiss(animated: true, completion: nil)
        //        )
    }
    
}
