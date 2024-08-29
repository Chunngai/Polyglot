//
//  WordExt.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation

extension Token {
    
    // https://stackoverflow.com/questions/31272561/working-with-unicode-code-points-in-swift
    static let accentSymbol: Character = "\u{031A}"
    
    var accentedPronunciation: String {
        
        guard let accentLoc = accentLoc else {
            return pronunciation
        }
        
        guard accentLoc >= 0 && accentLoc < pronunciation.count else {  // For heibangata of ja, the accentLoc is -1.
            return pronunciation
        }
        
        var pronunciation = self.pronunciation
        
        // https://stackoverflow.com/questions/27103454/how-to-add-a-character-at-a-particular-index-in-string-in-swift
        pronunciation.insert(
            Token.accentSymbol,
            at: pronunciation.index(
                pronunciation.startIndex,
                offsetBy: accentLoc + 1
            )
        )
        
        return pronunciation
        
    }
}

extension Array where Iterator.Element == Token {
        
    var accentLocs: [Int?] {
        self.map { $0.accentLoc }
    }
    
    var pronunciations: [String] {
        self.map { $0.pronunciation }
    }
    
    var accentedPronunciations: [String] {
        self.map { $0.accentedPronunciation }
    }
}

extension Word {
        
    var accentedText: String {
        if let tokens = self.tokens {
            
            if LangCode.currentLanguage == .ja {
                
                let accentedPronunciation: String = tokens.accentedPronunciations.joined(separator: Strings.wordSeparator)
                if accentedPronunciation.normalized(
                    caseInsensitive: true,
                    diacriticInsensitive: false
                ).replacingOccurrences(
                    of: String(Token.accentSymbol),
                    with: ""
                ) == self.text.normalized(
                    caseInsensitive: true,
                    diacriticInsensitive: false
                ) {  // E.g., japanese words with katakana only.
                    return accentedPronunciation
                } else {
                    return "\(self.text) (\(accentedPronunciation))"
                }
                
            } else if LangCode.currentLanguage == .ru {
                
                return addAccentMarks(
                    for: self.text,
                    with: self.tokens ?? []
                )
                
            } else {
                return self.text
            }
            
        } else {
            return self.text
        }
    }
}

extension Word {
    
    var query: String {
        return text + meaning
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
    
    mutating func add(newWord: Word) -> Int? {
        for (i, existingWord) in self.enumerated() {
            // Duplication check with the text var.
            if newWord.text == existingWord.text {
                print("Skipped: \(newWord.text)")
                // Return the word index.
                return i
            }
        }
        append(newWord)
        return nil
    }
    
    mutating func add(newWords: [Word]) {
        for newWord in newWords {
            add(newWord: newWord)
        }
    }
    
    mutating func updateWord(of id: String, newText: String? = nil, newTokens: [Token]? = nil, newMeaning: String? = nil, newNote: String? = nil) -> Word? {
        for i in 0..<count {
            if self[i].id == id {
                self[i].update(newText: newText, newTokens: newTokens, newMeaning: newMeaning, newNote: newNote)
                return self[i]
            }
        }
        return nil
    }
    
    mutating func removeWord(of id: String) {
        for i in 0..<count {
            if self[i].id == id {
                self.remove(at: i)
                return
            }
        }
    }
    
    func subset(containing keyWord: String, shouldIgnoreCaseAndAccent: Bool = true) -> [Word] {
        if keyWord.isEmpty {
            return self
        }
        
        let keyWord = keyWord.normalized(
            shouldStrip: false,
            caseInsensitive: shouldIgnoreCaseAndAccent,
            diacriticInsensitive: shouldIgnoreCaseAndAccent
        )
        
        var subset: [Word] = []
        for word in self {
            let query = word.query.normalized(
                caseInsensitive: shouldIgnoreCaseAndAccent,
                diacriticInsensitive: shouldIgnoreCaseAndAccent
            )
            if query.contains(keyWord) {
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

//extension Word {
//    
//    static let dummyWord: Word = Word(
//        text: "Dummy word",
//        meaning: "Dummy word"
//    )
//    
//}

extension Word {
    
    static let defaultDateFormatter = Date.defaultDateFormatter  // For speeding up word grouping.
    
    var groupId: String {
        var groupId = cDate.repr(from: Word.defaultDateFormatter)
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
    func grouped(into size: Int? = nil) -> [GroupedWords] {
        var groupedWordsMapping: [String: GroupedWords] = [:]
        for word in self {
            let groupId = word.groupId
            
            groupedWordsMapping.setDefault(value: GroupedWords(words: []), for: groupId)
            groupedWordsMapping[groupId]?.words.append(word)
        }
        
        var groupedWords = Array<GroupedWords>(groupedWordsMapping.values)
        if let size = size {
            var tmpArray: [GroupedWords] = []
            for group in groupedWords {
                if group.words.count <= size {
                    tmpArray.append(group)
                } else {
                    let chunkedWords = group.words.chunked(into: size)
                    for chunk in chunkedWords {
                        tmpArray.append(GroupedWords(words: chunk))
                    }
                }
            }
            groupedWords = tmpArray
        }
        
        // Sort groups.
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
