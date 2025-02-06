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
        super.init(
            words: words, 
            articles: articles, 
            isDuolingoOnly: LangCode.currentLanguage.isDuolingoOnlyForReading
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
        while self.practiceList.isEmpty {  // TODO: - Improve here.
            
        }
        
        // self.currentPracticeIndex SHOULD ALWAYS BE 0
        // AS DONE PRACTICES WILL BE REMOVED FROM THE LIST.
        self.currentPracticeIndex = 0
        
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
        
        var practiceList: [ReadingPractice] = []
        while true {
            
            if paraIndex >= randomArticle.paras.count {
                break
            }
            
            let para = randomArticle.paras[paraIndex]
            let sentences = para.text.tokenized(with: LangCode.currentLanguage.sentenceTokenizer)
            for (sentenceId, sentence) in sentences.enumerated() {
                
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
                
                maybeTranslate(text: sentence) { translation, isTranslated, translatorType, translationQuery in
                    for practice in self.practiceList {
                        guard let practice = practice as? ReadingPractice else {
                            continue
                        }
                        if practice.text == translationQuery {
                            practice.meaning = translation
                            practice.isTextMachineTranslated = isTranslated
                            practice.machineTranslatorType = translatorType
                            break
                        }
                    }
                }
                calculateAccentLocsForText(in: practice)
            }
            if practiceList.count >= batchSize {
                break
            }
            
            paraIndex += 1
        }
        if practiceList.count < batchSize {
            practiceList.append(contentsOf: self.make() as! [ReadingPractice])
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
