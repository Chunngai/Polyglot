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
        if let note = note {
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
    
    mutating func updateWord(of id: Int, newText: String? = nil, newMeaning: String? = nil) {
        for i in 0..<count {
            if self[i].id == id {
                self[i].update(newText: newText, newMeaning: newMeaning)
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
}
