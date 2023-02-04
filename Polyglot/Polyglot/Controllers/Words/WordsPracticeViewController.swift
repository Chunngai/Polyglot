//
//  WordsPracticeViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class WordsPracticeViewController: PracticeViewController {
    
    var practiceProducer: WordPracticeProducer!
    
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
   
    // MARK: - Init
   
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do not call the functions below,
        // as they will be called in viewDidLoad()
        // of the superclass.
        // updateSetups()
        // updateViews()
        // updateLayouts()
        // updatePracticeView()
    }
    
    override func updateSetups() {
        super.updateSetups()
        
        practiceStatus = .beforeAnswering
    }
    
    override func updateViews() {
        super.updateViews()
    }
    
    override func updateLayouts() {
        super.updateLayouts()
    }
    
    override func updatePracticeView() {
        func makePracticeView() -> PracticeViewDelegate {
            switch practiceProducer.currentPractice.practice.practiceType {
            case .meaningSelection:
                return {
                    let practiceView = SelectionPracticeView()
                    practiceView.updateValues(selectionTexts: practiceProducer.currentPractice.selectionTexts!)
                    practiceView.delegate = self
                    return practiceView
                }()
            case .meaningFilling:
                return {
                    let practiceView = MeaningFillingPracticeView()
                    practiceView.delegate = self
                    return practiceView
                }()
            case .contextSelection:
                // TODO: - Update here.
                break
            case .accentSelection:
                return {
                    let practiceView = SelectionPracticeView()
                    practiceView.updateValues(selectionTexts: practiceProducer.currentPractice.selectionTexts!)
                    practiceView.delegate = self
                    return practiceView
                }()
            }
            
            // Will not reach here.
            return SelectionPracticeView()
        }
        
        // Remove the old practice view.
        if practiceView != nil {
            practiceView.removeFromSuperview()
        }
        // Make a new one.
        practiceView = makePracticeView()
        // Add to the main view and update layouts.
        mainView.addSubview(practiceView)
        practiceView.snp.makeConstraints { (make) in
            make.top.equalTo(promptLabel.snp.bottom).offset(50)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.bottom.equalTo(nextButton.snp.top).offset(-20)
        }
        
        // Update the prompt.
        promptLabel.text = practiceProducer.currentPractice.prompt
    }
    
    func updateValues(words: [Word]) {
        practiceProducer = WordPracticeProducer(words: words)
    }
}

extension WordsPracticeViewController {
    
    // MARK: - Utils
    
    private func activateDoneButton() {
        doneButton.isEnabled = true
        doneButton.backgroundColor = Colors.lightBlue
    }
    
    private func deactivateDoneButton() {
        doneButton.isEnabled = false
        doneButton.backgroundColor = Colors.lightGrayBackgroundColor
    }
}

extension WordsPracticeViewController {
    
    // MARK: - Selectors
    
    @objc override func doneButtonTapped() {
        let answer = (practiceView as! WordPracticeViewDelegate).submit()
        practiceProducer.submit(answer: answer)
        (practiceView as! WordPracticeViewDelegate).updateViews(
            for: practiceProducer.currentPractice.practice.correctness!,
            key: practiceProducer.currentPractice.key,
            tokenizer: practiceProducer.currentPractice.tokenizer
        )
                
        practiceStatus = .finished
    }
    
    @objc override func nextButtonTapped() {        
        practiceProducer.next()
        updatePracticeView()
        
        practiceStatus = .beforeAnswering
    }
}

extension WordsPracticeViewController {
    
    // MARK: - TimingBar Delegate
    
    override func stopPracticing() {
        practiceProducer.save()
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
}
