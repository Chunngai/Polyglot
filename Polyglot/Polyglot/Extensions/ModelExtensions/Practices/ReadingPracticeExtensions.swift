//
//  ReadingPracticeExtensions.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct ReadingPracticeProducer: PracticeProducerDelegate {
    
    typealias T = Article
    typealias U = ReadingPracticeProducer.Item
    
    var dataSource: [Article] {
        didSet {
            
            if dataSource.isEmpty {
                dataSource.append(Article.dummyArticle)
            }
            
        }
    }
    
    var practiceList: [ReadingPracticeProducer.Item]
    var currentPracticeIndex: Int {
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
        self.dataSource = articles
        
        self.practiceList = []
        self.currentPracticeIndex = 0
        
        self.practiceList.append(contentsOf: make())
    }
    
    // TODO: - Update
    func make() -> [ReadingPracticeProducer.Item] {
        // Randomly choose a topic.
        let randomTopic = dataSource.topics.randomElement()!
        
        var practiceList: [ReadingPracticeProducer.Item] = []
        for _ in 0..<10 {
            
            // Randomly choose an article.
            let randomArticle = dataSource.compactMap({ (article) -> Article? in
                return article.topic == randomTopic ? article : nil
            }).randomElement()!
            // Randomly choose a paragraph.
            let randomParagraph = randomArticle.paras.randomElement()!
            
            practiceList.append(ReadingPracticeProducer.Item(
                practice: ReadingPractice(
                    articleId: randomArticle.id,
                    paragraphId: randomParagraph.id
                ),
                text: randomParagraph.text,
                meaning: randomParagraph.meaning
            ))
            
        }
        return practiceList
    }
    
    mutating func next() {
        currentPracticeIndex += 1
    }
}

extension ReadingPracticeProducer {
    
    struct Item: PracticeItemDelegate {
        
        typealias T = ReadingPractice
        
        var practice: ReadingPractice
        
        var text: String
        var meaning: String?
    }
    
}
