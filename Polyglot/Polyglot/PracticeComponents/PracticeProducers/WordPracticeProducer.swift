//
//  WordPracticeExtensions.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation
import UIKit
import NaturalLanguage

class WordPracticeProducer: BasePracticeProducer {
    
    private var lang: LangCode = LangCode.currentLanguage

    private var wordPracticeCounter: [String: Int] = [:]
    var excludedPractices: [WordPractice] = []

    /// Recomputes `wordPracticeCounter` from the current `practiceList`. Callers that replace
    /// `practiceList` after init (e.g. filtering down to a selected word set and deduplicating)
    /// must call this afterward -- otherwise the counter stays based on the stale pre-filter
    /// snapshot and `next()` never reaches zero for a word, so its Ebbinghaus period never
    /// advances even after all its practices are answered.
    func resetWordPracticeCounter() {
        self.wordPracticeCounter = WordPracticeProducer.countWordPractices(from: self.practiceList)
    }
    
    // MARK: - Init
    
    override init(words: [Word], articles: [Article]) {
        super.init(words: words, articles: articles)
        
        let cachedWordPractices = WordPracticeProducer.loadCachedPractices(for: LangCode.currentLanguage)
        if !cachedWordPractices.isEmpty {
            self.practiceList.append(contentsOf: cachedWordPractices)
            self.practiceList.shuffle()

            self.wordPracticeCounter = WordPracticeProducer.countWordPractices(from: self.practiceList)
        }
        
    }
    
    override func next() {
        
        let wordPractice = self.practiceList.removeFirst()
        if let wordPractice = wordPractice as? WordPractice {
            let key = Self.normalizedKey(from: wordPractice.word)
            if self.wordPracticeCounter.keys.contains(key) {
                self.wordPracticeCounter[key]! -= 1
                if self.wordPracticeCounter[key]! <= 0 {
                    self.wordPracticeCounter.removeValue(forKey: key)
                    self.advanceEbbinghausSchedule(forKey: key, consumedPeriodIndex: wordPractice.periodIndex ?? 0)
                }
            }
        }
        sendWordPracticeCounterUpdateNotification()
        
    }
    
    override func cache() {
        guard let selected = self.practiceList as? [WordPractice] else {
            return
        }
        var practicesToCache = selected + excludedPractices
        WordPracticeProducer.save(
            &practicesToCache,
            for: self.lang
        )
    }
}

extension WordPracticeProducer {
    
    private func addAccents(to practice: BasePractice, with accentedWord: String) {
        
        guard 
            self.lang == .ja
            || self.lang == .ru
        else {
            return
        }
                    
        guard let practice = practice as? WordPractice else {
            return
        }
        
        guard practice.practiceType != .meaningFilling else {
            return
        }
        guard practice.practiceType != .accentSelection else {
            return
        }
        guard practice.practiceType != .imageFilling else {
            return
        }

        let originalWord = practice.word

        practice.query = practice.query.replacingOccurrences(
            of: originalWord,
            with: accentedWord
        )
        practice.key = practice.key.replacingOccurrences(
            of: originalWord,
            with: accentedWord
        )
        // Do not use replacement for prompts.
        // Otherwise words in the prompts may be replaced.
        practice.prompt = prompt(
            for: practice.practiceType,
            withWord: practice.query
        )
        if practice.context != nil {
            practice.context! = practice.context!.replacingOccurrences(
                of: originalWord,
                with: accentedWord
            )
        }
        
        if practice.choices != nil {
            // Only replace choices that are in the target language (not meaning/translation text).
            let choicesAreTargetLanguage = practice.direction != .textToMeaning
                || (practice.practiceType != .meaningSelection && practice.practiceType != .meaningFilling)
            if choicesAreTargetLanguage {
                for (i, choice) in practice.choices!.enumerated() {
                    if choice == originalWord {
                        practice.choices![i] = accentedWord
                    }
                }
            }
        }
        
        if practice.reorderingWordList != nil {
            practice.reorderingWordList = practice.key
                .split(with: Strings.wordSeparator)
                .map { $0.replacingOccurrences(of: String(Token.accentSymbol), with: "") }
        }
            
    }
    
    private func sendWordPracticeCounterUpdateNotification() {
        // // https://stackoverflow.com/questions/55382533/how-to-observe-the-value-of-a-global-variable-and-act-on-a-change-within-the-vie
        NotificationCenter.default.post(Notification(
            name: .wordPracticeCounterUpdated, 
            object: nil, 
            userInfo: [
                "lang": self.lang,
                "wordPracticeCounter": self.wordPracticeCounter
            ]
        ))
    }
    
    private func advanceEbbinghausSchedule(forKey key: String, consumedPeriodIndex: Int) {
        let newPeriod = consumedPeriodIndex + 1
        EbbinghausSchedule.update(for: self.lang) { schedule in
            if newPeriod >= EbbinghausSchedule.practiceGroups.count {
                schedule.removeValue(forKey: key)
            } else {
                var entry = EbbinghausSchedule.entry(forKey: key, in: schedule)
                entry.periodIndex = newPeriod
                entry.nextReviewDate = EbbinghausSchedule.nextReviewDate(afterPeriod: consumedPeriodIndex)
                schedule[key] = entry
            }
        }
        if newPeriod >= EbbinghausSchedule.practiceGroups.count {
            // Remove from persistent reinforcement words now that all periods are done.
            ReinforcementWords.remove(word: key, for: self.lang)
        }
        // Purge this word's practices for the period just consumed (and any earlier stale
        // period) from the cache. Otherwise old-period records linger alongside newly
        // generated next-period ones; since the practice list is shuffled and per-type dedup
        // doesn't distinguish period, a stale old-period record can be picked back up for
        // "practice" instead of the real next-period one, making it look like progress never
        // advances.
        Self.update(for: self.lang) { practices in
            practices.removeAll {
                Self.normalizedKey(from: $0.word) == key && ($0.periodIndex ?? 0) <= consumedPeriodIndex
            }
        }
    }

    func makeAndCachePractices(for words: [String], skipDuplicates: Bool = true) {

        let nRepetitions = self.lang.configs.wordPracticeRepetition
        let enabledTypes = self.lang.configs.phraseReviewEnabledPracticeTypes

        var schedule = EbbinghausSchedule.load(for: self.lang)
        // Snapshot of what's already on disk (independent of `wordPracticeCounter`, which only
        // reflects what's currently in this instance's in-memory `practiceList`). Used to gate
        // generation per (word, type) so re-running this on an already-populated word doesn't
        // pile on duplicates -- this is checked instead of `skipDuplicates`'s whole-word skip so
        // partially-generated words (e.g. one type failed/pending) still get topped up correctly.
        let onDiskPractices = Self.loadCachedPractices(for: self.lang)

        for word in words {

            if skipDuplicates && wordPracticeCounter.keys.contains(Self.normalizedKey(from: word)) {
                continue
            }
            let key = Self.normalizedKey(from: word)
            wordPracticeCounter[key] = 0

            // Ensure a schedule entry exists for this word.
            if schedule[key] == nil {
                let newEntry = WordReviewEntry(wordKey: key, periodIndex: 0, nextReviewDate: .distantPast)
                schedule[key] = newEntry
                // Write atomically against the persisted file rather than overwriting it with
                // this possibly-stale in-memory `schedule` snapshot.
                EbbinghausSchedule.update(for: self.lang) { persisted in
                    if persisted[key] == nil {
                        persisted[key] = newEntry
                    }
                }
            }
            let periodIndex = schedule[key]!.periodIndex
            let typesToUse = EbbinghausSchedule.effectivePracticeTypes(
                for: periodIndex,
                enabledTypes: enabledTypes
            )

            // Existing on-disk count per type for this word+period, so we only generate the
            // deficit per type instead of a full batch every time this word is revisited.
            let existingForWord = onDiskPractices.filter {
                Self.normalizedKey(from: $0.word) == key && ($0.periodIndex ?? 0) == periodIndex
            }
            func neededCount(for type: WordPractice.PracticeType) -> Int {
                guard typesToUse.contains(type) else { return 0 }
                let existing = existingForWord.filter { $0.practiceType == type }.count
                let needed = max(0, nRepetitions - existing)
                print("[makeAndCachePractices] \(key) / \(type): existing=\(existing), generating=\(needed)")
                return needed
            }

            let neededAccentSelection = neededCount(for: .accentSelection)

            var practicesForWord: [WordPractice] = []

            let now = Date()
            let candidateWords = self.words.filter {
                guard $0.text != word else { return false }
                guard let entry = schedule[Self.normalizedKey(from: $0.text)] else { return false }
                return entry.nextReviewDate <= now
            }

            func stamp(_ p: WordPractice) -> WordPractice {
                p.periodIndex = periodIndex
                return p
            }

            let neededMeaningSelection = neededCount(for: .meaningSelection)
            let neededMeaningFilling = neededCount(for: .meaningFilling)
            if neededMeaningSelection > 0 || neededMeaningFilling > 0 {
                machineTranslator.translate(query: word) { translations, _ in
                    guard !translations.isEmpty else { return }
                    let meaning = translations.joined(separator: "; ")

                    for _ in 0..<neededMeaningSelection {
                        if let p = self.makeMeaningSelectionPractice(
                            word: word, query: word, key: meaning,
                            direction: .textToMeaning, preferredWords: candidateWords
                        ) {
                            self.practiceList.append(stamp(p))
                            self.wordPracticeCounter[key]! += 1
                            practicesForWord.append(p)
                        }
                        if let p = self.makeMeaningSelectionPractice(
                            word: word, query: meaning, key: word,
                            direction: .meaningToText, preferredWords: candidateWords
                        ) {
                            self.practiceList.append(stamp(p))
                            self.wordPracticeCounter[key]! += 1
                            practicesForWord.append(p)
                        }
                    }
                    for _ in 0..<neededMeaningFilling {
                        let p = self.makeMeaningFillingPractice(
                            word: word, query: meaning, key: word, direction: .meaningToText
                        )
                        self.practiceList.append(stamp(p))
                        self.wordPracticeCounter[key]! += 1
                        practicesForWord.append(p)
                    }
                    self.cache()
                    self.sendWordPracticeCounterUpdateNotification()
                }
            }

            let neededContextSelection = neededCount(for: .contextSelection)
            if neededContextSelection > 0 {
                for _ in 0..<neededContextSelection {
                    if let p = makeContextSelectionPractice(word: word, query: word, preferredWords: candidateWords) {
                        practiceList.append(stamp(p))
                        wordPracticeCounter[key]! += 1
                        practicesForWord.append(p)
                    }
                }
            }
            self.cache()
            self.sendWordPracticeCounterUpdateNotification()

            let neededReordering = neededCount(for: .reordering)
            if neededReordering > 0 {
                for _ in 0..<neededReordering {
                    makeReorderingPractice(word: word, query: word) { practice in
                        if let p = practice {
                            self.practiceList.append(stamp(p))
                            self.wordPracticeCounter[key]! += 1
                            practicesForWord.append(p)
                            self.cache()
                            self.sendWordPracticeCounterUpdateNotification()
                        }
                    }
                }
            }

            let neededImageSelection = neededCount(for: .imageSelection)
            let neededImageFilling = neededCount(for: .imageFilling)
            if neededImageSelection > 0 || neededImageFilling > 0 {
                imageCreator.generateImage(for: word) { imageUrl in
                    guard let imageUrl = imageUrl else { return }
                    for _ in 0..<neededImageSelection {
                        if let p = self.makeImageSelectionPractice(word: word, imageUrl: imageUrl, preferredWords: candidateWords) {
                            self.practiceList.append(stamp(p))
                            self.wordPracticeCounter[key]! += 1
                            practicesForWord.append(p)
                        }
                        self.cache()
                        self.sendWordPracticeCounterUpdateNotification()
                    }
                    for _ in 0..<neededImageFilling {
                        let p = self.makeImageFillingPractice(word: word, imageUrl: imageUrl)
                        self.practiceList.append(stamp(p))
                        self.wordPracticeCounter[key]! += 1
                        practicesForWord.append(p)
                        self.cache()
                        self.sendWordPracticeCounterUpdateNotification()
                    }
                }
            }

            let neededPhraseConstruction = neededCount(for: .phraseConstruction)
            if neededPhraseConstruction > 0 {
                for _ in 0..<neededPhraseConstruction {
                    if let p = makePhraseConstructionPractice(word: word) {
                        practiceList.append(stamp(p))
                        wordPracticeCounter[key]! += 1
                        practicesForWord.append(p)
                    }
                }
                self.cache()
                self.sendWordPracticeCounterUpdateNotification()
            }

            analyzeAccents(for: word) { tokens, fixedText, text in
                guard !tokens.isEmpty else { return }

                let needsAspect = LangCode.currentLanguage.configs.shouldShowVerbAspectsInPractices
                let needsNounCase = LangCode.currentLanguage.configs.shouldShowNounCasesInPractices
                if needsAspect || needsNounCase {
                    for practice in practicesForWord {
                        if needsAspect {
                            practice.verbAspectAnnotations = calculateVerbAspectAnnotations(for: practice.query, with: tokens)
                        }
                        if needsNounCase {
                            practice.nounCaseAnnotations = calculateNounCaseAnnotations(for: practice.query, with: tokens)
                            practice.shortAdjectiveAnnotations = calculateShortAdjectiveAnnotations(for: practice.query, with: tokens)
                        }
                        // Annotate Russian choices (meaningToText direction or contextSelection).
                        if let choices = practice.choices,
                           practice.direction == .meaningToText || practice.practiceType == .contextSelection {
                            practice.choiceVerbAspectAnnotations = Array(repeating: [], count: choices.count)
                            practice.choiceNounCaseAnnotations = Array(repeating: [], count: choices.count)
                            for (i, choice) in choices.enumerated() {
                                analyzeAccents(for: choice) { choiceTokens, _, _ in
                                    guard !choiceTokens.isEmpty else { return }
                                    if needsAspect {
                                        practice.choiceVerbAspectAnnotations[i] = calculateVerbAspectAnnotations(for: choice, with: choiceTokens)
                                    }
                                    if needsNounCase {
                                        practice.choiceNounCaseAnnotations[i] = calculateNounCaseAnnotations(for: choice, with: choiceTokens)
                                    }
                                    self.cache()
                                }
                            }
                        }

                        // Annotate Russian context sentence.
                        if let context = practice.context, practice.practiceType == .contextSelection {
                            analyzeAccents(for: context) { contextTokens, _, _ in
                                guard !contextTokens.isEmpty else { return }
                                if needsAspect {
                                    practice.contextVerbAspectAnnotations = calculateVerbAspectAnnotations(for: context, with: contextTokens)
                                }
                                if needsNounCase {
                                    practice.contextNounCaseAnnotations = calculateNounCaseAnnotations(for: context, with: contextTokens)
                                }
                                self.cache()
                            }
                        }
                    }
                }
                for practice in practicesForWord {
                    practice.isGrammarAnnotationCompleted = true
                }

                let accentedWord = Self.joinTokensPreservingPunctuation(tokens.accentedPronunciations, separator: Strings.wordSeparator)
                for practice in practicesForWord {
                    self.addAccents(to: practice, with: accentedWord)
                    practice.isAccentAnnotationCompleted = true
                }

                for _ in 0..<neededAccentSelection {
                    if let p = self.makeAccentSelectionPractice(
                        word: fixedText ?? text, query: fixedText ?? text, tokens: tokens
                    ) {
                        p.periodIndex = periodIndex
                        self.practiceList.append(p)
                        self.wordPracticeCounter[key]! += 1
                    }
                }
                self.cache()
                self.sendWordPracticeCounterUpdateNotification()
            }
        }
    }

    /// Re-annotate existing cached practices for a word that are missing accent or grammar annotations.
    func annotateExistingPractices(for key: String, completion: (() -> Void)? = nil) {
        let lang = self.lang
        let needsAccent = lang == .ja || lang == .ru
        let needsAspect = lang.configs.shouldShowVerbAspectsInPractices
        let needsNounCase = lang.configs.shouldShowNounCasesInPractices
        guard needsAccent || needsAspect || needsNounCase else { completion?(); return }

        let allPractices = Self.loadCachedPractices(for: lang)
        let schedule = EbbinghausSchedule.load(for: lang)
        let periodIndex = EbbinghausSchedule.entry(forKey: key, in: schedule).periodIndex

        let targets = allPractices.filter {
            Self.normalizedKey(from: $0.word) == key
                && ($0.periodIndex ?? 0) == periodIndex
                && (!$0.isAccentAnnotationCompleted || !$0.isGrammarAnnotationCompleted)
        }
        guard !targets.isEmpty else { completion?(); return }

        let word = targets.first!.word

        analyzeAccents(for: word) { tokens, _, _ in
            guard !tokens.isEmpty else {
                completion?()
                return
            }

            for practice in targets {
                if !practice.isGrammarAnnotationCompleted {
                    if needsAspect {
                        practice.verbAspectAnnotations = calculateVerbAspectAnnotations(for: practice.query, with: tokens)
                    }
                    if needsNounCase {
                        practice.nounCaseAnnotations = calculateNounCaseAnnotations(for: practice.query, with: tokens)
                        practice.shortAdjectiveAnnotations = calculateShortAdjectiveAnnotations(for: practice.query, with: tokens)
                    }
                    if let choices = practice.choices,
                       practice.direction == .meaningToText || practice.practiceType == .contextSelection {
                        practice.choiceVerbAspectAnnotations = Array(repeating: [], count: choices.count)
                        practice.choiceNounCaseAnnotations = Array(repeating: [], count: choices.count)
                        for (i, choice) in choices.enumerated() {
                            analyzeAccents(for: choice) { choiceTokens, _, _ in
                                guard !choiceTokens.isEmpty else { return }
                                if needsAspect {
                                    practice.choiceVerbAspectAnnotations[i] = calculateVerbAspectAnnotations(for: choice, with: choiceTokens)
                                }
                                if needsNounCase {
                                    practice.choiceNounCaseAnnotations[i] = calculateNounCaseAnnotations(for: choice, with: choiceTokens)
                                }
                            }
                        }
                    }
                    if let context = practice.context, practice.practiceType == .contextSelection {
                        analyzeAccents(for: context) { contextTokens, _, _ in
                            guard !contextTokens.isEmpty else { return }
                            if needsAspect {
                                practice.contextVerbAspectAnnotations = calculateVerbAspectAnnotations(for: context, with: contextTokens)
                            }
                            if needsNounCase {
                                practice.contextNounCaseAnnotations = calculateNounCaseAnnotations(for: context, with: contextTokens)
                            }
                        }
                    }
                    practice.isGrammarAnnotationCompleted = true
                }
                if !practice.isAccentAnnotationCompleted {
                    let accentedWord = Self.joinTokensPreservingPunctuation(tokens.accentedPronunciations, separator: Strings.wordSeparator)
                    self.addAccents(to: practice, with: accentedWord)
                    practice.isAccentAnnotationCompleted = true
                }
            }

            // Re-read the file fresh and splice in the mutated targets by id, instead of
            // overwriting with the `allPractices` snapshot taken before this async work
            // started -- avoids clobbering concurrent writes from other callers.
            let mutatedById = Dictionary(uniqueKeysWithValues: targets.map { ($0.id, $0) })
            WordPracticeProducer.update(for: lang) { practices in
                for i in practices.indices {
                    if let mutated = mutatedById[practices[i].id] {
                        practices[i] = mutated
                    }
                }
            }

            completion?()
        }
    }

}

extension WordPracticeProducer {

    func submit(answer: String) {

        guard let currentPractice = currentPractice as? WordPractice else {
            return
        }
        currentPractice.checkCorrectness(answer: answer)

        if currentPractice.correctness != .correct {
            // Re-add the practice for reinforcement.
            DispatchQueue.global(qos: .userInitiated).async {
                let practiceForReinforcement = WordPractice(from: currentPractice)
                practiceForReinforcement.correctness = nil
                
                self.practiceList.append(practiceForReinforcement)
                let key = Self.normalizedKey(from: practiceForReinforcement.word)
                self.wordPracticeCounter[key] = (self.wordPracticeCounter[key] ?? 0) + 1
                self.sendWordPracticeCounterUpdateNotification()
            }
        }
    }
    
}

extension WordPracticeProducer {
        
    private func promptTemplate(for practiceType: WordPractice.PracticeType) -> String {
        
        switch practiceType {
        case .meaningSelection, .meaningFilling:
            return Strings.meaningSelectionAndFillingPracticePrompt
        case .contextSelection:
            return Strings.contextSelectionPracticePrompt
        case .accentSelection:
            return Strings.accentSelectionPracticePrompt
        case .reordering:
            return Strings.reorderingPracticePrompt
        case .imageSelection:
            return Strings.imageSelectionPracticePrompt
        case .imageFilling:
            return Strings.imageFillingPracticePrompt
        case .phraseConstruction:
            return Strings.phraseConstructionPracticePrompt
        }
        
    }
    
    private func prompt(for practiceType: WordPractice.PracticeType, withWord wordInPrompt: String) -> String {
        return promptTemplate(for: practiceType).replacingOccurrences(
            of: Strings.maskToken,
            with: wordInPrompt
        )
    }
    
    private func choices(for wordToPractice: String, textForChoice: (Word) -> String, preferredWords: [Word] = []) -> [String]? {

        guard self.words.count >= Self.defaultChoiceNumber else {
            return nil
        }

        var choices: [String] = [wordToPractice]

        // Normalize for dedup: strip accent symbols then normalize (case-insensitive)
        // so variants like "сло'во"/"слово" or "Hello"/"hello" are not both added as choices.
        func normalized(_ s: String) -> String {
            s.replacingOccurrences(of: String(Token.accentSymbol), with: "")
             .normalized(caseInsensitive: true)
        }
        func choicesContains(_ candidate: String) -> Bool {
            let n = normalized(candidate)
            return choices.contains { normalized($0) == n }
        }

        var shuffledPreferred = preferredWords.shuffled()
        while choices.count < Self.defaultChoiceNumber && !shuffledPreferred.isEmpty {
            let choice = textForChoice(shuffledPreferred.removeFirst())
            if !choicesContains(choice) {
                choices.append(choice)
            }
        }

        var loopCount = 0
        while choices.count < Self.defaultChoiceNumber {
            let choice = textForChoice(self.words.randomElement()!)
            if !choicesContains(choice) || loopCount >= Self.maxChoiceLoopCount {
                choices.append(choice)
            }
            loopCount += 1
        }

        choices.shuffle()
        return choices

    }
    
    private func makeMeaningSelectionPractice(
        word: String,
        query: String,
        key: String,
        direction: WordPractice.PracticeDirection,
        preferredWords: [Word] = []
    ) -> WordPractice? {

        guard let choices = choices(
            for: key,
            textForChoice: {
                direction == .textToMeaning ? $0.meaning : $0.text
            },
            preferredWords: preferredWords
        ) else {
            return nil
        }
        
        return WordPractice(
            practiceType: .meaningSelection,
            word: word,
            query: query,
            key: key,
            prompt: prompt(for: .meaningSelection, withWord: query),
            choices: choices,
            direction: direction
        )
        
    }
    
    private func makeMeaningFillingPractice(
        word: String,
        query: String,
        key: String,
        direction: WordPractice.PracticeDirection
    ) -> WordPractice {
        
        return WordPractice(
            practiceType: .meaningFilling,
            word: word,
            query: query,
            key: key,
            prompt: prompt(for: .meaningFilling, withWord: query),
            direction: direction
        )
        
    }
    
    private func makeContextSelectionPractice(
        word: String,
        query: String,
        preferredWords: [Word] = []
    ) -> WordPractice? {

        guard let choices = choices(
            for: query,
            textForChoice: { $0.text },
            preferredWords: preferredWords
        ) else {
            return nil
        }

        // Try to use stored context sentence from ReinforcementWords first (item 1(2)a).
        let reinforcementStore = ReinforcementWords.load(for: self.lang)
        let key = Self.normalizedKey(from: word)
        let contextText: String?
        var articleId: String? = nil
        var paragraphId: String? = nil

        if let stored = reinforcementStore[key], !stored.contextSentence.isEmpty {
            contextText = stored.contextSentence
        } else {
            // Fall back to article paragraph if no stored context sentence.
            let candidates = articles.paraCandidates(for: query)
            guard candidates.count != 0,
                  let candidate = candidates.randomElement()
            else {
                return nil
            }
            contextText = candidate.text
            articleId = candidate.articleId
            paragraphId = candidate.paraId
        }

        guard let contextText = contextText else {
            return nil
        }

        return WordPractice(
            practiceType: .contextSelection,
            word: word,
            query: query,
            key: query,
            prompt: prompt(for: .contextSelection, withWord: query),
            choices: choices,
            context: contextText.trimmingCharacters(in: .whitespaces).replacingOccurrences(
                of: query,
                with: Strings.underscoreToken,
                options: [.caseInsensitive, .diacriticInsensitive]
            ),
            articleId: articleId,
            paragraphId: paragraphId,
            direction: .text
        )

    }
    
    private func makeAccentSelectionPractice(
        word: String,
        query: String,
        tokens: [Token]
    ) -> WordPractice? {
        
        // Not needed for one-syllable words.
        guard tokens.pronunciations.joined(separator: "").count >= 2 else {
            return nil
        }
        
        // TODO: - nil and -1 produces the same accented pronunciation.
        
        func makePronunciationsWith(accents: [Int?], and tokens: [Token]) -> String? {
            guard accents.count == tokens.count else {
                return nil
            }
            
            var tokens = tokens
            for (i, accent) in accents.enumerated() {
                tokens[i].accentLoc = accent
            }
            
            let accentedTokenPronunciations = languageSpecificPreprocess(tokens.accentedPronunciations)
            let accentedWord = Self.joinTokensPreservingPunctuation(accentedTokenPronunciations, separator: Strings.wordSeparator)
            return accentedWord
        }
        
        func generateRandomAccentLocs(for tokens: [Token]) -> [Int?] {
            return tokens.pronunciations.map({ (pronunciation) -> Int? in
                if pronunciation.count > 1 {  // Old jp accent interface or other langs (e.g., Russian).
                    // E.g., if the pronunciation has two chars,
                    // vals will be [0, 1].
                    var vals: [Int?] = Array<Int>(0..<pronunciation.count)
                    // Add a nil for other situations, e.g., no accent.
                    vals += [nil]
                    
                    return vals.randomElement()!
                } else {  // New jp accent interface.
                    let rand: Float = Float.random(in: 0...1)
                    if rand < 0.8 {  // No accent in most cases.
                        return nil
                    } else {
                        return 0
                    }
                }
            })
        }
        
        func hasSingleVowelOrJo(inAccentedRussianTokenPronunciation accentedRussianTokenPronunciation: String) -> Bool {
            var vowelCount = 0
            var joCount = 0
            for char in Array(accentedRussianTokenPronunciation) {
                if char == Token.accentSymbol {
                    continue
                }
                if Tokens.russianVowels.contains(String(char)) {
                    vowelCount += 1
                }
                if Tokens.russianJos.contains(String(char)) {
                    joCount += 1
                }
            }
            
            if vowelCount == 1 {
                return true
            }
            if joCount == 1 {
                return true
            }
            return false
        }
        
        func languageSpecificPreprocess(_ accentedTokenPronunciations: [String]) -> [String] {
            if LangCode.currentLanguage != .ru {
                return accentedTokenPronunciations
            }
            
            var accentedTokenPronunciations = accentedTokenPronunciations
            for (i, accentedTokenPronunciation) in accentedTokenPronunciations.enumerated() {
                if hasSingleVowelOrJo(inAccentedRussianTokenPronunciation: accentedTokenPronunciation) {
                    accentedTokenPronunciations[i] = accentedTokenPronunciations[i].replacing(
                        String(Token.accentSymbol),
                        with: ""
                    )
                }
            }
            return accentedTokenPronunciations
        }
        
        func matchLanguageSpecificRequirements(_ accentedText: String) -> Bool {
            
            if LangCode.currentLanguage == .ru {
                
                var previousChar: Character?
                for currentChar in accentedText {
                    // 如果当前是重音符号，检查前一个字符
                    if currentChar == Token.accentSymbol {
                        // 重音不能在第一位
                        guard let prev = previousChar else {
                            return false
                        }
                        // 前一个必须是俄语元音
                        guard Tokens.russianVowels.contains(prev) else {
                            return false
                        }
                    }
                    
                    // 更新前一个字符
                    previousChar = currentChar
                }
                
                // 所有重音都合法
                return true
            }
            
            return true
        }
        
        let accentedTokenPronunciations = languageSpecificPreprocess(tokens.accentedPronunciations)
        let accentedWord = Self.joinTokensPreservingPunctuation(accentedTokenPronunciations, separator: Strings.wordSeparator)
        // Not needed for Russian words without accents.
        if LangCode.currentLanguage == .ru && tokens.pronunciations == tokens.accentedPronunciations {
            return nil
        }
        var selectionTexts = [accentedWord]
        
        // Randomly generate two accent sequences.
        var maxNTries: Int = Self.defaultChoiceNumber * 3
        while true {
            // Generate a random accent sequence.
            let selectionAccentLocs = generateRandomAccentLocs(for: tokens)
            guard let selectionText = makePronunciationsWith(
                accents: selectionAccentLocs,
                and: tokens
            ) else {
                continue
            }
            
            if !matchLanguageSpecificRequirements(selectionText) {
                continue
            }
            if selectionTexts.contains(selectionText) {
                continue
            }
            selectionTexts.append(selectionText)
            
            if selectionTexts.count == Self.defaultChoiceNumber {
                break
            }

            maxNTries -= 1
            if maxNTries <= 0 {
                return nil
            }
        }
        selectionTexts.shuffle()
                
        return WordPractice(
            practiceType: .accentSelection,
            word: word,
            query: query,
            key: accentedWord,
            prompt: prompt(for: .accentSelection, withWord: query),
            choices: selectionTexts,
            direction: .text
        )
        
    }
    
    private func makeReorderingPractice(
        word: String,
        query: String,
        completion: @escaping (WordPractice?) -> Void
    ) {
        
        let candidates = articles.paraCandidates(for: query)
        guard candidates.count != 0,
              let candidate = candidates.randomElement() 
        else {
            completion(nil)
            return
        }
        
        let sentences = candidate.text.tokenized(with: self.lang.sentenceTokenizer)
        guard let targetSentence = sentences.first(where: { (sentence) -> Bool in
            sentence.contains(query)
        }) else {
            completion(nil)
            return
        }
        
        // Using the whole target sentence will
        // result in too many words,
        // so use the target subsentence instead.
        let subSentences = targetSentence.split(with: Strings.subsentenceSeparator)
        guard let targetSubSentence = subSentences.first(where: { (subSentence) -> Bool in
            subSentence.contains(query)
        }) else {
            completion(nil)
            return
        }
        
        // Reduce the number of tokens.
        // TODO: - Improvement.
        let rawWords = targetSubSentence.tokenized(with: self.lang.wordTokenizer)
        var words: [String] = []
        if self.lang == LangCode.ja {
            var indexOfLastWord: Int = -1
            for i in 0..<rawWords.count {
                let rawWord = rawWords[i]
                if i > 0 && Tokens.japaneseParticles.contains(rawWord) {
                    words[indexOfLastWord] = words[indexOfLastWord] + rawWord
                } else {
                    words.append(rawWord)
                    indexOfLastWord += 1
                }
            }
        } else {
            words = rawWords
        }
        
        if words.isEmpty {
            print("Empty words. Target subsentence: \(targetSubSentence). Skipping.")
            completion(nil)
            return
        }

        // Strip accent symbols so displayed word-bank labels (which applyAccentBold
        // already strips) match the key during correctness checking.
        words = words.map { $0.replacingOccurrences(of: String(Token.accentSymbol), with: "") }
        
        // Check line number.
        // TODO: - Update here. It's not proper to call calculateRowNumber() here.
//        if ReorderingPracticeView.calculateRowNumber(words: words) > 3 {
//            print("The subsentence is too long. Skipping. Subsentence: \(targetSentence)")
//            completion(nil)
//        }
        
        machineTranslator.translate(query: targetSubSentence) { translations, _ in
            guard let translation = translations.first else {
                completion(nil)
                return
            }
            completion(WordPractice(
                practiceType: .reordering,
                word: word,
                query: query,
                key: Self.joinTokensPreservingPunctuation(words, separator: Strings.wordSeparator),
                prompt: self.prompt(for: .reordering, withWord: query),
                reorderingWordList: words,
                reorderingTextTranslation: translation,
                articleId: candidate.articleId,
                paragraphId: candidate.paraId,
                direction: .text
            ))
        }
                
    }

    private func makeImageSelectionPractice(word: String, imageUrl: String, preferredWords: [Word] = []) -> WordPractice? {
        guard let choices = choices(for: word, textForChoice: { $0.text }, preferredWords: preferredWords) else {
            return nil
        }
        return WordPractice(
            practiceType: .imageSelection,
            word: word,
            query: word,
            key: word,
            prompt: prompt(for: .imageSelection, withWord: word),
            choices: choices,
            imageUrl: imageUrl,
            direction: .meaningToText
        )
    }

    private func makeImageFillingPractice(word: String, imageUrl: String) -> WordPractice {
        return WordPractice(
            practiceType: .imageFilling,
            word: word,
            query: word,
            key: word,
            prompt: prompt(for: .imageFilling, withWord: word),
            imageUrl: imageUrl,
            direction: .meaningToText
        )
    }

    private func makePhraseConstructionPractice(word: String) -> WordPractice? {
        let chunks = word.syllabified(for: self.lang)
        guard !chunks.isEmpty else { return nil }
        return WordPractice(
            practiceType: .phraseConstruction,
            word: word,
            query: word,
            key: Self.joinTokensPreservingPunctuation(chunks, separator: Strings.wordSeparator),
            prompt: prompt(for: .phraseConstruction, withWord: word),
            reorderingWordList: chunks,
            direction: .text
        )
    }

}

extension WordPracticeProducer {

    // MARK: - IO
    
    static func fileName(for lang: String) -> String {
        return "cachedWordPractices.\(lang).json"
    }

    static func loadCachedPractices(for lang: LangCode) -> [WordPractice] {
        withFileLock(fileName(for: lang.rawValue)) {
            loadCachedPracticesUnlocked(for: lang)
        }
    }

    static func save(_ practicesToCache: inout [WordPractice], for lang: LangCode) {
        let captured = practicesToCache
        withFileLock(fileName(for: lang.rawValue)) {
            saveUnlocked(captured, for: lang)
        }
    }

    /// Atomically loads, mutates, and saves the cached practices -- eliminates the
    /// read-modify-write race between this and any other caller (on any thread)
    /// that also goes through `loadCachedPractices`/`save`/`update`.
    @discardableResult
    static func update<T>(
        for lang: LangCode,
        _ mutate: (inout [WordPractice]) -> T
    ) -> T {
        withFileLock(fileName(for: lang.rawValue)) {
            var practices = loadCachedPracticesUnlocked(for: lang)
            let result = mutate(&practices)
            saveUnlocked(practices, for: lang)
            return result
        }
    }

    private static func loadCachedPracticesUnlocked(for lang: LangCode) -> [WordPractice] {
        do {
            let practices = try readDataFromJson(
                fileName: WordPracticeProducer.fileName(for: lang.rawValue),
                type: [WordPractice].self
            ) as? [WordPractice] ?? []

            return practices
        } catch {
            print(error)
            return []
        }
    }

    private static func saveUnlocked(_ practicesToCache: [WordPractice], for lang: LangCode) {
        do {
            try writeDataToJson(
                fileName: WordPracticeProducer.fileName(for: lang.rawValue),
                data: practicesToCache
            )
        } catch {
            print(error)
        }
    }

}

extension WordPracticeProducer {
    
    // MARK: - Constants

    private static let defaultChoiceNumber: Int = 3
    private static let maxChoiceLoopCount: Int = 30

    // MARK: - Class methods

    static func makeKeyForWordPracticeCount(from word: String) -> String {
        return word.replacingOccurrences(
            of: String(Token.accentSymbol),
            with: ""
        )
    }
    
    static func countWordPractices(for lang: LangCode) -> [String: Int] {
        return Self.countWordPractices(from: Self.loadCachedPractices(for: lang))
    }

    static func normalizedKey(from word: String) -> String {
        let stripped = makeKeyForWordPracticeCount(from: word).lowercased()
        return stripped.replacingOccurrences(of: #"\s*([^\w\s])\s*"#, with: "$1", options: .regularExpression)
    }

    /// Joins tokens with `separator`, but omits the separator before a token
    /// that is pure punctuation (e.g. ",") -- otherwise tokenizing a phrase
    /// like "a, b" and rejoining with a space separator produces "a , b".
    static func joinTokensPreservingPunctuation(_ tokens: [String], separator: String) -> String {
        var result = ""
        for token in tokens {
            let isPunctuation = token.range(of: #"^[^\w\s]+$"#, options: .regularExpression) != nil
            if !result.isEmpty && !isPunctuation {
                result += separator
            }
            result += token
        }
        return result
    }

    static func deleteWordPractices(forKey key: String, lang: LangCode) {
        Self.update(for: lang) { practices in
            practices.removeAll { normalizedKey(from: $0.word) == key }
        }
    }

    static func uniqueWordEntries(for lang: LangCode) -> [(key: String, meaning: String)] {
        let practices = Self.loadCachedPractices(for: lang)
        var seen = Set<String>()
        var meaningByKey: [String: String] = [:]
        var fallbackMeaningByKey: [String: String] = [:]
        var entries: [(key: String, meaning: String)] = []
        for p in practices {
            let wordKey = normalizedKey(from: p.word)
            if seen.insert(wordKey).inserted {
                entries.append((key: wordKey, meaning: ""))
            }
            if meaningByKey[wordKey] == nil {
                switch (p.practiceType, p.direction) {
                case (.meaningSelection, .textToMeaning), (.meaningFilling, .textToMeaning):
                    meaningByKey[wordKey] = p.key
                case (.meaningSelection, .meaningToText), (.meaningFilling, .meaningToText):
                    meaningByKey[wordKey] = p.query
                default:
                    if fallbackMeaningByKey[wordKey] == nil {
                        let candidate = p.key.isEmpty ? p.query : p.key
                        if !candidate.isEmpty && candidate != wordKey {
                            fallbackMeaningByKey[wordKey] = candidate
                        }
                    }
                }
            }
        }
        return entries.map { (key: $0.key, meaning: meaningByKey[$0.key] ?? fallbackMeaningByKey[$0.key] ?? "") }
    }
    
    static func countWordPractices(from practiceList: [BasePractice]) -> [String: Int] {
        
        var wordPracticeCounter: [String: Int] = [:]
        for wordPractice in practiceList {
            guard let wordPractice = wordPractice as? WordPractice else {
                continue
            }
            let word = wordPractice.word
            
            let key = Self.normalizedKey(from: word)
            if wordPracticeCounter.keys.contains(key) {
                wordPracticeCounter[key]! += 1
            } else {
                wordPracticeCounter[key] = 1
            }
        }
        return wordPracticeCounter
        
    }
    
}

extension Notification.Name {
    static let wordPracticeCounterUpdated = Notification.Name("wordPracticeCounterUpdated")
}
