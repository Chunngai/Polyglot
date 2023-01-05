//
//  ArticleExt.swift
//  Polyglot
//
//  Created by Sola on 2022/12/25.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation

extension Article {
    
    var query: String {
        return title + body + source
    }
}

extension Array where Iterator.Element == Article {

    // TODO: - Simplify the for loops?

    func getArticle(from id: Int) -> Article? {
        for article in self {
            if article.id == id {
                return article
            }
        }
        return nil
    }
    
    mutating func add(newArticle: Article) {
        append(newArticle)
    }
    
    mutating func updateArticle(of id: Int, newTitle: String? = nil, newBody: String? = nil, newSource: String? = nil) {
        for i in 0..<count {
            if self[i].id == id {
                self[i].update(newTitle: newTitle, newBody: newBody, newSource: newSource)
                return
            }
        }
    }
    
    mutating func removeArticle(of id: Int) {
        for i in 0..<count {
            if self[i].id == id {
                self.remove(at: i)
                return
            }
        }
    }
    
    func subset(containing keyWord: String) -> [Article] {
        var subset: [Article] = []
        for article in self {
            if article.query.contains(keyWord) {
                subset.append(article)
            }
        }
        return subset
    }
}

extension Array where Iterator.Element == Article {
    
    
    
}
