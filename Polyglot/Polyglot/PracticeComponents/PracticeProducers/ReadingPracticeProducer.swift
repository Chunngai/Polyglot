//
//  ReadingPracticeExtensions.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

class ReadingPracticeProducer: PracticeProducerDelegate {
    
    typealias U = ReadingPracticeProducer.Item
    
    var words: [Word] = []
    var articles: [Article]
    var batchSize: Int
    
    var practiceList: [ReadingPracticeProducer.Item] = []
    var currentPracticeIndex: Int = 0 {
        didSet {
            if currentPracticeIndex >= practiceList.count {
                practiceList.append(contentsOf: make())
            }
        }
    }
    var currentPractice: ReadingPracticeProducer.Item {
        get {
            return practiceList[currentPracticeIndex]
        }
        set {
            practiceList[currentPracticeIndex] = newValue
        }
    }
    
    init(articles: [Article]) {
        self.articles = articles
        self.batchSize = self.articles.count >= ReadingPracticeProducer.defaultBatchSize ?
            ReadingPracticeProducer.defaultBatchSize :
            self.articles.count
        
        self.practiceList.append(contentsOf: make())
    }
    
    // TODO: - Update
    func make() -> [ReadingPracticeProducer.Item] {
        // Randomly choose a topic.
        let randomTopic = self.articles.topics.randomElement()!

        // Randomly choose an article.
        let randomArticle = self.articles.compactMap({ (article) -> Article? in
            return article.topic == randomTopic ? article : nil
        }).randomElement()!
        
        // Randomly choose a paragraph.
        let randomParaStartIndex = (0..<randomArticle.paras.count).randomElement()!
        var randomParaEndIndex = randomParaStartIndex + self.batchSize - 1
        if randomParaEndIndex >= randomArticle.paras.count {
            randomParaEndIndex = randomArticle.paras.count - 1
        }
        
        var practiceList: [ReadingPracticeProducer.Item] = []
        for i in randomParaStartIndex...randomParaEndIndex {
            let para = randomArticle.paras[i]
            practiceList.append(ReadingPracticeProducer.Item(
                practice: ReadingPractice(
                    articleId: randomArticle.id,
                    paragraphId: para.id
                ),
                text: para.text,
                meaning: para.meaning,
                textLang: LangCode.currentLanguage,
                meaningLang: LangCode.pairedLanguage
            ))
            
        }
        return practiceList
    }
}

extension ReadingPracticeProducer {
    
    struct Item: PracticeDelegate {
        
        typealias T = ReadingPractice
        var practice: ReadingPractice
        
        var text: String
        var meaning: String?
        
        var textLang: LangCode
        var meaningLang: LangCode
    }
    
}
