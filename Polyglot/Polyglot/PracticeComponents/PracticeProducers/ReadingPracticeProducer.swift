//
//  ReadingPracticeProducer.swift
//  Polyglot
//
//  Created by Ho on 8/25/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation

class ReadingPracticeProducer: TextMeaningPracticeProducer {

    var selectedArticle: Article?
    private var currentSelectedParaIndex: Int = 0
    private var pendingStartParaIndex: Int = 0
    var isArticleComplete: Bool = false
    private var cancelledDuringLoading = false

    // MARK: - Init

    init(words: [Word], articles: [Article]) {
        super.init(
            words: words, 
            articles: articles, 
            isDuolingoOnly: LangCode.currentLanguage.configs.isDuolingoOnlyForReading
        )
        
        // Override the batch size.
        self.batchSize = LangCode.currentLanguage.configs.readingPracticeDuration
        
        let cachedReadingPractices = ReadingPracticeProducer.loadCachedPractices(for: LangCode.currentLanguage)
        load(cachedReadingPractices)
    }
    
    override func next() {
        if self.practiceList.isEmpty {
            self.practiceList.append(contentsOf: self.make())
        }
        if self.practiceList.isEmpty { return }

        self.currentPracticeIndex = 0

        if !isArticleComplete && self.practiceList.count <= batchSize {
            DispatchQueue.global(qos: .userInitiated).async {
                let newPractices = self.make()
                self.practiceList.append(contentsOf: newPractices)
                self.updateMeaningsAndExistingPhrasesAndAccentLocs()
            }
        }
    }
    
    override func make() -> [BasePractice] {

        let randomArticle: Article
        if let selected = selectedArticle {
            randomArticle = selected
        } else {
            guard let randomGroupedArticles = self.groupedArticles.randomElement() else { return [] }
            guard let picked = randomGroupedArticles.articles.randomElement() else { return [] }
            randomArticle = picked
        }

        // Determine starting paragraph: resume from stored position if using selectedArticle.
        let startingParaIndex: Int
        if selectedArticle != nil {
            let metaData = ReadingPracticeProducer.loadParagraphMetaData(for: LangCode.currentLanguage)
            let stored = Int(metaData[ReadingPracticeProducer.paragraphMetaKey(for: randomArticle.id)] ?? "0") ?? 0
            if stored >= randomArticle.paras.count {
                isArticleComplete = true
                return []
            }
            startingParaIndex = stored
            pendingStartParaIndex = stored
        } else {
            startingParaIndex = (0..<randomArticle.paras.count).randomElement() ?? 0
        }
        var paraIndex = startingParaIndex
        
        var practiceList: [ReadingPractice] = []
        while true {
            
            if paraIndex >= randomArticle.paras.count {
                break
            }
            
            let para = randomArticle.paras[paraIndex]
            let sentences = para.text.tokenized(with: LangCode.currentLanguage.sentenceTokenizer)
            for (sentenceId, sentence) in sentences.enumerated() {
                
                if !LangCode.isText(
                    sentence,
                    in: LangCode.currentLanguage
                ) {
                    continue
                }
                
                let (
                    existingPhraseRanges,
                    existingPhraseMeanings
                ) = findExistingPhraseRangesAndMeanings(
                    for: sentence,
                    from: self.words
                )
                let practice = ReadingPractice(
                    text: sentence,
                    meaning: "",
                    textLang: LangCode.currentLanguage,
                    meaningLang: LangCode.currentLanguage.configs.languageForTranslation,
                    textSource: .article(
                        articleId: randomArticle.id,
                        paragraphId: para.id,
                        sentenceId: sentenceId
                    ),
                    isTextMachineTranslated: false,
                    machineTranslatorType: .none,
                    existingPhraseRanges: existingPhraseRanges,
                    existingPhraseMeanings: existingPhraseMeanings,
                    textAccentLocs: []
                )
                practiceList.append(practice)

                // Skip for the first practice in article mode: accent is handled
                // inline below together with translation (concurrent, with 5s timeout).
                let isFirstArticlePractice = selectedArticle != nil && practiceList.count == 1
                if !isFirstArticlePractice {
                    calculateAccentLocsForText(in: practice)
                }
            }
            if practiceList.count >= batchSize {
                break
            }
            
            paraIndex += 1
        }
        if practiceList.count < batchSize {
            if selectedArticle != nil {
                isArticleComplete = true
            } else {
                practiceList.append(contentsOf: self.make() as! [ReadingPractice])
            }
        }

        // Persist the paragraph we reached so the next session resumes here.
        if selectedArticle != nil {
            let savedPara = isArticleComplete ? randomArticle.paras.count : paraIndex + 1
            currentSelectedParaIndex = savedPara
            // NOTE: cache() is called AFTER loading completes (below), not here.
            // This ensures a force-quit during loading leaves the stored position
            // unchanged so the next launch resumes from the correct paragraph.

            // Concurrently fetch translation and accent marks for the first practice,
            // then proceed. Translation has no timeout; accent marking times out after 10s.
            if let first = practiceList.first {
                let translationSemaphore = DispatchSemaphore(value: 0)
                let accentSemaphore = DispatchSemaphore(value: 0)
                let needsAccent = LangCode.currentLanguage.shouldAddAccentMarksToTextInPractices

                if first.meaning.isEmpty {
                    maybeTranslate(text: first.text) { translation, isMachineTranslated, translatorType, _ in
                        first.meaning = translation
                        first.isTextMachineTranslated = isMachineTranslated
                        first.machineTranslatorType = translatorType
                        translationSemaphore.signal()
                    }
                } else {
                    translationSemaphore.signal()
                }

                let needsAspect = LangCode.currentLanguage.configs.shouldShowVerbAspectsInPractices
                if needsAccent || needsAspect {
                    analyzeAccents(for: first.text) { tokens, fixedText, _ in
                        if !tokens.isEmpty {
                            if let fixedText = fixedText {
                                first.text = fixedText
                            }
                            if needsAccent {
                                first.textAccentLocs = calculateAccentLocs(for: first.text, with: tokens)
                            }
                            if needsAspect {
                                first.verbAspectAnnotations = calculateVerbAspectAnnotations(for: first.text, with: tokens)
                            }
                        }
                        accentSemaphore.signal()
                    }
                }

                translationSemaphore.wait()
                if needsAccent || needsAspect {
                    accentSemaphore.wait(timeout: .now() + 10)
                }
            }

            // Write progress only after the first practice is ready, and only if the
            // user has not already cancelled (cacheCurrentProgress may have saved the
            // correct roll-back position while make() was still blocked on the semaphore).
            guard !cancelledDuringLoading else { return practiceList }
            cache(paragraphIndex: savedPara, articleId: randomArticle.id)

            DispatchQueue.global(qos: .userInitiated).async {
                self.updateMeaningsAndExistingPhrasesAndAccentLocs()
            }
        }

        return practiceList
    }
    
    override func cache() {
        guard selectedArticle == nil else { return }
        guard var practicesToCache = self.practiceList as? [ReadingPractice] else {
            return
        }
        ReadingPracticeProducer.save(
            &practicesToCache,
            for: LangCode.currentLanguage
        )
    }
}

extension ReadingPracticeProducer {
    
    override func updatePracticeRepetitions() {
        if let currentPractice = self.practiceList[self.currentPracticeIndex] as? TextMeaningPractice {
            currentPractice.currentRepetition += 1
            if currentPractice.currentRepetition < currentPractice.totalRepetitions {
                // Move the current practice to the end of the list.
                self.practiceList.remove(at: self.currentPracticeIndex)
                self.practiceList.append(currentPractice)
            } else {
                self.practiceList.remove(at: self.currentPracticeIndex)
            }
        }
    }
    
}

extension ReadingPracticeProducer {

    // MARK: - IO

    static func paragraphMetaKey(for articleId: String) -> String {
        return "readingParagraph_\(articleId)"
    }

    static func paragraphMetaFileName(for lang: LangCode) -> String {
        return "readingParagraphProgress.\(lang.rawValue).json"
    }

    static func loadParagraphMetaData(for lang: LangCode) -> [String: String] {
        return (try? readDataFromJson(
            fileName: paragraphMetaFileName(for: lang),
            type: [String: String].self
        ) as? [String: String]) ?? [:]
    }

    static func saveParagraphMetaData(_ metaData: inout [String: String], for lang: LangCode) {
        try? writeDataToJson(
            fileName: paragraphMetaFileName(for: lang),
            data: metaData
        )
    }

    func cache(paragraphIndex: Int, articleId: String) {
        var metaData = ReadingPracticeProducer.loadParagraphMetaData(for: LangCode.currentLanguage)
        metaData[ReadingPracticeProducer.paragraphMetaKey(for: articleId)] = String(paragraphIndex)
        ReadingPracticeProducer.saveParagraphMetaData(&metaData, for: LangCode.currentLanguage)
    }

    func cacheCurrentProgress() {
        guard let article = selectedArticle else { return }
        let paraIndex: Int
        if let practice = practiceList.first as? ReadingPractice,
           case let .article(_, paragraphId, _) = practice.textSource,
           let paragraphId = paragraphId,
           let idx = article.paras.firstIndex(where: { $0.id == paragraphId }) {
            paraIndex = idx
            cancelledDuringLoading = false  // Stable state: reset so future make() calls write normally.
        } else if practiceList.isEmpty {
            cancelledDuringLoading = true  // Prevent make() from overwriting this position.
            paraIndex = pendingStartParaIndex
        } else {
            paraIndex = currentSelectedParaIndex
        }
        cache(paragraphIndex: paraIndex, articleId: article.id)
    }

    static func fileName(for lang: String) -> String {
        return "cachedReadingPractices.\(lang).json"
    }

    static func loadCachedPractices(for lang: LangCode) -> [ReadingPractice] {
        do {
            let practices = try readDataFromJson(
                fileName: ReadingPracticeProducer.fileName(for: lang.rawValue),
                type: [ReadingPractice].self
            ) as? [ReadingPractice] ?? []
            return practices
        } catch {
            return []
        }
    }

    static func save(_ practicesToCache: inout [ReadingPractice], for lang: LangCode) {
        do {
            try writeDataToJson(
                fileName: ReadingPracticeProducer.fileName(for: lang.rawValue),
                data: practicesToCache
            )
        } catch {
            print(error.localizedDescription)
        }
    }

}
