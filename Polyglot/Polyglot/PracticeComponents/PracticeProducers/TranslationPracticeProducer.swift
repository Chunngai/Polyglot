//
//  TranslationPracticeExtensions.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

class TranslationPracticeProducer: PracticeProducerDelegate {
    
    typealias U = TranslationPracticeProducer.Item
    
    var words: [Word] = []
    var articles: [Article]
    var batchSize: Int
    
    var practiceList: [TranslationPracticeProducer.Item] = []
    var currentPracticeIndex: Int = 0 {
        didSet {
            if currentPracticeIndex >= practiceList.count {
                practiceList.append(contentsOf: make())
            }
        }
    }
    var currentPractice: TranslationPracticeProducer.Item {
        get {
            return practiceList[currentPracticeIndex]
        }
        set {
            practiceList[currentPracticeIndex] = newValue
        }
    }
    
    init(articles: [Article]) {
        self.articles = articles
        self.batchSize = self.articles.count >= TranslationPracticeProducer.defaultBatchSize ?
            TranslationPracticeProducer.defaultBatchSize :
            self.articles.count
        
        self.practiceList.append(contentsOf: make())
    }
    
    func make() -> [TranslationPracticeProducer.Item] {
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
        
        var practiceList: [TranslationPracticeProducer.Item] = []
        for i in randomParaStartIndex...randomParaEndIndex {
            
            let para = randomArticle.paras[i]
            
            // Randomly choose a direction.
//            let randomDirection = Array<PracticeDirection>(arrayLiteral: .textToMeaning, .meaningToText).randomElement(from: [0.2, 0.8])!  // 0.2 prob for text -> meaning and 0.8 prob for meaning -> text.
            let randomDirection = PracticeDirection.meaningToText
            
            var text: String!
            var meaning: String!
            var textLang: LangCode!
            var meaningLang: LangCode!
            if randomDirection == .textToMeaning {
                text = para.text
                meaning = para.meaning
                textLang = LangCode.currentLanguage
                meaningLang = LangCode.pairedLanguage
            } else if randomDirection == .meaningToText {
                text = para.meaning
                meaning = para.text
                textLang = LangCode.pairedLanguage
                meaningLang = LangCode.currentLanguage
            }
            
            practiceList.append(TranslationPracticeProducer.Item(
                practice: TranslationPractice(
                    articleId: randomArticle.id,
                    paragraphId: para.id,
                    direction: randomDirection
                ),
                text: text,
                meaning: meaning,
                textLang: textLang,
                meaningLang: meaningLang
            ))
        }
        return practiceList
    }
}

extension TranslationPracticeProducer {
    
    struct Item: PracticeDelegate {
        
        typealias T = TranslationPractice
        var practice: TranslationPractice
        
        var text: String?
        var meaning: String?
     
        var textLang: LangCode
        var meaningLang: LangCode
    }
    
}
