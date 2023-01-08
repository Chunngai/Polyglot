//
//  WordsPracticeViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class WordsPracticeViewController: UIViewController {
    
    private var practiceProducer: WordPracticeProducer!
    
    var practiceStatus: PracticeStatus! {
        didSet {
            switch practiceStatus {
            case .beforeAnswering:
                doneButton.isHidden = false
                nextButton.isHidden = true
                deactivateDoneButton()
            case .afterAnswering:
                activateDoneButton()
            case .finished:
                doneButton.isHidden = true
                nextButton.isHidden = false
                deactivateDoneButton()
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
    
    private var practiceView: PracticeDelegate!
    
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
    
    private func updateSetups() {
        timingBar.delegate = self
        
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        
        practiceStatus = .beforeAnswering
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
        mainView.addSubview(doneButton)
        mainView.addSubview(nextButton)
    }
    
    private func updateLayouts() {
        mainView.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalToSuperview().multipliedBy(0.7)
        }
        
        promptLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        doneButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(20)
            make.width.height.equalTo(Sizes.roundButtonRadius)
        }
        nextButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(20)
            make.width.height.equalTo(Sizes.roundButtonRadius)
        }
    }
    
    func updateValues(words: [Word]) {
        practiceProducer = WordPracticeProducer(words: words)
        updatePracticeView()
    }
}

extension WordsPracticeViewController {
    
    // MARK: - Utils
    
    // TODO: - Wrap here. (didSet, etc.)
    private func updatePracticeView() {
        // Remove the old practice view.
        if practiceView != nil {
            practiceView.removeFromSuperview()
        }
        
        // Make a new one.
        switch practiceProducer.currentPractice.practice.practiceType {
        case .meaningSelection:
            practiceView = MeaningSelectionPracticeView()
            if let meaningSelectionPracticeView = practiceView as? MeaningSelectionPracticeView {
                meaningSelectionPracticeView.updateValues(practiceItem: practiceProducer.currentPractice)
                meaningSelectionPracticeView.delegate = self
            }
        case .meaningFilling:
            practiceView = MeaningFillingPracticeView()
            if let meaningFillingPracticeView = practiceView as? MeaningFillingPracticeView {
                meaningFillingPracticeView.updateValues(practiceItem: practiceProducer.currentPractice)
                meaningFillingPracticeView.delegate = self
            }
        case .contextSelection:
            practiceView = MeaningSelectionPracticeView()  // TODO: - for debugging
//            practiceView = ContextSelectionPracticeView()
        }
        mainView.addSubview(practiceView)
        practiceView.snp.makeConstraints { (make) in
            make.top.equalTo(promptLabel.snp.bottom).offset(50)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(350)
        }
        
        // Update the prompt.
        promptLabel.attributedText = NSAttributedString(
            string: practiceProducer.currentPractice.prompt,
            attributes: Attributes.practicePromptAttributes
        )
    }
    
    private func activateDoneButton() {
        doneButton.isEnabled = true
        doneButton.backgroundColor = Colors.weakLightBlue
    }
    
    private func deactivateDoneButton() {
        doneButton.isEnabled = false
        doneButton.backgroundColor = Colors.weakBackgroundColor
    }
}

extension WordsPracticeViewController {
    
    // MARK: - Selectors
    
    @objc func cancelButtonTapped() {
        stopPracticing()
    }
    
    @objc func doneButtonTapped() {
        // TODO: - Simplify.
        if [WordPractice.PracticeType.meaningSelection, WordPractice.PracticeType.contextSelection].contains(practiceProducer.currentPractice.practice.practiceType) {
            let selectedWordId = practiceView.check() as! Int
            practiceProducer.currentPractice.practice.selectedWordId = selectedWordId
        } else if practiceProducer.currentPractice.practice.practiceType == .meaningFilling {
            let typedAnswer = practiceView.check() as! String
            practiceProducer.currentPractice.practice.filledText = typedAnswer
        }
        
        practiceStatus = .finished
    }
    
    @objc func nextButtonTapped() {
        practiceProducer.next()
        
        updatePracticeView()
        
        practiceStatus = .beforeAnswering
    }
}

extension WordsPracticeViewController: TimingBarDelegate {
    
    // MARK: - TimingBar Delegate
    
    func stopPracticing() {
        
        // TODO: - Merge.
        func saveHistoryRecords() {
            var historyRecords: [HistoryRecord] = []
            for i in 0..<practiceProducer.currentPracticeIndex {
                historyRecords.append(HistoryRecord(practice: practiceProducer.practiceList[i].practice))
            }
            
            historyRecords.append(HistoryRecord(practice: practiceProducer.currentPractice.practice))
            
            var loadedHistory = HistoryRecord.load()  // TODO: - Update.
            loadedHistory.append(contentsOf: historyRecords)  // TODO: - Don't load every time.
            HistoryRecord.save(&loadedHistory)
        }
        
        saveHistoryRecords()
        
//        doneButton.isHidden = true
//        nextButton.isHidden = true
        navigationController?.dismiss(animated: true, completion: nil)

    }
    
}
