//
//  TranslationPracticeExtensions.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

class SpeakingPracticeProducer: TextMeaningPracticeProducer {
    
    // MARK: - Init
    
    override init(words: [Word], articles: [Article]) {
        super.init(words: words, articles: articles)
        
        // Override the batch size.
        self.batchSize = LangCode.currentLanguage.configs.speakingPracticeDuration
        
        let cachedSpeakingPractices = SpeakingPracticeProducer.loadCachedPractices(for: LangCode.currentLanguage)
        if !cachedSpeakingPractices.isEmpty {
            // In case that some words have been deleted.
            for cachedSpeakingPractice in cachedSpeakingPractices {
                let (updatedExistingPhraseRanges, updatedExistingPhraseMeanings) = findExistingPhraseRangesAndMeanings(
                    for: cachedSpeakingPractice.text,
                    from: self.words
                )
                cachedSpeakingPractice.existingPhraseRanges = updatedExistingPhraseRanges
                cachedSpeakingPractice.existingPhraseMeanings = updatedExistingPhraseMeanings
            }
            self.practiceList.append(contentsOf: cachedSpeakingPractices)
        } else {
            self.practiceList.append(contentsOf: make())
        }
    }
    
    override func make() -> [BasePractice] {
        
        var practiceList: [SpeakingPractice] = []
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
            } else if n == 1 {
                makePractice(
                    inGranularity: TextGranularity.sentence,
                    callBack: { practice in
                        practiceList.append(practice)
                        self.calculateAccentLocsForText(in: practice)
                    }
                )
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
    
    override func reinforce() {
        guard let currentPractice = currentPractice as? SpeakingPractice else {
            return
        }
        currentPractice.totalRepetitions += LangCode.currentLanguage.configs.practiceRepetition
        self.practiceList[self.currentPracticeIndex] = currentPractice
    }
    
    override func cache() {        
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
            totalRepetitions: LangCode.currentLanguage.configs.practiceRepetition,
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
}

extension SpeakingPracticeProducer {
    
    // MARK: - IO
    
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
