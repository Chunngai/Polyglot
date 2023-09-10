//
//  WordCardEntry.swift
//  Polyglot
//
//  Created by Sola on 2023/9/10.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct WordCardEntry: Codable {
    
    var title: String
    var body: String
    
}

extension WordCardEntry {
    
    // MARK: - IO
    
    static func fileName(for lang: String) -> String {
        return "wordCardEntries.\(lang).json"
    }
    
    static func load(for lang: String) -> [WordCardEntry] {
        do {
            let entries = try readSequenceDataFromJson(fileName: WordCardEntry.fileName(for: lang), type: WordCardEntry.self) as! [WordCardEntry]
            return entries
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static func save(_ entries: inout [WordCardEntry], for lang: String) {
        do {
            try writeSequenceDataFromJson(fileName: WordCardEntry.fileName(for: lang), data: entries)
        } catch {
            print(error)
            exit(1)
        }
    }
}

extension WordCardEntry {
    
    // MARK: - Constants
    
    static let maxEntryNumber: Int = 100
    
}
