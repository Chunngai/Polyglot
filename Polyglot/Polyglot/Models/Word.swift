//
//  Word.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation

struct Word {
    
    var id: Int
    var creationDate: Date
    var modificationDate: Date
    
    var word: String
    var meaning: String
    var groupNote: String
    
    init(creationDate: Date = Date(), word: String, meaning: String, groupNote: String = "") {
        
        // For adding new words.
        
        self.word = word
        self.meaning = meaning
        self.groupNote = groupNote
        
        self.id = word.hashValue
        self.creationDate = creationDate
        self.modificationDate = creationDate
    }
    
    func update() {
        
        // TODO: - For editing. Modify the modification date here.
        
    }
}

extension Word: Codable {
    
    // MARK: - IO
    
    static let fileName: String = "words.json"
    
    static func load() -> [Word] {
        do {
            let words = try readSequenceDataFromJson(fileName: Word.fileName, type: Word.self) as! [Word]
            
            return words
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static func save(_ words: inout [Word]) {
        do {
            try writeSequenceDataFromJson(fileName: Word.fileName, data: words)
        } catch {
            print(error)
            exit(1)
        }
    }
    
}

extension Word {
    
    // Only for debugging.
//    init(word: String, meaning: String, groupNote: String = "", creationDate: Date) {
//
//        // For adding new words.
//
//        self.id = Date().hashValue
//        self.creationDate = creationDate
//        self.modificationDate = creationDate
//
//        self.word = word
//        self.meaning = meaning
//        self.groupNote = groupNote
//    }
    
//    static var samples: [Word] = [
//        Word(creationDate: Date(), word: "中間試験", meaning: "期中考"),
//        Word(creationDate: Date(), word: "秘密兵器", meaning: "秘密兵器"),
//        Word(creationDate: Date(), word: "出題範囲", meaning: "出题范围"),
//        Word(creationDate: Date(), word: "図工", meaning: "手工"),
//        Word(creationDate: Date(), word: "戦争から立ち直る", meaning: "从战争中重振"),
//        Word(creationDate: Date(), word: "作戦する", meaning: "行动"),
//        Word(creationDate: Date(), word: "水道水", meaning: "自来水"),
//        Word(creationDate: Date(), word: "辺鄙な", meaning: "偏僻的"),
//        Word(creationDate: Date(timeInterval: 300000, since: Date()), word: "作戦する", meaning: "行动"),
//        Word(creationDate: Date(timeInterval: 300000, since: Date()), word: "水道水", meaning: "自来水"),
//        Word(creationDate: Date(timeInterval: 300000, since: Date()), word: "辺鄙な", meaning: "偏僻的")
//    ]
    
}
