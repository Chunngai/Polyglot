//
//  PracticeProducerDelegate.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

class BasePracticeProducer {
    
    var words: [Word]!
    var articles: [Article]!
    var groupedArticles: [GroupedArticles]!
    
    var practiceList: [BasePractice] = []
    var currentPracticeIndex: Int = 0
    var currentPractice: BasePractice {
        get {
            if self.practiceList.isEmpty {
                self.practiceList.append(contentsOf: self.make())
            }
            
            return self.practiceList[self.currentPracticeIndex]
        }
        set {
            self.practiceList[self.currentPracticeIndex] = newValue
        }
    }
    
    var batchSize: Int = 6
    
    var machineTranslator: MachineTranslator = MachineTranslator(
        srcLang: LangCode.currentLanguage,
        trgLang: LangCode.currentLanguage.configs.languageForTranslation
    )
    var contentCreator: ContentCreator = ContentCreator()
    
    init(words: [Word], articles: [Article]) {
        self.words = words
        self.articles = articles
        self.groupedArticles = articles.groups
    }
    
    func make() -> [BasePractice] {
        fatalError("make() has not been implemented.")
    }
    
    func next() {
        fatalError("next() has not been implemented.")
    }
    
    func load(_ cachedPractices: [BasePractice]) {
        fatalError("load(_) has not been implemented.")
    }
    
    func cache() {
        fatalError("cache() has not been implemented.")
    }
}

extension BasePracticeProducer {
    
    // MARK: - IO
    
    static func metaDataFileName(for lang: LangCode) -> String {
        return "practice.meta.\(lang.rawValue).json"
    }
    
    static func loadMetaData(for lang: LangCode) -> [String:String] {
        do {
            let metaData = try readDataFromJson(
                fileName: BasePracticeProducer.metaDataFileName(for: lang),
                type: [String:String].self
            ) as? [String:String] ?? [:]
            return metaData
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static func saveMetaData(_ metaData: inout [String:String], for lang: LangCode) {
        do {
            try writeDataToJson(
                fileName: BasePracticeProducer.metaDataFileName(for: lang),
                data: metaData
            )
        } catch {
            print(error)
            exit(1)
        }
    }
    
}
