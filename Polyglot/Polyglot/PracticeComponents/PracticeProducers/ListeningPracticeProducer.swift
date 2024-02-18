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
        
        let cachedListeningPractices = ListeningPracticeProducer.loadCachedPractices(for: LangCode.currentLanguage)
        if !cachedListeningPractices.isEmpty {
            self.practiceList.append(contentsOf: cachedListeningPractices)
        } else {
            self.practiceList.append(contentsOf: make())
        }
        // Create and save new cached practices for the use of next time.
        DispatchQueue.global(qos: .userInitiated).async {
            guard var listeningPracticesToCache = self.make() as? [ListeningPractice] else {
                return
            }
            ListeningPracticeProducer.save(
                &listeningPracticesToCache,
                for: LangCode.currentLanguage
            )
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
                    inGranularity: TextGranularity.sentence,
                    callBack: { listenAndRepeatPractice in
                        practiceList.append(listenAndRepeatPractice)
                    }
                )
            } else if n == 1 {
                makePractice(
                    ofType: .listenAndRepeat,
                    inGranularity: TextGranularity.sentence,
                    callBack: { listenAndRepeatPractice in
                        practiceList.append(listenAndRepeatPractice)
                    }
                )
            }
        }
        
        let startTime = Date()
        while true {
            if practiceList.count >= batchSize {
                break
            }
            
            if Date().timeIntervalSince(startTime) >= ListeningPracticeProducer.practiceMakingTimeThredshold {
                break
            }
            Thread.sleep(forTimeInterval: 0.1)  // For avoiding high CPU usage.
        }
        
        practiceList.shuffle()
        return practiceList
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
    
    private func generateRanges(for text: String) -> [NSRange] {
                
        var clozeRanges: [NSRange] = []

        // For Japanese and some languages, tokenization is crucial.
        var tokens = text.tokenized(with: LangCode.currentLanguage.wordTokenizer)
        guard !tokens.isEmpty else {
            return []
        }
        
        var tokenBuffer: String = ""
        var location: Int = 0
        var length: Int = 0
        for (i, character) in text.enumerated() {
            
            if tokenBuffer == tokens[0] {
                clozeRanges.append(NSRange(
                    location: location,
                    length: length
                ))
                tokens.remove(at: 0)
                tokenBuffer = ""
                
//                print(
//                    location,
//                    length,
//                    (text as NSString).substring(with: NSRange(
//                        location: location,
//                        length: length
//                    ))
//                )
            }
            
            if tokens.isEmpty {
                break
            }
            
            if character == tokens[0].first! && tokenBuffer.isEmpty {
                location = i
                length = 1
                tokenBuffer = String(character)
                continue
            }
            
            if tokens[0].starts(with: tokenBuffer + String(character)) {
                tokenBuffer += String(character)
                length += 1
                continue
            }
            
            tokenBuffer = ""
        }

        if !tokenBuffer.isEmpty {
            clozeRanges.append(NSRange(
                location: location,
                length: length
            ))
        }
        
        return clozeRanges
    }
    
    private func makePractice(
        practiceType: ListeningPractice.PracticeType,
        text: String,
        meaning: String,
        textSource: TextSource,
        isTextMachineTranslated: Bool
    ) -> ListeningPractice? {
                    
        var clozeRanges: [NSRange] = generateRanges(for: text)
        if clozeRanges.isEmpty {
            return nil
        }
        if practiceType == .listenAndComplete && clozeRanges.count >= ListeningPracticeProducer.maxClozeNumForListenAndComplete {
            clozeRanges = clozeRanges.randomElements(of: ListeningPracticeProducer.maxClozeNumForListenAndComplete)
        }
        
        let (existingPhraseRanges, existingPhraseMeanings) = findExistingPhraseRangesAndMeanings(for: text)
        
        return ListeningPractice(
            practiceType: practiceType,
            prompt: makePrompt(for: practiceType),
            text: text,
            meaning: meaning,
            textLang: LangCode.currentLanguage,
            meaningLang: LangCode.pairedLanguage,
            textSource: textSource,
            isTextMachineTranslated: isTextMachineTranslated,
            clozeRanges: clozeRanges,
            existingPhraseRanges: existingPhraseRanges,
            existingPhraseMeanings: existingPhraseMeanings
        )
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
            translator: self.translator,
            contentCreator: self.contentCreator
        ) { text, meaning, textSource, isTextMachineTranslated in
            guard let practice = self.makePractice(
                practiceType: practiceType,
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

extension ListeningPracticeProducer {
    
    func checkCorrectness(of submission: Any) {
        guard let currentPractice = currentPractice as? ListeningPractice else {
            return
        }
        
        if currentPractice.practiceType == .listenAndRepeat {
            guard let matchedClozeRanges = submission as? [NSRange] else {
                return
            }
            if Double(matchedClozeRanges.count) / Double(currentPractice.clozeRanges.count) <= ListeningPracticeProducer.listenAndRepeatRedoThredshold {
                practiceList.append(ListeningPractice(from: currentPractice))
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
    static let listenAndRepeatRedoThredshold: Double = 0.6
    
}
