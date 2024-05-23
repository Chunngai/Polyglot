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
        
        let cachedSpeakingPractices = SpeakingPracticeProducer.loadCachedPractices(for: LangCode.currentLanguage)
        if !cachedSpeakingPractices.isEmpty {
            self.practiceList.append(contentsOf: cachedSpeakingPractices)
        } else {
            self.practiceList.append(contentsOf: make())
        }
//        // Create and save new cached practices for the use of next time.
//        DispatchQueue.global(qos: .userInitiated).async {
//            guard var speakingPracticesToCache = self.make() as? [SpeakingPractice] else {
//                return
//            }
//            SpeakingPracticeProducer.save(
//                &speakingPracticesToCache,
//                for: LangCode.currentLanguage
//            )
//        }
    }
    
    override func next() {
        super.next()
        
        let startIndex = currentPracticeIndex + 1
        if startIndex >= practiceList.count {
            return
        }
        
        guard var practicesToCache = [BasePractice](practiceList.suffix(from: currentPracticeIndex + 1)) as? [SpeakingPractice] else {
            return
        }
        SpeakingPracticeProducer.save(
            &practicesToCache,
            for: LangCode.currentLanguage
        )
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
                    }
                )
            } else if n == 1 {
                makePractice(
                    inGranularity: TextGranularity.sentence,
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
    
    func reinforce() {
        guard let currentPractice = currentPractice as? SpeakingPractice else {
            return
        }
        practiceList.append(SpeakingPractice(from: currentPractice))
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
