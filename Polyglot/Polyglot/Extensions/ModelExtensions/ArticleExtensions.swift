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
        return title + body 
    }
    
    // TODO: - Make it an extension of [Article]?
    static func getArticle(from id: Int) -> Article? {  // TODO: - A more efficient method?
        for article in Article.load() {  // TODO: - Update "samples".
            if article.id == id {
                return article
            }
        }
        return nil
    }
}

extension Array where Iterator.Element == Article {
    
    mutating func removeArticle(of id: Int) {
        var index: Int = -1
        for i in 0..<count {  // TODO: - Remove the for loop here.
            if self[i].id == id {
                index = i
                break
            }
        }
        if index >= 0 {
            self.remove(at: index)
        }
    }
    
}
