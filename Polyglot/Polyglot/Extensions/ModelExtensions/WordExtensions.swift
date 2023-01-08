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
        return text + meaning
    }
    
    var groupId: String {
        var groupId = cDate.repr()
        if let note = note, !note.isEmpty {
            groupId += " · \(note)"
        }
        return groupId
    }
}

extension Array where Iterator.Element == Word {
    
    // TODO: - Simplify the for loops?
    
    func getWord(from id: Int) -> Word? {
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
    
    mutating func updateWord(of id: Int, newText: String? = nil, newMeaning: String? = nil, newNote: String? = nil) {
        for i in 0..<count {
            if self[i].id == id {
                self[i].update(newText: newText, newMeaning: newMeaning, newNote: newNote)
                return
            }
        }
    }
    
    mutating func removeWord(of id: Int) {
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

struct GroupedWords {
    
    // For storing words grouped by group identifiers.
    var groupId: String
    var words: [Word]
    
    init(groupId: String, words: [Word]) {
        self.groupId = groupId
        self.words = words
    }
    
    init(groupId: String) {
        self.init(groupId: groupId, words: [])
    }
}

extension Array where Iterator.Element == Word {
    
    // TODO: - Improve here. It's time consuming to compute.
    var groups: [GroupedWords] {
        var groupedWordsMapping: [String: GroupedWords] = [:]
        for word in self {
            let groupId = word.groupId
            
            groupedWordsMapping.setDefault(value: GroupedWords(groupId: groupId), for: groupId)
            groupedWordsMapping[groupId]?.words.append(word)
        }
        
        var groupedWords = Array<GroupedWords>(groupedWordsMapping.values)
        groupedWords.sort { (item1, item2) -> Bool in
            item1.words[0].cDate != item2.words[0].cDate
                ? item1.words[0].cDate > item2.words[0].cDate  // First, sort by date.
                : item1.groupId < item2.groupId  // Then, sort by groupId.
        }
        return groupedWords
    }
}
