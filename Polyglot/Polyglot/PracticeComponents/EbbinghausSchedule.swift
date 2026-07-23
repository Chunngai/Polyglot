//
//  EbbinghausSchedule.swift
//  Polyglot
//
//  Created by Ho on 7/12/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import Foundation

struct WordReviewEntry: Codable {
    var wordKey: String
    var periodIndex: Int
    var nextReviewDate: Date
}

enum EbbinghausSchedule {

    // Days to wait after completing period N before the next period unlocks.
    static let intervalDays: [Int] = [1, 2, 4, 7, 15, 30]

    // The 3 practice types to use for each period, ordered easy → hard.
    static let practiceGroups: [[WordPractice.PracticeType]] = [
        [.meaningSelection, .contextSelection, .imageSelection],
        [.meaningSelection, .meaningFilling, .contextSelection],
        [.meaningFilling, .imageSelection, .reordering],
        [.contextSelection, .imageFilling, .phraseConstruction],
        [.reordering, .imageFilling, .phraseConstruction],
        [.reordering, .phraseConstruction, .accentSelection],
    ]

    // Difficulty-ordered fallback list used when filling gaps.
    static let allTypesByDifficulty: [WordPractice.PracticeType] = [
        .meaningSelection,
        .contextSelection,
        .imageSelection,
        .meaningFilling,
        .imageFilling,
        .reordering,
        .phraseConstruction,
        .accentSelection,
    ]

    // MARK: - Helpers

    static func isCompleted(_ entry: WordReviewEntry) -> Bool {
        return entry.periodIndex >= practiceGroups.count
    }

    static func isAvailable(_ entry: WordReviewEntry) -> Bool {
        return entry.nextReviewDate <= Date()
    }

    static func nextReviewDate(afterPeriod periodIndex: Int) -> Date {
        let days = intervalDays[min(periodIndex, intervalDays.count - 1)]
        return Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }

    // Returns the 3 effective practice types for the given period,
    // filtered by enabledTypes and padded with fallbacks if needed.
    static func effectivePracticeTypes(
        for periodIndex: Int,
        enabledTypes: Set<WordPractice.PracticeType>
    ) -> [WordPractice.PracticeType] {
        let clampedIndex = min(periodIndex, practiceGroups.count - 1)
        let preferred = practiceGroups[clampedIndex].filter { enabledTypes.contains($0) }
        var result = preferred
        if result.count < 3 {
            for t in allTypesByDifficulty {
                if !result.contains(t) && enabledTypes.contains(t) {
                    result.append(t)
                }
                if result.count == 3 { break }
            }
        }
        return result
    }

    static func entry(forKey key: String, in schedule: [String: WordReviewEntry]) -> WordReviewEntry {
        return schedule[key] ?? WordReviewEntry(
            wordKey: key,
            periodIndex: 0,
            nextReviewDate: .distantPast
        )
    }

    // MARK: - IO

    static func fileName(for lang: LangCode) -> String {
        return "ebbinghausSchedule.\(lang.rawValue).json"
    }

    static func load(for lang: LangCode) -> [String: WordReviewEntry] {
        do {
            let entries = try readDataFromJson(
                fileName: fileName(for: lang),
                type: [WordReviewEntry].self
            ) as? [WordReviewEntry] ?? []
            return Dictionary(uniqueKeysWithValues: entries.map { ($0.wordKey, $0) })
        } catch {
            return [:]
        }
    }

    static func save(_ schedule: inout [String: WordReviewEntry], for lang: LangCode) {
        do {
            let entries = Array(schedule.values)
            try writeDataToJson(fileName: fileName(for: lang), data: entries)
        } catch {
            print(error)
        }
    }
}
