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

    // `makeAndCachePractices` fires several independent async branches per word (meaning
    // translation, reordering, image generation, accent analysis) that all mutate
    // `wordPracticeCounter`/`practiceList` and call `cache()` from their own completion
    // callbacks, with no guarantee about relative ordering or which thread they land on.
    // Without serialization this is a lost-update race on the counter dictionary and a
    // data race on the practiceList array (both undefined behavior for concurrent mutation),
    // which is what caused the displayed practice-count digit to visibly bounce between
    // correct and stale values while image generation was in flight (analysis.md 新需求 9).
    private let stateQueue = DispatchQueue(label: "com.polyglot.wordPracticeProducer.state")

    @discardableResult
    private func mutate<T>(_ body: () -> T) -> T {
        stateQueue.sync(execute: body)
    }

    // Multiple independent `WordPracticeProducer` instances (reinforcement while reading,
    // `PhraseReviewWordSelectionViewController.backgroundRefresh()`, the word-practice list
    // itself) can call `makeAndCachePractices` for the same word at nearly the same time.
    // `makeAndCachePractices` decides how many practices of each type to generate from a
    // snapshot of what's already on disk (`neededCount`), taken once per call -- with no
    // cross-instance mutual exclusion, two concurrent calls can each see "0 existing" and
    // both generate a full batch, producing duplicate `WordPractice` records with different
    // `id`s for what should be a single practice slot (analysis.md 新需求 9, bug 4a). This
    // process-wide gate makes "is word X currently being generated" a single source of truth
    // so a second concurrent call for the same word skips entirely instead of duplicating.
    private static let generationGateLock = NSLock()
    private static var keysInGeneration: Set<String> = []

    private static func tryBeginGeneration(for key: String) -> Bool {
        generationGateLock.lock()
        defer { generationGateLock.unlock() }
        guard !keysInGeneration.contains(key) else { return false }
        keysInGeneration.insert(key)
        return true
    }

    private static func endGeneration(for key: String) {
        generationGateLock.lock()
        defer { generationGateLock.unlock() }
        keysInGeneration.remove(key)
    }

    /// Recomputes `wordPracticeCounter` from the current `practiceList`. Callers that replace
    /// `practiceList` after init (e.g. filtering down to a selected word set and deduplicating)
    /// must call this afterward -- otherwise the counter stays based on the stale pre-filter
    /// snapshot and `next()` never reaches zero for a word, so its Ebbinghaus period never
    /// advances even after all its practices are answered.
    func resetWordPracticeCounter() {
        mutate {
            self.wordPracticeCounter = WordPracticeProducer.countWordPractices(from: self.practiceList)
        }
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

        var consumed: (key: String, periodIndex: Int)? = nil
        mutate {
            let wordPractice = self.practiceList.removeFirst()
            if let wordPractice = wordPractice as? WordPractice {
                let key = Self.normalizedKey(from: wordPractice.word)
                if self.wordPracticeCounter.keys.contains(key) {
                    self.wordPracticeCounter[key]! -= 1
                    if self.wordPracticeCounter[key]! <= 0 {
                        self.wordPracticeCounter.removeValue(forKey: key)
                        consumed = (key, wordPractice.periodIndex ?? 0)
                    }
                }
            }
        }
        if let consumed = consumed {
            self.advanceEbbinghausSchedule(forKey: consumed.key, consumedPeriodIndex: consumed.periodIndex)
        }
        sendWordPracticeCounterUpdateNotification()
        
    }
    
    override func cache() {
        let practicesToCache: [WordPractice]? = mutate {
            guard let selected = self.practiceList as? [WordPractice] else {
                return nil
            }
            return selected + excludedPractices
        }
        guard let practicesToCache = practicesToCache else {
            return
        }
        // Upsert by `id` into a freshly-read copy of the on-disk array instead of
        // blindly overwriting it with this instance's in-memory snapshot. Multiple
        // independent `WordPracticeProducer` instances (backgroundRefresh, reinforcement
        // from reading/listening practices, the word list itself) each hold their own
        // stale snapshot; a blind overwrite here would clobber annotation flags/practices
        // another instance already persisted after this snapshot was taken (analysis.md
        // 新需求 9.3).
        let byId = Dictionary(uniqueKeysWithValues: practicesToCache.map { ($0.id, $0) })
        WordPracticeProducer.update(for: self.lang) { practices in
            var seenIds = Set<UUID>()
            for i in practices.indices {
                if let updated = byId[practices[i].id] {
                    practices[i] = updated
                    seenIds.insert(practices[i].id)
                }
            }
            for practice in practicesToCache where !seenIds.contains(practice.id) {
                practices.append(practice)
            }
        }
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

    // Grammar annotations (verb aspect / noun case / short adjective) are computed on the
    // plain, un-accented practice.query. addAccents() then inserts one Token.accentSymbol
    // per token into practice.query, shifting every character at or after each insertion
    // point by +1. Without this correction, annotation position/length -- especially the
    // verb-root/adjectival-suffix/reflexive-ся split for participles -- point at the wrong
    // characters once the accent symbols are in place.
    private func shiftForAccentInsertions(position: Int, length: Int, accentLocs: [Int]) -> (position: Int, length: Int) {
        var shift = 0
        var length = length
        for loc in accentLocs.sorted() {
            if loc < position {
                shift += 1
            } else if loc < position + length {
                length += 1
            }
        }
        return (position + shift, length)
    }

    private func adjustForAccentInsertions(_ annotations: inout [VerbAspectAnnotation], accentLocs: [Int]) {
        guard !accentLocs.isEmpty else { return }
        for i in annotations.indices {
            let (position, length) = shiftForAccentInsertions(
                position: annotations[i].position, length: annotations[i].length, accentLocs: accentLocs
            )
            annotations[i].position = position
            annotations[i].length = length
        }
    }

    private func adjustForAccentInsertions(_ annotations: inout [NounCaseAnnotation], accentLocs: [Int]) {
        guard !accentLocs.isEmpty else { return }
        for i in annotations.indices {
            let (position, length) = shiftForAccentInsertions(
                position: annotations[i].position, length: annotations[i].length, accentLocs: accentLocs
            )
            annotations[i].position = position
            annotations[i].length = length
        }
    }

    private func adjustForAccentInsertions(_ annotations: inout [ShortAdjectiveAnnotation], accentLocs: [Int]) {
        guard !accentLocs.isEmpty else { return }
        for i in annotations.indices {
            let (position, length) = shiftForAccentInsertions(
                position: annotations[i].position, length: annotations[i].length, accentLocs: accentLocs
            )
            annotations[i].position = position
            annotations[i].length = length
        }
    }

    private func adjustAnnotationsForAccentInsertions(of practice: WordPractice, tokens: [Token], word: String) {
        let accentLocs = calculateAccentLocs(for: word, with: tokens)
        guard !accentLocs.isEmpty else { return }
        adjustForAccentInsertions(&practice.verbAspectAnnotations, accentLocs: accentLocs)
        adjustForAccentInsertions(&practice.nounCaseAnnotations, accentLocs: accentLocs)
        adjustForAccentInsertions(&practice.shortAdjectiveAnnotations, accentLocs: accentLocs)
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
                // New round: allow each type to be generated up to quota again.
                entry.completedGenerationTypes = []
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

    func makeAndCachePractices(for words: [String]) {

        let nRepetitions = self.lang.configs.wordPracticeRepetition
        let enabledTypes = self.lang.configs.phraseReviewEnabledPracticeTypes

        var schedule = EbbinghausSchedule.load(for: self.lang)
        // Snapshot of what's already on disk (independent of `wordPracticeCounter`, which only
        // reflects what's currently in this instance's in-memory `practiceList`). Used to gate
        // generation per (word, type) so re-running this on an already-populated word doesn't
        // pile on duplicates -- this replaces an earlier whole-word skip (`if wordPracticeCounter
        // .keys.contains(word) { continue }`) that used to short-circuit ANY word with an existing
        // practice of ANY type, silently preventing missing types (e.g. imageSelection) on an
        // otherwise-populated word from ever being generated.
        let onDiskPractices = Self.loadCachedPractices(for: self.lang)

        // The phrase-review list: every word that has an Ebbinghaus schedule entry (i.e. has
        // been added to reinforcement/review at some point), regardless of whether it's
        // currently due. Choices/context annotation lookups search this pool. Computed once
        // (O(self.words.count)) rather than inside the loop below -- `self.words` doesn't
        // change across this call, and `schedule` only ever gains entries here, never loses
        // them, so a single filter plus incremental appends (below, when a new schedule entry
        // is created for a word in this batch) keeps it correct without refiltering per word.
        var reviewListWords = self.words.filter {
            schedule[Self.normalizedKey(from: $0.text)] != nil
        }

        for word in words {

            let key = Self.normalizedKey(from: word)

            // Skip entirely if another producer instance (this one or a different one, e.g.
            // `backgroundRefresh`'s own producer) is already generating for this word --
            // otherwise both would independently see "0 existing" for the same (word, type)
            // and each generate a full batch, producing duplicate `WordPractice` records with
            // different `id`s for what should be a single practice slot (bug 4a).
            guard Self.tryBeginGeneration(for: key) else {
                print("[makeAndCachePractices] \(key): generation already in progress elsewhere, skipping")
                continue
            }
            // Tracks every async branch (meaning translation, reordering, image generation,
            // token/accent analysis, and the per-choice/context accent analysis nested inside
            // annotation) fired for this word, so the generation gate is released only once
            // all of them have actually finished -- not merely once this synchronous pass
            // through the loop body returns.
            let generationGroup = DispatchGroup()
            generationGroup.notify(queue: .main) {
                Self.endGeneration(for: key)
            }

            mutate {
                if wordPracticeCounter[key] == nil {
                    wordPracticeCounter[key] = 0
                }
            }

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
                // Keep `reviewListWords` in sync: this word just newly joined the review list,
                // so later words in this same batch should be able to have their context
                // annotated against it too.
                if let newlyReviewedWord = self.words.first(where: { Self.normalizedKey(from: $0.text) == key }) {
                    reviewListWords.append(newlyReviewedWord)
                }
            }
            // Snapshot into a `let` before any async branch below captures it. The async
            // branches (token/accent analysis, translation, image generation) run their
            // completion on other queues/threads, and by the time they fire, later iterations
            // of this loop may already be mutating the outer `var reviewListWords` (via the
            // append above) on the calling thread -- concurrent mutation and read of the same
            // `Array` from different threads without synchronization is undefined behavior.
            // Capturing an immutable snapshot here instead means each iteration's closures see
            // a fixed, safely-shared array (Array's CoW buffer is safe to read concurrently from
            // multiple threads as long as nothing mutates it, which this snapshot never does).
            let reviewListWordsSnapshot = reviewListWords
            let periodIndex = schedule[key]!.periodIndex
            let typesToUse = EbbinghausSchedule.effectivePracticeTypes(
                for: periodIndex,
                enabledTypes: enabledTypes
            )
            // Types already generated to quota for this round -- must not be topped back up
            // even if practices of that type were since consumed by practicing. Only clearing
            // this (which happens when `periodIndex` advances) re-allows generation.
            let completedTypes = schedule[key]!.completedGenerationTypes

            // Existing on-disk count per type for this word+period, so we only generate the
            // deficit per type instead of a full batch every time this word is revisited.
            let existingForWord = onDiskPractices.filter {
                Self.normalizedKey(from: $0.word) == key && ($0.periodIndex ?? 0) == periodIndex
            }
            func neededCount(for type: WordPractice.PracticeType) -> Int {
                guard typesToUse.contains(type) else { return 0 }
                guard !completedTypes.contains(type) else { return 0 }
                let existing = existingForWord.filter { $0.practiceType == type }.count
                let needed = max(0, nRepetitions - existing)
                print("[makeAndCachePractices] \(key) / \(type): existing=\(existing), generating=\(needed)")
                return needed
            }

            // Migration for pre-existing data: if a type already had quota met on disk before
            // this per-type "completed" tracking existed, `completedTypes` won't have it yet.
            // Mark it now from the already-known `existingForWord` snapshot so this word doesn't
            // get topped back up the next time one of its practices is consumed.
            for type in typesToUse where !completedTypes.contains(type) {
                let existing = existingForWord.filter { $0.practiceType == type }.count
                guard existing >= nRepetitions else { continue }
                EbbinghausSchedule.update(for: self.lang) { persisted in
                    guard var entry = persisted[key], entry.periodIndex == periodIndex else { return }
                    entry.completedGenerationTypes.insert(type)
                    persisted[key] = entry
                }
            }

            // Call after appending newly generated practices of `type` to `practiceList`. If the
            // (word, period, type) count on the live list has reached quota, persist that as
            // "fully generated this round" so later calls (including backgroundRefresh) don't
            // regenerate a practice of this type that gets consumed by practicing.
            func markTypeCompletedIfQuotaMet(_ type: WordPractice.PracticeType) {
                let currentCount: Int = mutate {
                    self.practiceList.compactMap { $0 as? WordPractice }.filter {
                        Self.normalizedKey(from: $0.word) == key
                            && ($0.periodIndex ?? 0) == periodIndex
                            && $0.practiceType == type
                    }.count
                }
                guard currentCount >= nRepetitions else { return }
                EbbinghausSchedule.update(for: self.lang) { persisted in
                    guard var entry = persisted[key], entry.periodIndex == periodIndex else { return }
                    entry.completedGenerationTypes.insert(type)
                    persisted[key] = entry
                }
            }

            let neededAccentSelection = neededCount(for: .accentSelection)

            // Reuse the tokens analyzed at reinforce-tap time (stored against the untouched
            // `contextSentence`) instead of re-running `analyzeAccents(for: word)`, when a
            // contiguous run of stored tokens matches `word`.
            let storedWordTokens = Self.tokens(forWord: word, in: ReinforcementWords.load(for: self.lang)[key]?.contextTokens ?? [])

            let now = Date()
            let candidateWords = self.words.filter {
                guard $0.text != word else { return false }
                guard let entry = schedule[Self.normalizedKey(from: $0.text)] else { return false }
                return entry.nextReviewDate <= now
            }
            // `reviewListWords` (computed once, outside this loop, above) is the phrase-review
            // pool used for choices/context annotation lookups.

            func stamp(_ p: WordPractice) -> WordPractice {
                p.periodIndex = periodIndex
                return p
            }

            let neededMeaningSelection = neededCount(for: .meaningSelection)
            let neededMeaningFilling = neededCount(for: .meaningFilling)
            let neededContextSelection = neededCount(for: .contextSelection)
            let neededReordering = neededCount(for: .reordering)
            let neededImageSelection = neededCount(for: .imageSelection)
            let neededImageFilling = neededCount(for: .imageFilling)
            let neededPhraseConstruction = neededCount(for: .phraseConstruction)

            func withWordTokens(_ completion: @escaping ([Token], String?, String) -> Void) {
                if let storedWordTokens = storedWordTokens {
                    completion(storedWordTokens, nil, word)
                    return
                }
                analyzeAccents(for: word, completion: completion)
            }

            // Resolve tokens FIRST, then run every generation branch inside this callback, so
            // each practice can be annotated the instant it's created (via `annotate` below)
            // instead of only annotating whatever happened to already be in a local snapshot
            // array by the time this callback fired. Previously, slow async branches (image
            // generation in particular) appended their practices to `practicesForWord` AFTER
            // this callback had already run and set the completion flags -- those late records
            // never got flagged here and stayed unannotated until a separate, later
            // `annotateExistingPractices` pass happened to catch them (analysis.md 新需求 9,
            // bug 4b). If token resolution itself fails (`tokens.isEmpty`), practices are still
            // created below exactly as before -- `annotate` is simply a no-op per practice in
            // that case, same as the prior behavior of skipping annotation entirely.
            generationGroup.enter()
            withWordTokens { tokens, fixedText, text in
                defer { generationGroup.leave() }

                let needsAspect = LangCode.currentLanguage.configs.shouldShowVerbAspectsInPractices
                let needsNounCase = LangCode.currentLanguage.configs.shouldShowNounCasesInPractices
                let accentedWord = tokens.isEmpty ? "" : Self.joinTokensPreservingPunctuation(
                    tokens.accentedPronunciations, separator: Strings.wordSeparator
                )

                // Annotates a single freshly-created practice using the tokens resolved above.
                // Safe to call immediately after creating/appending any practice, sync or async.
                func annotate(_ practice: WordPractice) {
                    guard !tokens.isEmpty else { return }
                    if needsAspect {
                        practice.verbAspectAnnotations = calculateVerbAspectAnnotations(for: practice.query, with: tokens)
                    }
                    if needsNounCase {
                        practice.nounCaseAnnotations = calculateNounCaseAnnotations(for: practice.query, with: tokens)
                        practice.shortAdjectiveAnnotations = calculateShortAdjectiveAnnotations(for: practice.query, with: tokens)
                    }
                    // Choices are drawn from the phrase-review list (`candidateWords`/
                    // `reviewListWords`, or `word` itself -- see `choices(for:textForChoice:)`),
                    // and every such `Word` already carries its own cached `tokens` from
                    // whenever it was added to review. Reuse that cached data directly instead
                    // of firing an `analyzeAccents` network call per choice -- if a choice has
                    // no cached tokens (not on the review list, or not yet analyzed), just leave
                    // it unannotated rather than calling out for it.
                    func cachedTokens(forChoiceOrContextText text: String) -> [Token]? {
                        if Self.normalizedKey(from: text) == key {
                            return tokens
                        }
                        return reviewListWordsSnapshot.first {
                            Self.normalizedKey(from: $0.text) == Self.normalizedKey(from: text)
                        }?.tokens
                    }

                    // Annotate Russian choices (meaningToText direction or contextSelection).
                    if let choices = practice.choices,
                       practice.direction == .meaningToText || practice.practiceType == .contextSelection {
                        practice.choiceVerbAspectAnnotations = Array(repeating: [], count: choices.count)
                        practice.choiceNounCaseAnnotations = Array(repeating: [], count: choices.count)
                        for (i, choice) in choices.enumerated() {
                            guard let choiceTokens = cachedTokens(forChoiceOrContextText: choice), !choiceTokens.isEmpty else { continue }
                            if needsAspect {
                                practice.choiceVerbAspectAnnotations[i] = calculateVerbAspectAnnotations(for: choice, with: choiceTokens)
                            }
                            if needsNounCase {
                                practice.choiceNounCaseAnnotations[i] = calculateNounCaseAnnotations(for: choice, with: choiceTokens)
                            }
                        }
                    }
                    // Context sentence: the practiced word's own occurrence is already blanked
                    // out to `Strings.underscoreToken` (see `makeContextSelectionPractice`), so
                    // there's nothing of the practiced word left to annotate there. For any
                    // OTHER word appearing in the context text, reuse ITS cached `tokens` from
                    // the phrase-review list (`reviewListWords`) to annotate that span -- best
                    // effort, skip whatever isn't on the review list rather than firing a
                    // full-sentence `analyzeAccents` call.
                    if let context = practice.context, practice.practiceType == .contextSelection {
                        let (contextVerbAnns, contextNounAnns) = Self.annotateContextUsingReviewListTokens(
                            context: context,
                            reviewListWords: reviewListWordsSnapshot,
                            needsAspect: needsAspect,
                            needsNounCase: needsNounCase
                        )
                        if needsAspect { practice.contextVerbAspectAnnotations = contextVerbAnns }
                        if needsNounCase { practice.contextNounCaseAnnotations = contextNounAnns }
                    }
                    practice.isGrammarAnnotationCompleted = true
                    self.addAccents(to: practice, with: accentedWord)
                    practice.isAccentAnnotationCompleted = true
                    self.adjustAnnotationsForAccentInsertions(of: practice, tokens: tokens, word: word)
                }

                if neededMeaningSelection > 0 || neededMeaningFilling > 0 {
                    // Reuse the meaning captured at reinforce-tap time (already translated then)
                    // instead of re-translating the same word here.
                    let storedMeaning = ReinforcementWords.load(for: self.lang)[key]?.meaning
                    func withMeaning(_ completion: @escaping (String) -> Void) {
                        if let storedMeaning = storedMeaning, !storedMeaning.isEmpty {
                            completion(storedMeaning)
                            return
                        }
                        self.machineTranslator.translate(query: word) { translations, _ in
                            guard !translations.isEmpty else { return }
                            completion(translations.joined(separator: "; "))
                        }
                    }
                    generationGroup.enter()
                    withMeaning { meaning in
                        defer { generationGroup.leave() }

                        for _ in 0..<neededMeaningSelection {
                            if let p = self.makeMeaningSelectionPractice(
                                word: word, query: word, key: meaning,
                                direction: .textToMeaning, preferredWords: candidateWords
                            ) {
                                annotate(p)
                                self.mutate {
                                    self.practiceList.append(stamp(p))
                                    self.wordPracticeCounter[key]! += 1
                                }
                            }
                            if let p = self.makeMeaningSelectionPractice(
                                word: word, query: meaning, key: word,
                                direction: .meaningToText, preferredWords: candidateWords
                            ) {
                                annotate(p)
                                self.mutate {
                                    self.practiceList.append(stamp(p))
                                    self.wordPracticeCounter[key]! += 1
                                }
                            }
                        }
                        for _ in 0..<neededMeaningFilling {
                            let p = self.makeMeaningFillingPractice(
                                word: word, query: meaning, key: word, direction: .meaningToText
                            )
                            annotate(p)
                            self.mutate {
                                self.practiceList.append(stamp(p))
                                self.wordPracticeCounter[key]! += 1
                            }
                        }
                        if neededMeaningSelection > 0 { markTypeCompletedIfQuotaMet(.meaningSelection) }
                        if neededMeaningFilling > 0 { markTypeCompletedIfQuotaMet(.meaningFilling) }
                        self.cache()
                        self.sendWordPracticeCounterUpdateNotification()
                    }
                }

                if neededContextSelection > 0 {
                    for _ in 0..<neededContextSelection {
                        if let p = self.makeContextSelectionPractice(word: word, query: word, preferredWords: candidateWords) {
                            annotate(p)
                            self.mutate {
                                self.practiceList.append(stamp(p))
                                self.wordPracticeCounter[key]! += 1
                            }
                        }
                    }
                    markTypeCompletedIfQuotaMet(.contextSelection)
                }
                self.cache()
                self.sendWordPracticeCounterUpdateNotification()

                if neededReordering > 0 {
                    for _ in 0..<neededReordering {
                        generationGroup.enter()
                        self.makeReorderingPractice(word: word, query: word) { practice in
                            defer { generationGroup.leave() }
                            if let p = practice {
                                annotate(p)
                                self.mutate {
                                    self.practiceList.append(stamp(p))
                                    self.wordPracticeCounter[key]! += 1
                                }
                                markTypeCompletedIfQuotaMet(.reordering)
                                self.cache()
                                self.sendWordPracticeCounterUpdateNotification()
                            }
                        }
                    }
                }

                if neededImageSelection > 0 || neededImageFilling > 0 {
                    generationGroup.enter()
                    self.imageCreator.generateImage(for: word) { imageUrl in
                        defer { generationGroup.leave() }
                        guard let imageUrl = imageUrl else { return }
                        for _ in 0..<neededImageSelection {
                            if let p = self.makeImageSelectionPractice(word: word, imageUrl: imageUrl, preferredWords: candidateWords) {
                                annotate(p)
                                self.mutate {
                                    self.practiceList.append(stamp(p))
                                    self.wordPracticeCounter[key]! += 1
                                }
                            }
                            markTypeCompletedIfQuotaMet(.imageSelection)
                            self.cache()
                            self.sendWordPracticeCounterUpdateNotification()
                        }
                        for _ in 0..<neededImageFilling {
                            let p = self.makeImageFillingPractice(word: word, imageUrl: imageUrl)
                            annotate(p)
                            self.mutate {
                                self.practiceList.append(stamp(p))
                                self.wordPracticeCounter[key]! += 1
                            }
                            markTypeCompletedIfQuotaMet(.imageFilling)
                            self.cache()
                            self.sendWordPracticeCounterUpdateNotification()
                        }
                    }
                }

                if neededPhraseConstruction > 0 {
                    for _ in 0..<neededPhraseConstruction {
                        if let p = self.makePhraseConstructionPractice(word: word) {
                            annotate(p)
                            self.mutate {
                                self.practiceList.append(stamp(p))
                                self.wordPracticeCounter[key]! += 1
                            }
                        }
                    }
                    markTypeCompletedIfQuotaMet(.phraseConstruction)
                    self.cache()
                    self.sendWordPracticeCounterUpdateNotification()
                }

                // accentSelection practices are built directly from `tokens` (already-accented
                // pronunciations); they don't need `annotate`'s query-rewrite/choice/context
                // logic, but still need the completion flags set so the list view's "all
                // matching records annotated" check (loadEntries) doesn't treat them as pending.
                for _ in 0..<neededAccentSelection {
                    if !tokens.isEmpty, let p = self.makeAccentSelectionPractice(
                        word: fixedText ?? text, query: fixedText ?? text, tokens: tokens
                    ) {
                        p.periodIndex = periodIndex
                        p.isGrammarAnnotationCompleted = true
                        p.isAccentAnnotationCompleted = true
                        self.mutate {
                            self.practiceList.append(p)
                            self.wordPracticeCounter[key]! += 1
                        }
                    }
                }
                if neededAccentSelection > 0 { markTypeCompletedIfQuotaMet(.accentSelection) }
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
        // Same phrase-review-list scoping as `makeAndCachePractices`: choices/context should be
        // annotated using tokens cached on words that are actually on the review list, not the
        // full `self.words` word bank.
        let reviewListWords = self.words.filter {
            schedule[Self.normalizedKey(from: $0.text)] != nil
        }

        let targets = allPractices.filter {
            Self.normalizedKey(from: $0.word) == key
                && ($0.periodIndex ?? 0) == periodIndex
                && (!$0.isAccentAnnotationCompleted || !$0.isGrammarAnnotationCompleted)
        }
        guard !targets.isEmpty else { completion?(); return }

        let word = targets.first!.word

        // Reuse tokens analyzed at reinforce-tap time if available, instead of re-running
        // `analyzeAccents(for: word)`.
        let storedWordTokens = Self.tokens(forWord: word, in: ReinforcementWords.load(for: lang)[key]?.contextTokens ?? [])
        func withWordTokens(_ completion: @escaping ([Token], String?, String) -> Void) {
            if let storedWordTokens = storedWordTokens {
                completion(storedWordTokens, nil, word)
                return
            }
            analyzeAccents(for: word, completion: completion)
        }
        withWordTokens { tokens, _, _ in
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
                    // Reuse cached `Word.tokens` from the phrase-review list (`reviewListWords`)
                    // instead of firing a fresh `analyzeAccents` call per choice/context --
                    // choices are words/phrases on the review list (or the practiced word
                    // itself), so their tokens were already analyzed and cached.
                    func cachedTokens(forChoiceOrContextText text: String) -> [Token]? {
                        if Self.normalizedKey(from: text) == key {
                            return tokens
                        }
                        return reviewListWords.first {
                            Self.normalizedKey(from: $0.text) == Self.normalizedKey(from: text)
                        }?.tokens
                    }

                    if let choices = practice.choices,
                       practice.direction == .meaningToText || practice.practiceType == .contextSelection {
                        practice.choiceVerbAspectAnnotations = Array(repeating: [], count: choices.count)
                        practice.choiceNounCaseAnnotations = Array(repeating: [], count: choices.count)
                        for (i, choice) in choices.enumerated() {
                            guard let choiceTokens = cachedTokens(forChoiceOrContextText: choice), !choiceTokens.isEmpty else { continue }
                            if needsAspect {
                                practice.choiceVerbAspectAnnotations[i] = calculateVerbAspectAnnotations(for: choice, with: choiceTokens)
                            }
                            if needsNounCase {
                                practice.choiceNounCaseAnnotations[i] = calculateNounCaseAnnotations(for: choice, with: choiceTokens)
                            }
                        }
                    }
                    if let context = practice.context, practice.practiceType == .contextSelection {
                        let (contextVerbAnns, contextNounAnns) = Self.annotateContextUsingReviewListTokens(
                            context: context,
                            reviewListWords: reviewListWords,
                            needsAspect: needsAspect,
                            needsNounCase: needsNounCase
                        )
                        if needsAspect { practice.contextVerbAspectAnnotations = contextVerbAnns }
                        if needsNounCase { practice.contextNounCaseAnnotations = contextNounAnns }
                    }
                    practice.isGrammarAnnotationCompleted = true
                }
                if !practice.isAccentAnnotationCompleted {
                    let accentedWord = Self.joinTokensPreservingPunctuation(tokens.accentedPronunciations, separator: Strings.wordSeparator)
                    self.addAccents(to: practice, with: accentedWord)
                    practice.isAccentAnnotationCompleted = true
                    self.adjustAnnotationsForAccentInsertions(of: practice, tokens: tokens, word: word)
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

    /// Extracts the contiguous run of `tokens` (analyzed against some larger context sentence)
    /// whose joined text matches `word`, so it can be reused as-is instead of re-running
    /// `analyzeAccents(for: word)`. Returns nil if no contiguous run matches.
    static func tokens(forWord word: String, in tokens: [Token]) -> [Token]? {
        guard !tokens.isEmpty else { return nil }
        let targetKey = normalizedKey(from: word)
        for start in 0..<tokens.count {
            var joined = ""
            for end in start..<tokens.count {
                joined += tokens[end].text
                if normalizedKey(from: joined) == targetKey {
                    return Array(tokens[start...end])
                }
                if joined.count > word.count { break }
            }
        }
        return nil
    }

    /// Annotates `context` using individual tokens from `reviewListWords`' cached `Word.tokens`
    /// (not the whole phrase text) -- so a multi-word review phrase still contributes an
    /// annotation for whichever single token of it actually shows up in `context`, and one
    /// token's text can't accidentally swallow another token's annotation the way passing the
    /// full phrase's token array into `calculateVerbAspectAnnotations`/`calculateNounCaseAnnotations`
    /// would (those functions walk their token array in lock-step with occurrences in the text
    /// and bail out at the first token they can't locate).
    static func annotateContextUsingReviewListTokens(
        context: String,
        reviewListWords: [Word],
        needsAspect: Bool,
        needsNounCase: Bool
    ) -> (verb: [VerbAspectAnnotation], noun: [NounCaseAnnotation]) {
        var contextVerbAnns: [VerbAspectAnnotation] = []
        var contextNounAnns: [NounCaseAnnotation] = []
        let contextLower = context.lowercased()
        var seenTokenTexts = Set<String>()
        for candidate in reviewListWords {
            guard let candidateTokens = candidate.tokens else { continue }
            for token in candidateTokens {
                let tokenTextLower = token.text.lowercased()
                guard !tokenTextLower.isEmpty else { continue }
                guard seenTokenTexts.insert(tokenTextLower).inserted else { continue }
                guard contextLower.contains(tokenTextLower) else { continue }
                if needsAspect {
                    contextVerbAnns.append(contentsOf: calculateVerbAspectAnnotations(for: context, with: [token]))
                }
                if needsNounCase {
                    contextNounAnns.append(contentsOf: calculateNounCaseAnnotations(for: context, with: [token]))
                }
            }
        }
        return (contextVerbAnns, contextNounAnns)
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
