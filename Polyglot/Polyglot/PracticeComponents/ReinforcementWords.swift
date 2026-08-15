//
//  ReinforcementWords.swift
//  Polyglot
//
//  Created by Ho on 8/12/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import Foundation

/// Persistent record of a word added to reinforcement practice from a text-meaning session.
struct ReinforcementWordEntry: Codable {
    var word: String
    /// The annotated sentence that contains this word (accent/grammar annotations already applied).
    var contextSentence: String
    /// Machine-translated meaning of the word. Empty string until translation completes.
    var meaning: String
}

enum ReinforcementWords {

    // MARK: - IO

    static func fileName(for lang: LangCode) -> String {
        return "reinforcementWords.\(lang.rawValue).json"
    }

    static func load(for lang: LangCode) -> [String: ReinforcementWordEntry] {
        do {
            let entries = try readDataFromJson(
                fileName: fileName(for: lang),
                type: [ReinforcementWordEntry].self
            ) as? [ReinforcementWordEntry] ?? []
            return Dictionary(uniqueKeysWithValues: entries.map { ($0.word, $0) })
        } catch {
            return [:]
        }
    }

    static func save(_ entries: inout [String: ReinforcementWordEntry], for lang: LangCode) {
        do {
            let arr = Array(entries.values)
            try writeDataToJson(fileName: fileName(for: lang), data: arr)
        } catch {
            print(error)
        }
    }

    static func add(word: String, contextSentence: String, meaning: String, for lang: LangCode) {
        var entries = load(for: lang)
        let key = WordPracticeProducer.normalizedKey(from: word)
        if entries[key] == nil {
            entries[key] = ReinforcementWordEntry(
                word: word,
                contextSentence: contextSentence,
                meaning: meaning
            )
            save(&entries, for: lang)
        }
    }

    static func remove(word: String, for lang: LangCode) {
        var entries = load(for: lang)
        let key = WordPracticeProducer.normalizedKey(from: word)
        entries.removeValue(forKey: key)
        save(&entries, for: lang)
    }

    static func updateMeaning(_ meaning: String, forWord word: String, for lang: LangCode) {
        var entries = load(for: lang)
        let key = WordPracticeProducer.normalizedKey(from: word)
        if entries[key] != nil {
            entries[key]!.meaning = meaning
            save(&entries, for: lang)
        }
    }

    static func updateContextSentence(_ sentence: String, forWord word: String, for lang: LangCode) {
        var entries = load(for: lang)
        let key = WordPracticeProducer.normalizedKey(from: word)
        if entries[key] != nil {
            entries[key]!.contextSentence = sentence
            save(&entries, for: lang)
        }
    }
}
