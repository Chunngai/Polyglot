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
    /// The sentence that contains this word.
    var contextSentence: String
    /// Accent/grammar analysis of `contextSentence`, computed once at reinforce time so
    /// practice generation and annotation backfill can reuse it instead of re-running
    /// `analyzeAccents` on the same text. Nil until the reinforce-tap analysis completes.
    var contextTokens: [Token]?
    /// Machine-translated meaning of the word. Empty string until translation completes.
    var meaning: String
}

enum ReinforcementWords {

    // MARK: - IO

    static func fileName(for lang: LangCode) -> String {
        return "reinforcementWords.\(lang.rawValue).json"
    }

    static func load(for lang: LangCode) -> [String: ReinforcementWordEntry] {
        withFileLock(fileName(for: lang)) {
            loadUnlocked(for: lang)
        }
    }

    static func save(_ entries: inout [String: ReinforcementWordEntry], for lang: LangCode) {
        let captured = entries
        withFileLock(fileName(for: lang)) {
            saveUnlocked(captured, for: lang)
        }
    }

    /// Atomically loads, mutates, and saves -- eliminates the read-modify-write race
    /// between this and any other caller (on any thread) that also goes through
    /// `load`/`save`/`update`.
    @discardableResult
    static func update<T>(
        for lang: LangCode,
        _ mutate: (inout [String: ReinforcementWordEntry]) -> T
    ) -> T {
        withFileLock(fileName(for: lang)) {
            var entries = loadUnlocked(for: lang)
            let result = mutate(&entries)
            saveUnlocked(entries, for: lang)
            return result
        }
    }

    static func add(word: String, contextSentence: String, contextTokens: [Token]? = nil, meaning: String, for lang: LangCode) {
        let key = WordPracticeProducer.normalizedKey(from: word)
        update(for: lang) { entries in
            if entries[key] == nil {
                entries[key] = ReinforcementWordEntry(
                    word: word,
                    contextSentence: contextSentence,
                    contextTokens: contextTokens,
                    meaning: meaning
                )
            }
        }
    }

    static func remove(word: String, for lang: LangCode) {
        let key = WordPracticeProducer.normalizedKey(from: word)
        update(for: lang) { entries in
            entries.removeValue(forKey: key)
        }
    }

    static func updateMeaning(_ meaning: String, forWord word: String, for lang: LangCode) {
        let key = WordPracticeProducer.normalizedKey(from: word)
        update(for: lang) { entries in
            if entries[key] != nil {
                entries[key]!.meaning = meaning
            }
        }
    }

    static func updateContextSentence(_ sentence: String, forWord word: String, for lang: LangCode) {
        let key = WordPracticeProducer.normalizedKey(from: word)
        update(for: lang) { entries in
            if entries[key] != nil {
                entries[key]!.contextSentence = sentence
            }
        }
    }

    private static func loadUnlocked(for lang: LangCode) -> [String: ReinforcementWordEntry] {
        do {
            let entries = try readDataFromJson(
                fileName: fileName(for: lang),
                type: [ReinforcementWordEntry].self
            ) as? [ReinforcementWordEntry] ?? []
            // Use normalizedKey (not the raw word) as the dictionary key: keeps entries keyed
            // consistently with add()/updateMeaning()/etc, and tolerates any legacy duplicate
            // raw-word text on disk instead of crashing on Dictionary construction.
            var result: [String: ReinforcementWordEntry] = [:]
            for entry in entries {
                result[WordPracticeProducer.normalizedKey(from: entry.word)] = entry
            }
            return result
        } catch {
            return [:]
        }
    }

    private static func saveUnlocked(_ entries: [String: ReinforcementWordEntry], for lang: LangCode) {
        do {
            let arr = Array(entries.values)
            try writeDataToJson(fileName: fileName(for: lang), data: arr)
        } catch {
            print(error)
        }
    }
}
