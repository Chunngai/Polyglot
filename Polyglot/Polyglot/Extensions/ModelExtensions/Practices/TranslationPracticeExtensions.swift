//
//  TranslationPracticeExtensions.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct TranslationPracticeProducer {
    
    var articles: [Article] {
        didSet {
            
            if articles.isEmpty {
                articles.append(Article.dummyArticle)
            }
            
        }
    }
    
    var practiceList: [TranslationPracticeProducer.Item]
    var currentPracticeIndex: Int {
        didSet {
            if currentPracticeIndex >= practiceList.count {
                practiceList.append(make())
            }
        }
    }
    var currentPractice: TranslationPracticeProducer.Item {
        return practiceList[currentPracticeIndex]
    }
    
    init(articles: [Article]) {
        self.articles = articles
        
        self.practiceList = []
        self.currentPracticeIndex = 0
        
        self.practiceList.append(make())
    }
    
    func make() -> TranslationPracticeProducer.Item {
        // Randomly choose an article.
        let randomArticle = articles.randomElement()!
        // Randomly choose a paragraph.
        let randomParagraph = randomArticle.paras.randomElement()!
        if !randomParagraph.isParallel {
            return make()  // TODO: - Use a translation api instead?
        }
        // Randomly choose a direction.
        let randomDirection = UInt.random(from: [0.2, 0.8])  // 0.2 prob for text -> meaning and 0.8 prob for meaning -> text.
        
        return TranslationPracticeProducer.Item(
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
        )
    }
    
    mutating func next() {
        currentPracticeIndex += 1
    }
}

extension TranslationPracticeProducer {
    
    struct Item {
        
        var practice: TranslationPractice
        
        var text: String
        var meaning: String
        
    }
    
}
