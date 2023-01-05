//
//  WordExt.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation

extension Word {

    var groupIdentifier: String {
        var identifier = creationDate.dateRepresentation()
        if !groupNote.trimmingWhitespacesAndNewlines().isEmpty {
            identifier += " · \(groupNote)"
        }
        return identifier
    }
    
    var query: String {
        return word + meaning
    }

    // TODO: - Make it an extension of [Word]?
    static func getWord(from id: Int) -> Word? {  // TODO: - A more efficient method?
        for word in Word.load() {  // TODO: - don't load everytime.
            if word.id == id {
                return word
            }
        }
        return nil
    }
}

extension Array where Element == Word {
    
    mutating func append(contentsOf newWords: [Word]) {
        
        for newWord in newWords {
            
            // TODO: - Simplify the duplication check.
            var shouldAdd: Bool = true
            for existingWord in self {
                if newWord.id == existingWord.id {
                    shouldAdd = false
                    print("Skipped: \(newWord.word)")
                    break
                }
            }
            
            if shouldAdd {
                append(newWord)
            }
        }
    }
    
    mutating func updateWord(of id: Int, newText: String? = "", newMeaning: String? = "") {
        for i in 0..<count {  // TODO: - Remove the for loop here.
            if self[i].id == id {
                if let newText = newText {
                    self[i].word = newText
                }
                if let newMeaning = newMeaning {
                    self[i].meaning = newMeaning
                }
                self[i].modificationDate = Date()
                
                break
            }
        }
    }
    
    mutating func removeWord(of id: Int) {
        var index: Int = -1
        for i in 0..<count {  // TODO: - Remove the for loop here.
            if self[i].id == id {
                index = i
                break
            }
        }
        if index >= 0 {
            self.remove(at: index)
        }
    }
}
