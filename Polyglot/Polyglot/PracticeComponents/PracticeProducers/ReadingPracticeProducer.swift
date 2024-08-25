//
//  ReadingPracticeProducer.swift
//  Polyglot
//
//  Created by Ho on 8/25/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation

class ReadingPracticeProducer: TextMeaningPracticeProducer {
    
    // MARK: - Init
    
    override init(words: [Word], articles: [Article]) {
        super.init(words: words, articles: articles)
        
        // Override the batch size.
        self.batchSize = LangCode.currentLanguage.configs.readingPracticeDuration
        
        let cachedReadingPractices = ReadingPracticeProducer.loadCachedPractices(for: LangCode.currentLanguage)
        if !cachedReadingPractices.isEmpty {
            self.practiceList.append(contentsOf: cachedReadingPractices)
        } else {
            self.practiceList.append(contentsOf: make())
        }
    }
    
    override func next() {
        if self.practiceList.isEmpty {
            self.practiceList.append(contentsOf: self.make())
        }
        while self.practiceList.isEmpty {  // TODO: - Improve here.
            
        }
        
        // self.currentPracticeIndex SHOULD ALWAYS BE 0
        // AS DONE PRACTICES WILL BE REMOVED FROM THE LIST.
//        self.currentPracticeIndex = 0
        
        if self.practiceList.count <= batchSize {
            DispatchQueue.global(qos: .userInitiated).async {
                self.practiceList.append(contentsOf: self.make())
            }
        }
    }
    
    override func make() -> [BasePractice] {
        
        guard let randomGroupedArticles = self.groupedArticles.randomElement() else {
            return []
        }
        guard let randomArticle = randomGroupedArticles.articles.randomElement() else {
            return []
        }
        guard var paraIndex = (0..<randomArticle.paras.count).randomElement() else {
            return []
        }
        
        paraIndex -= batchSize
        if paraIndex < 0 {
            paraIndex = 0
        }
        
        var practiceList: [ReadingPractice] = []
        for _ in 0..<batchSize {
             
            if paraIndex < randomArticle.paras.count {
                let para = randomArticle.paras[paraIndex]
                
                let (existingPhraseRanges, existingPhraseMeanings) = findExistingPhraseRangesAndMeanings(
                    for: para.text,
                    from: self.words
                )
                
                practiceList.append(ReadingPractice(
                    text: para.text,
                    meaning: "",
                    textLang: LangCode.currentLanguage,
                    meaningLang: LangCode.currentLanguage.configs.languageForTranslation,
                    textSource: .article(
                        articleId: randomArticle.id,
                        paragraphId: para.id,
                        sentenceId: nil
                    ),
                    isTextMachineTranslated: false,
                    machineTranslatorType: .none,
                    existingPhraseRanges: existingPhraseRanges,
                    existingPhraseMeanings: existingPhraseMeanings
                ))
                
                paraIndex += 1
            } else {
                break
            }
            
        }
        
        return practiceList
    }
    
    override func cache() {
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
    
    // MARK: - IO
    
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
