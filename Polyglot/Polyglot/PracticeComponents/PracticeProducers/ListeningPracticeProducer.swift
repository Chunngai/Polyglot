//
//  ListeningPracticeProducer.swift
//  Polyglot
//
//  Created by Ho on 2/6/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation

class ListeningPracticeProducer: TextMeaningPracticeProducer {
        
    // MARK: - Init
    
    override init(words: [Word], articles: [Article]) {
        super.init(words: words, articles: articles)
        
        // Override the batch size.
        self.batchSize = LangCode.currentLanguage.configs.listeningPracticeDuration * 2
        
        let cachedListeningPractices = ListeningPracticeProducer.loadCachedPractices(for: LangCode.currentLanguage)
        if !cachedListeningPractices.isEmpty {
            self.practiceList.append(contentsOf: cachedListeningPractices)
        } else {
            self.practiceList.append(contentsOf: make())
        }
    }
    
    override func make() -> [BasePractice] {
        
        var practiceList: [ListeningPractice] = []
        for _ in 0..<batchSize {
            
            let n = Int.random(in: 0...1)
            if n == 0 {
                makePractice(
                    ofType: .listenAndRepeat,
                    for: self.words.randomElement()!,
                    inGranularity: TextGranularity.subsentence,
                    callBack: { listenAndRepeatPractice in
                        practiceList.append(listenAndRepeatPractice)
                    }
                )
            } else if n == 1 {
                makePractice(
                    ofType: .listenAndRepeat,
                    inGranularity: TextGranularity.subsentence,
                    callBack: { listenAndRepeatPractice in
                        practiceList.append(listenAndRepeatPractice)
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
    
    func submit(_ matchedClozeRanges: Any) -> Float? {
        guard let currentPractice = currentPractice as? ListeningPractice else {
            return nil
        }
        
        if currentPractice.practiceType == .listenAndRepeat {
            guard let matchedClozeRanges = matchedClozeRanges as? [NSRange] else {
                return nil
            }
            let correctness = Float(matchedClozeRanges.count) / Float(currentPractice.clozeRanges.count)
            return correctness
        }
        return nil
    }
    
    override func reinforce() {
        guard let currentPractice = currentPractice as? ListeningPractice else {
            return
        }
        currentPractice.totalRepetitions += LangCode.currentLanguage.configs.practiceRepetition
        self.practiceList[self.currentPracticeIndex] = currentPractice
    }
    
    override func cache() {
        guard var practicesToCache = practiceList as? [ListeningPractice] else {
            return
        }
        ListeningPracticeProducer.save(
            &practicesToCache,
            for: LangCode.currentLanguage
        )
    }
    
}

extension ListeningPracticeProducer {
    
    private func makePrompt(for practiceType: ListeningPractice.PracticeType) -> String {
        switch practiceType {
        case .listenAndRepeat:
            return Strings.listeningAndRepeatPracticePrompt
        case .listenAndComplete:
            return Strings.listenAndCompletePracticePrompt
        }
        
    }
    
    private func makePractice(
        practiceType: ListeningPractice.PracticeType,
        granularity: TextGranularity,
        text: String,
        meaning: String,
        textSource: TextSource,
        isTextMachineTranslated: Bool,
        machineTranslatorType: MachineTranslatorType
    ) -> [ListeningPractice] {
                    
        var clozeRanges: [NSRange] = text.tokenRanges.compactMap { tokenRange in
            let token = (text as NSString).substring(with: tokenRange)
            if !LangCode.currentLanguage.shouldFilter(token) {
                return tokenRange
            } else {
                return nil
            }
        }
        
        var subtexts: [String] = []
        if granularity == .subsentence {
            var subsentences = text.split(with: Strings.subsentenceSeparator)
            if subsentences.count == 1 {
                subtexts = [text]
            } else {
                subtexts = [""]
                var currentSubsentenceIndex: Int = 0
                var tokenCountOfLastSubsentence: Int = 0
                while currentSubsentenceIndex < subsentences.count {
                    
                    let currentSubsentence = subsentences[currentSubsentenceIndex].strip()
                    let tokenCountOfCurrentSubsentence = currentSubsentence.tokenized(with: LangCode.currentLanguage.wordTokenizer).count
                    if tokenCountOfCurrentSubsentence <= ListeningPracticeProducer.minSubsentenceWordCountThreshold
                        || tokenCountOfLastSubsentence <= ListeningPracticeProducer.minSubsentenceWordCountThreshold {
                        subtexts[subtexts.count - 1] += "\(Strings.subsentenceSeparator)\(Strings.wordSeparator)\(currentSubsentence)"
                    } else {
                        subtexts.append(currentSubsentence)
                    }
                    currentSubsentenceIndex += 1
                    tokenCountOfLastSubsentence = tokenCountOfCurrentSubsentence
                    
                }
            }
        } else {
            subtexts = [text]
        }
        
        var practices: [ListeningPractice] = []
        for subtext in subtexts {
            let subtextRange = (text as NSString).range(of: subtext)
            var subtextClozeRanges = clozeRanges.compactMap { clozeRange in
                if subtextRange.intersection(clozeRange) != nil {
                    return clozeRange
                } else {
                    return nil
                }
            }
            
            if subtextClozeRanges.isEmpty {
                continue
            }
            if practiceType == .listenAndComplete 
                && subtextClozeRanges.count >= ListeningPracticeProducer.maxClozeNumForListenAndComplete {
                subtextClozeRanges = subtextClozeRanges.randomElements(of: ListeningPracticeProducer.maxClozeNumForListenAndComplete)
            }
            
            let (existingPhraseRanges, existingPhraseMeanings) = findExistingPhraseRangesAndMeanings(
                for: text,
                from: self.words
            )
            
            practices.append(ListeningPractice(
                practiceType: practiceType,
                prompt: makePrompt(for: practiceType),
                text: text,
                meaning: meaning,
                textLang: LangCode.currentLanguage,
                meaningLang: LangCode.currentLanguage.configs.languageForTranslation,
                textSource: textSource,
                isTextMachineTranslated: isTextMachineTranslated,
                machineTranslatorType: machineTranslatorType,
                clozeRanges: subtextClozeRanges,
                existingPhraseRanges: existingPhraseRanges,
                existingPhraseMeanings: existingPhraseMeanings,
                totalRepetitions: LangCode.currentLanguage.configs.practiceRepetition,
                currentRepetition: 0
            ))
        }
        return practices
    }
    
    private func makePractice(
        ofType practiceType: ListeningPractice.PracticeType,
        for randomWord: Word? = nil,
        inGranularity granularity: TextGranularity,
        callBack: @escaping (ListeningPractice) -> Void
    ) {
     
        generateTextMeaning(
            randomWord: randomWord,
            granularity: granularity,
            machineTranslator: self.machineTranslator,
            contentCreator: self.contentCreator
        ) { text, meaning, textSource, isTextMachineTranslated, machineTranslatorType in
            for practice in self.makePractice(
                practiceType: practiceType,
                granularity: granularity,
                text: text,
                meaning: meaning,
                textSource: textSource,
                isTextMachineTranslated: isTextMachineTranslated,
                machineTranslatorType: machineTranslatorType
            ) {
                callBack(practice)
            }
        }
        
    }
}

extension ListeningPracticeProducer {
    
    // MARK: - IO
    
    static func fileName(for lang: String) -> String {
        return "cachedListeningPractices.\(lang).json"
    }
    
    static func loadCachedPractices(for lang: LangCode) -> [ListeningPractice] {
        do {
            let practices = try readDataFromJson(
                fileName: ListeningPracticeProducer.fileName(for: lang.rawValue),
                type: [ListeningPractice].self
            ) as? [ListeningPractice] ?? []
            return practices
        } catch {
            return []
        }
    }
    
    static func save(_ practicesToCache: inout [ListeningPractice], for lang: LangCode) {
        do {
            try writeDataToJson(
                fileName: ListeningPracticeProducer.fileName(for: lang.rawValue),
                data: practicesToCache
            )
        } catch {
            print(error.localizedDescription)
        }
    }
    
}

extension ListeningPracticeProducer {
    
    // MARK: - Constants
    
    static let maxClozeNumForListenAndComplete: Int = 10
    static let listenAndRepeatRedoThredshold: Float = 0.6
    static let minSubsentenceWordCountThreshold: Int = 5
    
}
