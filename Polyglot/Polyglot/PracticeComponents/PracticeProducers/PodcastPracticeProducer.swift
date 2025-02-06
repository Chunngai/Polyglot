//
//  PodcastPracticeProducer.swift
//  Polyglot
//
//  Created by Ho on 1/19/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import Foundation

class PodcastPracticeProducer: TextMeaningPracticeProducer {
    
    var article: Article!
    var paraIndex: Int!
    
    // MARK: - Init
    
    override init(words: [Word], articles: [Article]) {
        super.init(
            words: words, 
            articles: articles, 
            isDuolingoOnly: LangCode.currentLanguage.isDuolingoOnlyForPodcast
        )
        
        let cachedPodcastPractices = PodcastPracticeProducer.loadCachedPractices(for: LangCode.currentLanguage)
        load(cachedPodcastPractices)
    }
    
    override func next() {
        if self.practiceList.isEmpty {
            self.practiceList.append(contentsOf: self.make())
        }
        while self.practiceList.isEmpty {  // TODO: - Improve here.
            
        }
        
        self.practiceList.remove(at: 0)
        
        if self.practiceList.count <= batchSize {
            DispatchQueue.global(qos: .userInitiated).async {
                self.practiceList.append(contentsOf: self.make())
            }
        }
    }
    
    override func make() -> [BasePractice] {
        
        func randomlyChooseArticleAndPara() {
            
            guard let randomGroupedArticles = self.groupedArticles.randomElement() else {
                return
            }

            guard let randomArticle = randomGroupedArticles.articles.randomElement() else {
                return
            }
            
            guard let paraIndex = (0..<randomArticle.paras.count).randomElement() else {
                return
            }
            
            self.article = randomArticle
            self.paraIndex = paraIndex
        }
        
        var practiceList: [PodcastPractice] = []
        while true {
            
            if self.article == nil
                || paraIndex >= self.article.paras.count {
                
                randomlyChooseArticleAndPara()
                guard article != nil, paraIndex != nil else {
                    return []
                }
                
            }
            
            let para = self.article.paras[paraIndex]
            paraIndex += 1
                
            let sentences = para.text.tokenized(with: LangCode.currentLanguage.sentenceTokenizer)
            for (sentenceId, sentence) in sentences.enumerated() {
                
                let (
                    existingPhraseRanges,
                    existingPhraseMeanings
                ) = findExistingPhraseRangesAndMeanings(
                    for: sentence,
                    from: self.words
                )
                let practice = PodcastPractice(
                    text: sentence,
                    meaning: "",
                    textLang: LangCode.currentLanguage,
                    meaningLang: LangCode.currentLanguage.configs.languageForTranslation,
                    textSource: .article(
                        articleId: self.article.id,
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
                        guard let practice = practice as? PodcastPractice else {
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
        }
        if practiceList.count < batchSize {
            practiceList.append(contentsOf: self.make() as! [PodcastPractice])
        }
        
        return practiceList
    }
    
    override func cache() {
        guard var practicesToCache = self.practiceList as? [PodcastPractice] else {
            return
        }
        PodcastPracticeProducer.save(
            &practicesToCache,
            for: LangCode.currentLanguage
        )
    }
}

extension PodcastPracticeProducer {
    
    // MARK: - IO
    
    static func fileName(for lang: String) -> String {
        return "cachedPodcastPractices.\(lang).json"
    }
    
    static func loadCachedPractices(for lang: LangCode) -> [PodcastPractice] {
        do {
            let practices = try readDataFromJson(
                fileName: PodcastPracticeProducer.fileName(for: lang.rawValue),
                type: [PodcastPractice].self
            ) as? [PodcastPractice] ?? []
            return practices
        } catch {
            return []
        }
    }
    
    static func save(_ practicesToCache: inout [PodcastPractice], for lang: LangCode) {
        do {
            try writeDataToJson(
                fileName: PodcastPracticeProducer.fileName(for: lang.rawValue),
                data: practicesToCache
            )
        } catch {
            print(error.localizedDescription)
        }
    }
    
}
