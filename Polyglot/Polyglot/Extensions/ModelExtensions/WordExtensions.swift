//
//  WordExt.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation

extension Word {
    
    var query: String {
        return (text + meaning).lowercased()
    }

}

extension Array where Iterator.Element == Word {
    
    // TODO: - Simplify the for loops?
    
    func getWord(from id: String) -> Word? {
        for word in self {
            if word.id == id {
                return word
            }
        }
        return nil
    }
    
    mutating func add(newWord: Word) {
        for existingWord in self {
            // Duplication check with the text var.
            if newWord.text == existingWord.text {
                print("Skipped: \(newWord.text)")
                return
            }
        }
        append(newWord)
    }
    
    mutating func add(newWords: [Word]) {
        for newWord in newWords {
            add(newWord: newWord)
        }
    }
    
    mutating func updateWord(of id: String, newText: String? = nil, newMeaning: String? = nil, newNote: String? = nil) {
        for i in 0..<count {
            if self[i].id == id {
                self[i].update(newText: newText, newMeaning: newMeaning, newNote: newNote)
                return
            }
        }
    }
    
    mutating func removeWord(of id: String) {
        for i in 0..<count {
            if self[i].id == id {
                self.remove(at: i)
                return
            }
        }
    }
    
    func subset(containing keyWord: String) -> [Word] {
        if keyWord.isEmpty {
            return self
        }
        
        var subset: [Word] = []
        for word in self {
            if word.query.contains(keyWord) {
                subset.append(word)
            }
        }
        return subset
    }
    
    func contains(_ word: Word) -> Bool {
        for existingWord in self {
            if existingWord.id == word.id {
                return true
            }
        }
        return false
    }
}

extension Word {
    
    static let dummyWord: Word = Word(
        text: "Dummy word",
        meaning: "Dummy word"
    )
    
}

extension Word {
    
    var groupId: String {
        var groupId = cDate.repr()
        if let note = note, !note.isEmpty {
            groupId += " · \(note)"
        }
        return groupId
    }
    
}

struct GroupedWords {
    
    // For storing words grouped by group identifiers.
    
    var words: [Word]
    
    var cDate: Date {
        words[0].cDate
    }
    var groupId: String {
        words[0].groupId
    }
    
    init(words: [Word]) {
        self.words = words
    }
}

extension Array where Iterator.Element == Word {
    
    // TODO: - Improve here. It's time consuming to compute.
    var groups: [GroupedWords] {
        var groupedWordsMapping: [String: GroupedWords] = [:]
        for word in self {
            let groupId = word.groupId
            
            groupedWordsMapping.setDefault(value: GroupedWords(words: []), for: groupId)
            groupedWordsMapping[groupId]?.words.append(word)
        }
        
        // Sort groups.
        var groupedWords = Array<GroupedWords>(groupedWordsMapping.values)
        groupedWords.sort { (group1, group2) -> Bool in
            group1.cDate != group2.cDate
                ? group1.cDate > group2.cDate  // First, sort by date.
                : group1.groupId < group2.groupId  // Then, sort by groupId.
        }
        
        // Sort words in each group.
        for i in 0..<groupedWords.count {
            groupedWords[i].words.sort { (word1, word2) -> Bool in
                word1.mDate > word2.mDate
            }
        }
        
        return groupedWords
    }
}
