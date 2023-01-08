//
//  ReadingPracticeExtensions.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct ReadingPracticeProducer {
    
    var articles: [Article] {
        didSet {
            
            if articles.isEmpty {
                articles.append(Article.dummyArticle)
            }
            
        }
    }
    
    var practiceList: [ReadingPracticeProducer.Item]
    var currentPracticeIndex: Int {
        didSet {
            if currentPracticeIndex >= practiceList.count {
                practiceList.append(make())
            }
        }
    }
    var currentPractice: ReadingPracticeProducer.Item {
        return practiceList[currentPracticeIndex]
    }
    
    init(articles: [Article]) {
        self.articles = articles
        
        self.practiceList = []
        self.currentPracticeIndex = 0
        
        self.practiceList.append(make())
    }
    
    // TODO: - Update
    func make() -> ReadingPracticeProducer.Item {
        // Randomly choose an article.
        let randomArticle = articles.randomElement()!
        // Randomly choose a paragraph.
        let randomParagraph = randomArticle.paras.randomElement()!
        
        return ReadingPracticeProducer.Item(
            practice: ReadingPractice(
                articleId: randomArticle.id,
                paragraphId: randomParagraph.id
            ),
            text: randomParagraph.text,
            meaning: randomParagraph.meaning
        )
    }
    
    mutating func next() {
        currentPracticeIndex += 1
    }
}

extension ReadingPracticeProducer {
    
    struct Item {
        
        var practice: ReadingPractice
        
        var text: String
        var meaning: String?
    }
    
}
