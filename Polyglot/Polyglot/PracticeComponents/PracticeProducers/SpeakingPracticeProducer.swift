//
//  TranslationPracticeExtensions.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

class SpeakingPracticeProducer: TextMeaningPracticeProducer {
    
    var selectedArticle: Article?
    var currentSelectedParaIndex: Int = 0
    private var pendingStartParaIndex: Int = 0
    private var isBackgroundMakeInProgress = false
    var isArticleComplete: Bool = false
    private var cancelledDuringLoading = false

    // MARK: - Init

    init(words: [Word], articles: [Article]) {
        super.init(
            words: words, 
            articles: articles, 
            isDuolingoOnly: LangCode.currentLanguage.configs.isDuolingoOnlyForSpeaking
        )
        
        // Override the batch size.
        self.batchSize = LangCode.currentLanguage.configs.speakingPracticeDuration
        
        let cachedSpeakingPractices = SpeakingPracticeProducer.loadCachedPractices(for: LangCode.currentLanguage)
        load(cachedSpeakingPractices)
        
        self.currentPracticeIndex = randomPracticeIndex
    }
    
    override func next() {
        if selectedArticle != nil {
            if self.practiceList.isEmpty {
                self.practiceList.append(contentsOf: self.make())
            }
            if self.practiceList.isEmpty { return }
            self.currentPracticeIndex = 0
            if !isArticleComplete && self.practiceList.count <= batchSize && !isBackgroundMakeInProgress {
                isBackgroundMakeInProgress = true
                DispatchQueue.global(qos: .userInitiated).async {
                    let newPractices = self.make()
                    self.practiceList.append(contentsOf: newPractices)
                    self.updateMeaningsAndExistingPhrasesAndAccentLocs()
                    // isBackgroundMakeInProgress is reset by make() itself
                }
            }
        } else {
            super.next()
        }
    }

    override func make() -> [BasePractice] {

        var practiceList: [SpeakingPractice] = []

        if let article = selectedArticle {
            // Read starting index once at the beginning of the batch.
            let metaData = SpeakingPracticeProducer.loadParagraphMetaData(for: LangCode.currentLanguage)
            let storedIndex = Int(metaData[SpeakingPracticeProducer.paragraphMetaKey(for: article.id)] ?? "0") ?? 0
            if storedIndex >= article.paras.count {
                isArticleComplete = true
                return []
            }

            // How many practices can we actually make (capped by remaining paragraphs).
            let remaining = article.paras.count - storedIndex
            let count = min(batchSize, remaining)

            // Track progress range; disk write is deferred until after loading completes
            // so a force-quit during loading leaves the stored position unchanged.
            pendingStartParaIndex = storedIndex
            currentSelectedParaIndex = storedIndex + count

            // Concurrently start translation and accent analysis for the first practice.
            let needsAccent = LangCode.currentLanguage.shouldAddAccentMarksToTextInPractices
            let needsAspect = LangCode.currentLanguage.configs.shouldShowVerbAspectsInPractices
            let accentSemaphore = DispatchSemaphore(value: 0)

            // Extract the sentence upfront so accent analysis can run in parallel with translation.
            let firstPara = article.paras[storedIndex]
            let firstSentence = firstPara.text.tokenized(with: LangCode.currentLanguage.sentenceTokenizer).first
                ?? firstPara.text
            var firstAccentTokens: [Token] = []
            var firstAccentFixedText: String? = nil
            if needsAccent || needsAspect {
                analyzeAccents(for: firstSentence) { tokens, fixedText, _ in
                    firstAccentTokens = tokens
                    firstAccentFixedText = fixedText
                    accentSemaphore.signal()
                }
            }

            var firstPractice: SpeakingPractice? = nil
            makePractice(fromArticle: article, atParaIndex: storedIndex) { practice in
                firstPractice = practice
            }
            while firstPractice == nil { Thread.sleep(forTimeInterval: 0.05) }

            // Wait for accent with 5s timeout, then apply directly (avoids the
            // self.practiceList search in calculateAccentLocsForText which would fail
            // here since firstPractice has not been appended to self.practiceList yet).
            if (needsAccent || needsAspect), let first = firstPractice {
                accentSemaphore.wait(timeout: .now() + 10)
                if !firstAccentTokens.isEmpty {
                    if let fixedText = firstAccentFixedText {
                        first.text = fixedText
                    }
                    if needsAccent {
                        first.textAccentLocs = calculateAccentLocs(for: first.text, with: firstAccentTokens)
                    }
                    if needsAspect {
                        first.verbAspectAnnotations = calculateVerbAspectAnnotations(for: first.text, with: firstAccentTokens)
                    }
                }
            }

            // Write progress only after the first practice is ready, and only if the
            // user has not already cancelled (cacheCurrentProgress may have saved the
            // correct roll-back position while make() was still blocked on the semaphore).
            if !cancelledDuringLoading {
                var updatedMeta = metaData
                updatedMeta[SpeakingPracticeProducer.paragraphMetaKey(for: article.id)] = String(storedIndex + count)
                SpeakingPracticeProducer.saveParagraphMetaData(&updatedMeta, for: LangCode.currentLanguage)
            }

            // Fire remaining translations in background and append to practiceList.
            // Set the flag before starting the bg task so that next() (which may be
            // called even when make() was triggered from the initial-load path via
            // currentPractice) cannot fire a second make() while this one is still
            // appending practices — which would interleave batches out of order.
            if count > 1 {
                isBackgroundMakeInProgress = true
                DispatchQueue.global(qos: .userInitiated).async {
                    var slots: [SpeakingPractice?] = Array(repeating: nil, count: count - 1)
                    for i in 1..<count {
                        let slotIndex = i - 1
                        self.makePractice(fromArticle: article, atParaIndex: storedIndex + i) { practice in
                            slots[slotIndex] = practice
                            self.calculateAccentLocsForText(in: practice)
                        }
                    }
                    while slots.contains(where: { $0 == nil }) {
                        Thread.sleep(forTimeInterval: 0.1)
                    }
                    self.practiceList.append(contentsOf: slots.compactMap { $0 })
                    self.isBackgroundMakeInProgress = false
                }
            } else {
                isBackgroundMakeInProgress = false
            }

            return [firstPractice!]
        } else {
            for _ in 0..<batchSize {
                let n = Int.random(in: 0...1)
                if n == 0 {
                    makePractice(
                        for: self.words.randomElement()!,
                        inGranularity: TextGranularity.sentence,
                        callBack: { practice in
                            practiceList.append(practice)
                            self.calculateAccentLocsForText(in: practice)
                        }
                    )
                } else {
                    makePractice(
                        inGranularity: TextGranularity.sentence,
                        callBack: { practice in
                            practiceList.append(practice)
                            self.calculateAccentLocsForText(in: practice)
                        }
                    )
                }
            }
        }
        
        while true {
            if practiceList.count >= batchSize {
                break
            }
            Thread.sleep(forTimeInterval: 0.1)  // For avoiding high CPU usage.
        }
        
        return practiceList
    }
    
    override func cache() {
        guard selectedArticle == nil else { return }
        guard var practicesToCache = self.practiceList as? [SpeakingPractice] else {
            return
        }
        SpeakingPracticeProducer.save(
            &practicesToCache,
            for: LangCode.currentLanguage
        )
    }
}

extension SpeakingPracticeProducer {
    
    private func makePractice(
        text: String,
        meaning: String,
        textSource: TextSource,
        isTextMachineTranslated: Bool,
        machineTranslatorType: MachineTranslatorType
    ) -> SpeakingPractice? {
        
        let (existingPhraseRanges, existingPhraseMeanings) = findExistingPhraseRangesAndMeanings(
            for: text,
            from: self.words
        )
        
        var meaningLang = LangCode.currentLanguage.configs.languageForTranslation
        if !isTextMachineTranslated {
            let detectedMeaningLang = LangCode(detectedFrom: meaning)
            if detectedMeaningLang != .undetermined {
                meaningLang = detectedMeaningLang
            }
        }
        
        return SpeakingPractice(
            text: text,
            meaning: meaning,
            textLang: LangCode.currentLanguage,
            meaningLang: meaningLang,
            textSource: textSource,
            isTextMachineTranslated: isTextMachineTranslated,
            machineTranslatorType: machineTranslatorType,
            existingPhraseRanges: existingPhraseRanges,
            existingPhraseMeanings: existingPhraseMeanings,
            totalRepetitions: selectedArticle != nil ? 1 : LangCode.currentLanguage.configs.speakingPracticeRepetition,
            currentRepetition: 0,
            textAccentLocs: []
        )
    }
    
    private func makePractice(
        for randomWord: Word? = nil,
        inGranularity granularity: TextGranularity,
        callBack: @escaping (SpeakingPractice) -> Void
    ) {
     
        generateTextMeaning(
            randomWord: randomWord,
            granularity: granularity,
            machineTranslator: self.machineTranslator,
            contentCreator: self.contentCreator
        ) { text, meaning, textSource, isTextMachineTranslated, machineTranslatorType in
            
            if !LangCode.isText(
                text,
                in: LangCode.currentLanguage
            ) {
                return
            }
            
            guard let practice = self.makePractice(
                text: text,
                meaning: meaning,
                textSource: textSource,
                isTextMachineTranslated: isTextMachineTranslated,
                machineTranslatorType: machineTranslatorType
            ) else {
                return
            }
            callBack(practice)
        }

    }

    private func makePractice(
        fromArticle article: Article,
        atParaIndex paraIndex: Int,
        callBack: @escaping (SpeakingPractice) -> Void
    ) {
        let para = article.paras[paraIndex]
        let sentences = para.text.tokenized(with: LangCode.currentLanguage.sentenceTokenizer)
        let sentence = sentences.first ?? para.text
        let sentenceIndex = sentences.isEmpty ? nil : 0

        let textSource = TextSource.article(
            articleId: article.id,
            paragraphId: para.id,
            sentenceId: sentenceIndex
        )

        maybeTranslate(text: sentence, meaning: para.meaning) { meaning, isTranslated, translatorType, _ in
            guard LangCode.isText(sentence, in: LangCode.currentLanguage) else { return }
            guard let practice = self.makePractice(
                text: sentence,
                meaning: meaning,
                textSource: textSource,
                isTextMachineTranslated: isTranslated,
                machineTranslatorType: translatorType
            ) else { return }
            callBack(practice)
        }
    }
}

extension SpeakingPracticeProducer {

    // MARK: - IO

    static func paragraphMetaKey(for articleId: String) -> String {
        return "speakingParagraph_\(articleId)"
    }

    static func paragraphMetaFileName(for lang: LangCode) -> String {
        return "speakingParagraphProgress.\(lang.rawValue).json"
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

    func cacheCurrentProgress() {
        guard let article = selectedArticle else { return }
        // Derive actual current position from the first remaining practice.
        let paraIndex: Int
        if let practice = practiceList.first as? SpeakingPractice,
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
        var metaData = SpeakingPracticeProducer.loadParagraphMetaData(for: LangCode.currentLanguage)
        metaData[SpeakingPracticeProducer.paragraphMetaKey(for: article.id)] = String(paraIndex)
        SpeakingPracticeProducer.saveParagraphMetaData(&metaData, for: LangCode.currentLanguage)
    }

    static func fileName(for lang: String) -> String {
        return "cachedSpeakingPractices.\(lang).json"
    }

    static func loadCachedPractices(for lang: LangCode) -> [SpeakingPractice] {
        do {
            let practices = try readDataFromJson(
                fileName: SpeakingPracticeProducer.fileName(for: lang.rawValue),
                type: [SpeakingPractice].self
            ) as? [SpeakingPractice] ?? []
            return practices
        } catch {
            return []
        }
    }

    static func save(_ practicesToCache: inout [SpeakingPractice], for lang: LangCode) {
        do {
            try writeDataToJson(
                fileName: SpeakingPracticeProducer.fileName(for: lang.rawValue),
                data: practicesToCache
            )
        } catch {
            print(error.localizedDescription)
        }
    }

}
