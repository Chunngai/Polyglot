//
//  ArticleExt.swift
//  Polyglot
//
//  Created by Sola on 2022/12/25.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation

extension Paragraph {
    
    var isParallel: Bool {
        return meaning != nil
    }
    
}

extension Array where Iterator.Element == Paragraph {
    
    func getParagraph(from id: String) -> Paragraph? {
        for paragraph in self {
            if paragraph.id == id {
                return paragraph
            }
        }
        return nil
    }
    
}

extension Article {
    
    var body: String {
        var paraStrings: [String] = []
        for para in paras {
            let text = para.text
            let meaning = para.meaning
            
            var paraString = "\(text)"
            if let meaning = meaning {
                paraString = "\(paraString)\(Paragraph.textMeaningSeparator)\(meaning)"
            }
            paraStrings.append(paraString)
        }
        return paraStrings.joined(separator: Article.paraSeparator)
    }
    
    var query: String {
        return (title + body).lowercased()
    }
}

extension Array where Iterator.Element == Article {

    // TODO: - Simplify the for loops?

    func getArticle(from id: String) -> Article? {
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
    
    mutating func updateArticle(of id: String, newTitle: String? = nil, newTopic: String? = nil, newBody: String? = nil, newSource: String? = nil) {
        for i in 0..<count {
            if self[i].id == id {
                self[i].update(newTitle: newTitle, newTopic: newTopic, newBody: newBody, newSource: newSource)
                return
            }
        }
    }
    
    mutating func removeArticle(of id: String) {
        for i in 0..<count {
            if self[i].id == id {
                self.remove(at: i)
                return
            }
        }
    }
    
    func subset(containing keyWord: String) -> [Article] {
        if keyWord.isEmpty {
            return self
        }
        
        var subset: [Article] = []
        for article in self {
            if article.query.contains(keyWord) {
                subset.append(article)
            }
        }
        return subset
    }
}

extension Article {
    
    static let dummyArticle: Article = Article(
        title: "Dummy article",
        body: "The article list is empty.\nThis is a dummy article."
    )
    
}

extension Array where Iterator.Element == Article {
    
    var topics: [String] {
        self.compactMap { (article) -> String? in
            article.topic
        }
    }
    
}

extension Article {
    
    var groupId: String {
        return topic ?? ""
    }
    
}

// TODO: - Merge with GroupedWords?
struct GroupedArticles {
    
    // For storing articles grouped by group identifiers.
    
    var articles: [Article]
    
    var cDate: Date {
        articles[0].cDate
    }
    var groupId: String {
        articles[0].groupId
    }
    
    init(articles: [Article]) {
        self.articles = articles
    }
}

extension Array where Iterator.Element == Article {
    
    // TODO: - Improve here. It's time consuming to compute.
    var groups: [GroupedArticles] {
        var groupedArticlesMapping: [String: GroupedArticles] = [:]
        for article in self {
            let groupId = article.groupId
            
            groupedArticlesMapping.setDefault(value: GroupedArticles(articles: []), for: groupId)
            groupedArticlesMapping[groupId]?.articles.append(article)
        }
        
        // Sort groups.
        var groupedArticles = Array<GroupedArticles>(groupedArticlesMapping.values)
        groupedArticles.sort { (group1, group2) -> Bool in
            group1.cDate != group2.cDate
                ? group1.cDate > group2.cDate  // First, sort by date.
                : group1.groupId < group2.groupId  // Then, sort by groupId.
        }
        
        // Sort words in each group.
        for i in 0..<groupedArticles.count {
            groupedArticles[i].articles.sort { (article1, article2) -> Bool in
                article1.mDate > article2.mDate
            }
        }
        
        return groupedArticles
    }
}
