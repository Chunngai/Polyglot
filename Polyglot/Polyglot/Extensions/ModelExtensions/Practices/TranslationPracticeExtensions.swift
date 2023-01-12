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
    
    var dataSource: [Article] {
        didSet {
            
            if dataSource.isEmpty {
                dataSource.append(Article.dummyArticle)
            }
            
        }
    }
    
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
        
        self.practiceList = []
        self.currentPracticeIndex = 0
        
        self.practiceList.append(contentsOf: make())
    }
    
    func make() -> [TranslationPracticeProducer.Item] {
        // Randomly choose a topic.
        let randomTopic = dataSource.topics.randomElement()!
        
        var practiceList: [TranslationPracticeProducer.Item] = []
        for _ in 0..<10 {
            
            // Randomly choose an article.
            let randomArticle = dataSource.compactMap({ (article) -> Article? in
                return article.topic == randomTopic ? article : nil
            }).randomElement()!
            // Randomly choose a paragraph.
            let randomParagraph = randomArticle.paras.randomElement()!
            if !randomParagraph.isParallel {
                return make()  // TODO: - Use a translation api instead?
            }
            // Randomly choose a direction.
            let randomDirection = UInt.random(from: [0.2, 0.8])  // 0.2 prob for text -> meaning and 0.8 prob for meaning -> text.
            
            practiceList.append(TranslationPracticeProducer.Item(
                practice: TranslationPractice(
                    articleId: randomArticle.id,
                    paragraphId: randomParagraph.id,
                    direction: randomDirection
                ),
                text: randomDirection == 0 ?
                    randomParagraph.text :
                    randomParagraph.meaning!,
                meaning: randomDirection == 0 ?
                    randomParagraph.meaning! :
                    randomParagraph.text
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
        
        var text: String
        var meaning: String
        
    }
    
}
