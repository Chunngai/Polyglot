//
//  TranslationPracticeViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/30.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class TranslationPracticeViewController: UIViewController {
    
    private var allNewWordsInfo: [Int : [NewWordInfo]] = [:]
    
    private var practiceProducer: TranslationPracticeProducer!
    private var practiceList: [TranslationPracticeProducer.TranslationPracticeItem]!
    private var currentPracticeIndex: Int!
    private var currentPractice: TranslationPracticeProducer.TranslationPracticeItem {
        return practiceList[currentPracticeIndex]
    }
    
    var practiceStatus: PracticeStatus! {
        didSet {
            switch practiceStatus {
            case .beforeAnswering:
                doneButton.isHidden = false
                nextButton.isHidden = true
            case .finished:
                doneButton.isHidden = true
                nextButton.isHidden = false
            default:
                return
            }
        }
    }
    
    // MARK: - Views
    
    private var timingBar: TimingBar = {
        let bar = TimingBar(duration: Vars.practiceDuration)
        return bar
    }()
    
    private var mainView: UIView = {
        let view = UIView()
        view.backgroundColor = nil
        return view
    }()
    
    private var promptLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = nil
        label.numberOfLines = 0
        return label
    }()
    
    private var textView: NewWordAddingTextView = {
        let textView = NewWordAddingTextView()
        textView.isEditable = false
        textView.backgroundColor = Colors.weakBackgroundColor
        textView.layer.masksToBounds = true
        textView.layer.cornerRadius = Sizes.defaultCornerRadius
        textView.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        return textView
    }()
    
    private var doneButton: RoundButton = {
        let button = RoundButton(radius: Sizes.roundButtonRadius)
        button.setImage(Icons.doneIcon, for: .normal)
        button.backgroundColor = Colors.weakLightBlue
        return button
    }()
    
    private var nextButton: RoundButton = {
        let button = RoundButton(radius: Sizes.roundButtonRadius)
        button.setImage(Icons.nextIcon, for: .normal)
        button.backgroundColor = Colors.weakLightBlue
        button.isHidden = true
        return button
    }()
    
    // MARK: - Controllers
    
    var delegate: WordsViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    override func viewDidLayoutSubviews() {
        // https://stackoverflow.com/questions/55492684/how-to-get-the-frame-of-a-uiview-that-has-been-setup-through-snapkit
//        textView.newWordBottomView.offset = UIScreen.main.bounds.maxY - mainView.frame.maxY
        textView.newWordBottomView.offset = 100
    }
    
    private func updateSetups() {
        timingBar.delegate = self
        
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        
        practiceStatus = .beforeAnswering
        
        solveKeyboardLocation(view: self.view)
    }
    
    private func updateViews() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: Icons.cancelIcon,
            style: .plain,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        navigationItem.titleView = timingBar
                 
        view.backgroundColor = Colors.defaultBackgroundColor

        view.addSubview(mainView)
        mainView.addSubview(promptLabel)
        promptLabel.attributedText = NSAttributedString(
            string: Strings.translationPracticePrompt,
            attributes: Attributes.practicePromptAttributes
        )
        mainView.addSubview(textView)
        textView.newWordBottomView.frame = CGRect(
            x: view.frame.minX,
            y: view.frame.maxY,
            width: view.frame.width,
            height: view.frame.height
        )
        view.addSubview(textView.newWordBottomView)

        mainView.addSubview(doneButton)
        mainView.addSubview(nextButton)
    }
    
    private func updateLayouts() {
        // TODO: - Update.
        
        mainView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(130)
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalToSuperview().multipliedBy(0.8)
        }
        
        promptLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        textView.snp.makeConstraints { (make) in
            make.top.equalTo(promptLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(500)
        }
        
        doneButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(textView.snp.bottom).offset(30)
            make.width.height.equalTo(Sizes.roundButtonRadius)
        }
        nextButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(textView.snp.bottom).offset(30)
            make.width.height.equalTo(Sizes.roundButtonRadius)
        }
    }
    
    func updateValues(articles: [Article]) {
        practiceProducer = TranslationPracticeProducer(articles: articles)
        practiceList = practiceProducer.make()
        currentPracticeIndex = 0
        
        updatePractice()
    }
}

extension TranslationPracticeViewController {
    
    // MARK: - Utils
    
    private func updatePractice() {
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
            string: currentPractice.textToTranslate,
            attributes: Attributes.longTextAttributes
        )
        
        // Recover new words of the current text, if any.
        if allNewWordsInfo.keys.contains(currentPracticeIndex) {
            textView.newWordsInfo = allNewWordsInfo[currentPracticeIndex]!
            textView.highlightAll()  // TODO: - Wrap?
        }
    }
    
    private func displayTranslation() {
        textView.attributedText = NSAttributedString(
            string: "\(currentPractice.textToTranslate)\n\nTranslation:\n\(currentPractice.textMeaning)",  // TODO: - Update here.
            attributes: Attributes.longTextAttributes
        )
        
        // Restore the highlights.
        // TODO: - Simplify here.
        textView.highlightAll()
    }
}

extension TranslationPracticeViewController {
    
    // MARK: - Selectors
    
    @objc func cancelButtonTapped() {
        stopPracticing()
        
        navigationController?.dismiss(animated: true, completion: nil)

    }
    
    @objc func doneButtonTapped() {
        
        practiceStatus = .finished
                
        displayTranslation()
    }
    
    @objc func nextButtonTapped() {
        // Store new words of the previous text.
        allNewWordsInfo[currentPracticeIndex] = textView.newWordsInfo

        // TODO: - Wrap.
        currentPracticeIndex += 1
        if currentPracticeIndex >= practiceList.count {
            practiceList.append(contentsOf: practiceProducer.make())
        }
        
        updatePractice()
        
        practiceStatus = .beforeAnswering
    }
}

extension TranslationPracticeViewController: TimingBarDelegate {
    
    // MARK: - TimingBar Delegate
    
    internal func stopPracticing() {
        
        // TODO: - Move elsewhere
        // New words are saved only the next button is pressed.
        // If the button is not pressed, the new words will not be saved.
        allNewWordsInfo[currentPracticeIndex] = textView.newWordsInfo
        
        // TODO: - Merge with reading practice?
        func saveNewWords() {
            var newWords: [Word] = []
            for (practiceItemIndex, newWordsInfo) in allNewWordsInfo {
                
                // TODO: - Simplify this block.
                let articleId = practiceList[practiceItemIndex].practice.articleAndParaIds[0]
                let article = Article.load().getArticle(from: articleId)  // TODO: - load()
                let articleTitle = article?.title
                
                for newWordInfo in newWordsInfo {
                    newWords.append(Word(
                        text: newWordInfo.word,
                        meaning: newWordInfo.meaning,
                        note: articleTitle ?? ""
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
        
        doneButton.isHidden = true
        nextButton.isHidden = true
//        navigationController?.dismiss(animated: true, completion: nil)
        
    }
    
}
