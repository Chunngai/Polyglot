//
//  WordsPracticeViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift

class WordsPracticeViewController: PracticeViewController {

    var selectedWordKeys: Set<String>? = nil

    private var initialPracticeCount: Int = 0

    private let grammarAnnotationLegendView: GrammarAnnotationLegendView = GrammarAnnotationLegendView()

    // Progress bar shown in the nav title when launched as phrase review.
    // Styled to match TimingBar: same height, full-width, rounded, same colors.
    private lazy var phraseReviewProgressBar: UIProgressView = {
        let bar = UIProgressView(progressViewStyle: .bar)
        bar.trackTintColor = Colors.timingBarTintColor
        bar.progressTintColor = Colors.lightBlue
        bar.progress = 0
        bar.layer.masksToBounds = true
        bar.layer.cornerRadius = Sizes.smallCornerRadius
        // Match TimingBar's width and height constraints.
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.widthAnchor.constraint(equalToConstant: 280 / 414 * UIScreen.main.bounds.width).isActive = true
        bar.heightAnchor.constraint(equalToConstant: 20).isActive = true
        return bar
    }()

    private lazy var practiceProducer: WordPracticeProducer = {
        let producer = WordPracticeProducer(words: words, articles: articles)
        if let keys = selectedWordKeys {
            var selected: [BasePractice] = []
            var excluded: [WordPractice] = []
            for practice in producer.practiceList {
                if let wp = practice as? WordPractice {
                    if keys.contains(WordPracticeProducer.normalizedKey(from: wp.word)) {
                        selected.append(wp)
                    } else {
                        excluded.append(wp)
                    }
                } else {
                    selected.append(practice)
                }
            }
            // Deduplicate: for each (word, practiceType) pair keep only up to
            // wordPracticeRepetition entries. This prevents inflated counts when
            // the cache contains multiple historical periods for the same word.
            let maxPerType = LangCode.currentLanguage.configs.wordPracticeRepetition
            var seenCounts: [String: Int] = [:]
            var deduped: [BasePractice] = []
            for practice in selected {
                if let wp = practice as? WordPractice {
                    let dedupeKey = "\(WordPracticeProducer.normalizedKey(from: wp.word))|\(wp.practiceType.rawValue)"
                    let count = seenCounts[dedupeKey, default: 0]
                    if count < maxPerType {
                        seenCounts[dedupeKey] = count + 1
                        deduped.append(wp)
                    }
                } else {
                    deduped.append(practice)
                }
            }

            producer.practiceList = deduped
            producer.practiceList.shuffle()
            producer.excludedPractices = excluded
            // Write the capped list back to disk so the phrase review list
            // reflects the trimmed count after returning from practice.
            producer.cache()
        }
        producer.practiceList.sort { a, b in
            guard let wa = a as? WordPractice, let wb = b as? WordPractice else { return false }
            let accentA = wa.isAccentAnnotationCompleted || wa.query.contains(Token.accentSymbol)
            let accentB = wb.isAccentAnnotationCompleted || wb.query.contains(Token.accentSymbol)
            let grammarA = wa.isGrammarAnnotationCompleted || !wa.verbAspectAnnotations.isEmpty || !wa.nounCaseAnnotations.isEmpty || !wa.shortAdjectiveAnnotations.isEmpty
            let grammarB = wb.isGrammarAnnotationCompleted || !wb.verbAspectAnnotations.isEmpty || !wb.nounCaseAnnotations.isEmpty || !wb.shortAdjectiveAnnotations.isEmpty
            let scoreA = (accentA ? 1 : 0) + (grammarA ? 1 : 0)
            let scoreB = (accentB ? 1 : 0) + (grammarB ? 1 : 0)
            return scoreA > scoreB
        }
        initialPracticeCount = producer.practiceList.count
        return producer
    }()
       
    // Code for adjusting the height of the textfield
    // when the keyboard is displayed.
    // TODO: - Move the code elsewhere.
    
    private var oriFrameOfFillingPracticeView: CGRect?
    private var marginBetweenTextFieldAndKeyboard: CGFloat = 30
    
    private func resetFillingPracticeViewMovingOffset() {

        guard let fillingPracticeView = practiceView as? FillingPracticeView else {
            return
        }
        guard let oriFrameOfFillingPracticeView = oriFrameOfFillingPracticeView else {
            return
        }
        
        UIView.animate(withDuration: 0.2) {
            fillingPracticeView.frame = oriFrameOfFillingPracticeView
        }
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
                
        guard let fillingPracticeView = practiceView as? FillingPracticeView else {
            return
        }
        if oriFrameOfFillingPracticeView == nil {
            oriFrameOfFillingPracticeView = fillingPracticeView.frame
        }
        if fillingPracticeView.frame != oriFrameOfFillingPracticeView {
            resetFillingPracticeViewMovingOffset()
        }
        
        // https://stackoverflow.com/questions/8082493/how-to-get-the-frame-of-a-view-inside-another-view
        let textFieldRelatedFrame = fillingPracticeView.convert(fillingPracticeView.textField.frame, to: self.view)
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        if textFieldRelatedFrame.maxY + marginBetweenTextFieldAndKeyboard >= keyboardSize.minY {
            let movingOffset = textFieldRelatedFrame.maxY - keyboardSize.minY + marginBetweenTextFieldAndKeyboard
            UIView.animate(withDuration: 0.2) {
                fillingPracticeView.frame = CGRect(
                    x: fillingPracticeView.frame.minX,
                    y: fillingPracticeView.frame.minY - movingOffset,
                    width: fillingPracticeView.frame.width,
                    height: fillingPracticeView.frame.height
                )
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        resetFillingPracticeViewMovingOffset()
    }
    
    // MARK: - Init

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        IQKeyboardManager.shared.enable = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        IQKeyboardManager.shared.enable = true
    }
    
    override func updateSetups() {
        super.updateSetups()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )

    }

    override func updateViews() {
        super.updateViews()

        mainView.addSubview(grammarAnnotationLegendView)
        grammarAnnotationLegendView.isHidden = true

        // When launched as phrase review (selectedWordKeys is set), replace the
        // timing bar in the nav title with a UIProgressView, and move the
        // progress label ("3/10") into the nav bar right side.
        if selectedWordKeys != nil {
            timingBar.pause()
            timingBar.isHidden = true
            navigationItem.titleView = phraseReviewProgressBar

            progressLabel.removeFromSuperview()
            progressLabel.textColor = Colors.weakTextColor
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: progressLabel)
        }
    }

    override func updateLayouts() {
        super.updateLayouts()

        grammarAnnotationLegendView.snp.remakeConstraints { (make) in
            make.top.equalTo(promptLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
    }
    
    override func updatePracticeView() {
        
        let currentPractice = practiceProducer.currentPractice as! WordPractice
        
        func makePracticeView() -> WordPracticeView {

            switch currentPractice.practiceType {
            case .meaningSelection:
                return {
                    let practiceView = SelectionPracticeView()
                    practiceView.updateValues(
                        selectionTexts: currentPractice.choices!,
                        verbAspectAnnotations: currentPractice.choiceVerbAspectAnnotations,
                        nounCaseAnnotations: currentPractice.choiceNounCaseAnnotations
                    )
                    practiceView.delegate = self
                    return practiceView
                }()
            case .meaningFilling:
                return {
                    let practiceView = FillingPracticeView()
                    practiceView.delegate = self
                    return practiceView
                }()
            case .contextSelection:
                return {
                    let practiceView = SelectionPracticeView()
                    practiceView.updateValues(
                        selectionTexts: currentPractice.choices!,
                        textViewText: currentPractice.context!,
                        verbAspectAnnotations: currentPractice.choiceVerbAspectAnnotations,
                        nounCaseAnnotations: currentPractice.choiceNounCaseAnnotations,
                        contextVerbAspectAnnotations: currentPractice.contextVerbAspectAnnotations,
                        contextNounCaseAnnotations: currentPractice.contextNounCaseAnnotations
                    )
                    practiceView.delegate = self
                    return practiceView
                }()
            case .accentSelection:
                return {
                    let practiceView = SelectionPracticeView()
                    practiceView.updateValues(selectionTexts: currentPractice.choices!)
                    practiceView.delegate = self
                    return practiceView
                }()
            case .reordering:
                return {
                    let practiceView = ReorderingPracticeView()
                    practiceView.updateValues(
                        words: currentPractice.reorderingWordList!,
                        translation: currentPractice.reorderingTextTranslation!
                    )
                    practiceView.delegate = self
                    return practiceView
                }()
            case .phraseConstruction:
                return {
                    let practiceView = ReorderingPracticeView()
                    practiceView.updateValues(
                        words: currentPractice.reorderingWordList!,
                        translation: currentPractice.word
                    )
                    practiceView.delegate = self
                    return practiceView
                }()
            case .imageSelection:
                return {
                    let practiceView = ImageSelectionPracticeView()
                    practiceView.updateValues(
                        selectionTexts: currentPractice.choices!,
                        imageUrl: currentPractice.imageUrl!,
                        verbAspectAnnotations: currentPractice.choiceVerbAspectAnnotations,
                        nounCaseAnnotations: currentPractice.choiceNounCaseAnnotations
                    )
                    practiceView.delegate = self
                    return practiceView
                }()
            case .imageFilling:
                return {
                    let practiceView = ImageFillingPracticeView()
                    practiceView.updateValues(imageUrl: currentPractice.imageUrl!)
                    practiceView.delegate = self
                    return practiceView
                }()
            }
        }
        
        // Update the prompt.
        // IMPORTANT: SHOULD BE ABOVE THE SNP SETTING OF THE PRACTICE VIEW,
        // WHOSE TOP DEPENDS ON THE BOTTOM OF THE PROMPT VIEW.
        // OTHERWISE, THE LOCATIONS OF THE DRAGGABLE LABELS MAY BE WEIRD.
        let promptAttributes = NSMutableAttributedString(
            string: currentPractice.prompt,
            attributes: Attributes.practicePromptAttributes
        )
        // Highlight the practice word.
//        promptAttributes.add(
//            attributes: Attributes.practiceWordAttributes,
//            for: currentPractice.query
//        )
        grammarAnnotationLegendView.reset()

        // Strip accent symbols and bold the preceding letter BEFORE applying
        // grammar annotations, so annotation positions (computed on accent-free
        // text) remain correct after the removal of the ' characters.
        GrammarAnnotationHelper.applyAccentBold(to: promptAttributes)

        // Strip accent symbols from the query key too so we can locate it in the
        // now-stripped prompt string.
        let strippedQuery = currentPractice.query
            .replacingOccurrences(of: String(Token.accentSymbol), with: "")

        if let rangeOfPracticeWord = promptAttributes.string.range(
            of: strippedQuery,
            options: .backwards
        ) {
            let nsRangeOfPracticeWord = NSRange(
                rangeOfPracticeWord,
                in: promptAttributes.string
            )
            promptAttributes.addAttributes(
                Attributes.practiceWordAttributes,
                range: nsRangeOfPracticeWord
            )

            // Annotations are positioned relative to currentPractice.query;
            // offset them to their location within the full prompt string.
            let wordOffset = nsRangeOfPracticeWord.location
            if !currentPractice.verbAspectAnnotations.isEmpty {
                let offsetAnnotations = currentPractice.verbAspectAnnotations.map {
                    VerbAspectAnnotation(position: $0.position + wordOffset, length: $0.length, label: $0.label)
                }
                grammarAnnotationLegendView.markVerbAspects(in: promptAttributes, at: offsetAnnotations)
            }
            if !currentPractice.nounCaseAnnotations.isEmpty {
                let offsetAnnotations = currentPractice.nounCaseAnnotations.map {
                    NounCaseAnnotation(position: $0.position + wordOffset, length: $0.length, label: $0.label, isItalic: $0.isItalic)
                }
                grammarAnnotationLegendView.markNounCases(in: promptAttributes, at: offsetAnnotations)
            }
            if !currentPractice.shortAdjectiveAnnotations.isEmpty {
                let offsetAnnotations = currentPractice.shortAdjectiveAnnotations.map {
                    ShortAdjectiveAnnotation(position: $0.position + wordOffset, length: $0.length)
                }
                grammarAnnotationLegendView.markShortAdjectives(in: promptAttributes, at: offsetAnnotations)
            }
        }
        // Always keep the legend hidden (item 1(7): legend is never shown).
        grammarAnnotationLegendView.isHidden = true
        promptLabel.attributedText = promptAttributes
        let completed = initialPracticeCount - practiceProducer.practiceList.count
        progressLabel.text = "\(completed)/\(initialPracticeCount)"
        // Update phrase review progress bar.
        if selectedWordKeys != nil && initialPracticeCount > 0 {
            let progress = Float(completed) / Float(initialPracticeCount)
            phraseReviewProgressBar.setProgress(progress, animated: true)
        }
        
        // Remove the old practice view.
        if practiceView != nil {
            practiceView.removeFromSuperview()
        }
        // Make a new one.
        practiceView = makePracticeView()

        if
            let newPracticeView = practiceView as? ReorderingPracticeView,
            (
                newPracticeView.calculateRowNumber(
                    words: newPracticeView.words,
                    font: newPracticeView.wordBankItemFont,
                    itemHorizontalPadding: ReorderingPracticeView.rowStackHorizontalSpacing
                ) > ReorderingPracticeView.maxRowStackNum
                || newPracticeView.calculateRowNumber(
                    words: newPracticeView.shuffledWords,
                    font: newPracticeView.wordBankItemFont,
                    itemHorizontalPadding: ReorderingPracticeView.rowStackHorizontalSpacing
                ) > ReorderingPracticeView.maxWordBankNum
            )
        {
            self.nextButtonTapped()
            return
        }
        
        // Add to the main view and update layouts.
        mainView.addSubview(practiceView)
        practiceView.snp.makeConstraints { (make) in
            make.top.equalTo(grammarAnnotationLegendView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(PracticeViewController.practiceViewWidthRatio)
            make.bottom.equalTo(nextButton.snp.top).offset(-20)
        }
        
        // TODO: - Move elsewhere.
        if let practiceView = practiceView as? ReorderingPracticeView {
            view.layoutIfNeeded()
            // https://stackoverflow.com/questions/14020027/how-do-i-know-that-the-uicollectionview-has-been-loaded-completely
            practiceView.wordBank.reloadData()
            practiceView.wordBank.performBatchUpdates(nil, completion: { (_) in
                practiceView.makeDraggableWordBankItems()
            })
        }
        
        deactivateDoneButton()
    }
}

extension WordsPracticeViewController: WordPracticeViewDelegate {
    
    // MARK: - WordPracticeView Delegate
    
    func activateDoneButton() {
        doneButton.isEnabled = true
        doneButton.backgroundColor = Colors.lightBlue
    }
    
    func deactivateDoneButton() {
        doneButton.isEnabled = false
        doneButton.backgroundColor = Colors.lightGrayBackgroundColor
    }
}

extension WordsPracticeViewController {

    // MARK: - Selectors

    @objc override func toggleButtonTapped() {
        guard selectedWordKeys != nil else {
            // Normal practice mode: let the parent handle timing bar toggle.
            super.toggleButtonTapped()
            return
        }
        // Phrase review mode: no timing bar — drive mask/interaction directly.
        if toggleButton.image == Icons.pauseIcon {
            // Pause: show the mask and block interaction.
            maskView.isHidden = false
            mainView.isUserInteractionEnabled = false
            view.bringSubviewToFront(maskView)
            toggleButton.image = Icons.startIcon
        } else {
            // Resume: hide the mask and restore interaction.
            maskView.isHidden = true
            mainView.isUserInteractionEnabled = true
            toggleButton.image = Icons.pauseIcon
        }
    }

    @objc override func doneButtonTapped() {
        super.doneButtonTapped()
        
        let answer = (practiceView as! WordPracticeView).submit()
        practiceProducer.submit(answer: answer)
        
        if let currentPractice = practiceProducer.currentPractice as? WordPractice,
           let practiceView = practiceView as? WordPracticeView {
            
            practiceView.updateViewsAfterSubmission(
                for: currentPractice.correctness!,
                key: currentPractice.key,
                tokenizer: currentPractice.tokenizer
            )
            
        }
    }
    
    @objc override func nextButtonTapped() {

        guard !shouldFinishPracticing else {
            practiceMetaData["recentWordPracticeDate"] = Date().repr(of: Date.defaultDateAndTimeFormat)
            self.stopPracticing()
            return
        }

        // When in phrase-review mode, pre-generate next-round practices in the background
        // for the word we are about to finish.
        if selectedWordKeys != nil,
           let currentWordPractice = practiceProducer.currentPractice as? WordPractice {
            let wordForNextRound = currentWordPractice.word
            let lang = LangCode.currentLanguage
            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let self = self else { return }
                let schedule = EbbinghausSchedule.load(for: lang)
                let key = WordPracticeProducer.normalizedKey(from: wordForNextRound)
                guard let entry = schedule[key] else { return }
                let nextPeriod = entry.periodIndex + 1
                guard nextPeriod < EbbinghausSchedule.practiceGroups.count else { return }
                // Only pre-generate if no cached practices for this word in the next period exist yet.
                let cached = WordPracticeProducer.loadCachedPractices(for: lang)
                let hasNextRound = cached.contains { WordPracticeProducer.normalizedKey(from: $0.word) == key && ($0.periodIndex ?? 0) == nextPeriod }
                guard !hasNextRound else { return }
                let producer = WordPracticeProducer(words: self.words, articles: self.articles)
                producer.makeAndCachePractices(for: [wordForNextRound], skipDuplicates: false)
            }
        }

        super.nextButtonTapped()
        practiceProducer.next()
        if practiceProducer.practiceList.isEmpty {
            practiceMetaData["recentWordPracticeDate"] = Date().repr(of: Date.defaultDateAndTimeFormat)
            stopPracticing()
            return
        }

        updatePracticeView()
    }
}

extension WordsPracticeViewController {
    
    override func stopPracticing() {
        practiceProducer.cache()
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
}
