//
//  TranslationPracticeExtensions.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

class SpeakingPracticeProducer: PracticeProducerDelegate {
    
    var translator: GoogleTranslator = GoogleTranslator(
        srcLang: LangCode.currentLanguage,
        trgLang: LangCode.pairedLanguage
    )
    var contentCreator: ContentCreator = ContentCreator(lang: LangCode.currentLanguage)
    
    // MARK: - PracticeProducer Delegate
    
    typealias U = SpeakingPractice
    
    var words: [Word]
    var articles: [Article]
    
    var practiceList: [SpeakingPractice] = []
    var currentPracticeIndex: Int = 0
        
    // MARK: - Init
    
    init(words: [Word], articles: [Article]) {
        self.words = words
        self.articles = articles
        
        let cachedSpeakingPractices = SpeakingPracticeProducer.loadCachedPractices(for: LangCode.currentLanguage)
        if !cachedSpeakingPractices.isEmpty {
            self.practiceList.append(contentsOf: cachedSpeakingPractices)
        } else {
            self.practiceList.append(contentsOf: make())
        }
        // Create and save new cached practices for the use of next time.
        DispatchQueue.global(qos: .userInitiated).async {
            var speakingPracticesToCache = self.make()
            SpeakingPracticeProducer.save(
                &speakingPracticesToCache,
                for: LangCode.currentLanguage
            )
        }
    }
    
    func make() -> [SpeakingPractice] {
        
        var practiceList: [SpeakingPractice] = []
        for _ in 0..<batchSize {
            
            let p = Double.random(in: 0...1)
            if p >= 0 && p < 0.45 {  // 45%.
                makePractice(
                    for: self.words.randomElement()!,
                    inGranularity: TextGranularity.sentence,
                    callBack: { practice in
                        practiceList.append(practice)
                    }
                )
            } else if p >= 0.45 && p < 0.9 {  // 45%
                makePractice(
                    inGranularity: TextGranularity.sentence,
                    callBack: { practice in
                        practiceList.append(practice)
                    }
                )
            } else if p >= 0.9 && p <= 1.0 {  // 10%
                makePractice(
                    inGranularity: TextGranularity.paragraph,
                    callBack: { practice in
                        practiceList.append(practice)
                    }
                )
            }
        }
        
        let startTime = Date()
        while true {
            if practiceList.count >= batchSize {
                break
            }
            
            if Date().timeIntervalSince(startTime) >= SpeakingPracticeProducer.practiceMakingTimeThredshold {
                break
            }
            Thread.sleep(forTimeInterval: 0.1)  // For avoiding high CPU usage.
        }
        
        practiceList.shuffle()
        return practiceList
    }
}

extension SpeakingPracticeProducer {
    
    private func makePractice(
        text: String,
        meaning: String,
        textSource: TextSource,
        isTextMachineTranslated: Bool
    ) -> SpeakingPractice? {
        
        let (existingPhraseRanges, existingPhraseMeanings) = findExistingPhraseRangesAndMeanings(for: text)
        
        var meaningLang = LangCode.pairedLanguage
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
            existingPhraseRanges: existingPhraseRanges,
            existingPhraseMeanings: existingPhraseMeanings
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
            translator: self.translator,
            contentCreator: self.contentCreator
        ) { text, meaning, textSource, isTextMachineTranslated in
            guard let practice = self.makePractice(
                text: text,
                meaning: meaning,
                textSource: textSource,
                isTextMachineTranslated: isTextMachineTranslated
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
