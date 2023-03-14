//
//  TranslationPracticeExtensions.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct TranslationPracticeProducer: PracticeProducerDelegate {
    
    typealias T = Article
    typealias U = TranslationPracticeProducer.Item
    
    var dataSource: [Article]
    var batchSize: Int = 6
    
    var practiceList: [TranslationPracticeProducer.Item]
    var currentPracticeIndex: Int {
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
        self.dataSource = articles
        self.batchSize = dataSource.count >= TranslationPracticeProducer.defaultBatchSize ?
            TranslationPracticeProducer.defaultBatchSize :
            dataSource.count
        
        self.practiceList = []
        self.currentPracticeIndex = 0
        
        self.practiceList.append(contentsOf: make())
    }
    
    func make() -> [TranslationPracticeProducer.Item] {
        // Randomly choose a topic.
        let randomTopic = dataSource.topics.randomElement()!
        
        var practiceList: [TranslationPracticeProducer.Item] = []
        for _ in 0..<batchSize {
            
            // Randomly choose an article.
            let randomArticle = dataSource.compactMap({ (article) -> Article? in
                return article.topic == randomTopic ? article : nil
            }).randomElement()!
            // Randomly choose a paragraph.
            let randomParagraph = randomArticle.paras.randomElement()!
            // Randomly choose a direction.
            let randomDirection = Array<PracticeDirection>(arrayLiteral: .textToMeaning, .meaningToText).randomElement(from: [0.2, 0.8])!  // 0.2 prob for text -> meaning and 0.8 prob for meaning -> text.
            
            var text: String!
            var meaning: String!
            var textLang: String!
            var meaningLang: String!
            if randomDirection == .textToMeaning {
                text = randomParagraph.text
                meaning = randomParagraph.meaning
                textLang = Variables.lang
                meaningLang = Variables.pairedLang
            } else if randomDirection == .meaningToText {
                text = randomParagraph.meaning
                meaning = randomParagraph.text
                textLang = Variables.pairedLang
                meaningLang = Variables.lang
            }
            
            practiceList.append(TranslationPracticeProducer.Item(
                practice: TranslationPractice(
                    articleId: randomArticle.id,
                    paragraphId: randomParagraph.id,
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
    
    mutating func next() {
        currentPracticeIndex += 1
    }
}

extension TranslationPracticeProducer {
    
    struct Item: PracticeItemDelegate {
        
        typealias T = TranslationPractice
        
        var practice: TranslationPractice
        
        var text: String?
        var meaning: String?
     
        var textLang: String
        var meaningLang: String
    }
    
}

extension TranslationPracticeProducer {
    
    // MARK: - Constants
    
    static let defaultBatchSize: Int = 6
    
}
