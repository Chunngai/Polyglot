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
    
    var practiceList: [BasePractice] = []
    var currentPracticeIndex: Int = 0
    var currentPractice: BasePractice {
        get {
            if currentPracticeIndex >= practiceList.count {
                self.practiceList.append(contentsOf: self.make())
            }
            return practiceList[currentPracticeIndex]
        }
        set {
            practiceList[currentPracticeIndex] = newValue
        }
    }
    
    var batchSize: Int = 6
    
    init(words: [Word], articles: [Article]) {
        self.words = words
        self.articles = articles
    }
    
    func make() -> [BasePractice] {
        fatalError("make() has not been implemented.")
    }
    
    func next() {
        currentPracticeIndex += 1
        if currentPracticeIndex >= practiceList.count - batchSize {
            DispatchQueue.global(qos: .userInitiated).async {
                self.practiceList.append(contentsOf: self.make())
            }
        }
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
