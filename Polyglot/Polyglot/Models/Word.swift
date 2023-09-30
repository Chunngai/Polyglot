//
//  Word.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation

struct Token: Codable {
    
    var text: String
    var baseForm: String
    var pronunciation: String
    var accentLoc: Int?
    
    init(text: String, baseForm: String, pronunciation: String, accentLoc: Int?) {
        
        self.text = text.lowercased().strip()
        self.baseForm = baseForm.lowercased().strip()
        self.pronunciation = pronunciation.lowercased().strip()
        self.accentLoc = accentLoc
        
    }
    
}

struct Word {
    
    var id: String
    var cDate: Date  // Creation date.
    var mDate: Date  // Modification date.
    
    var text: String
    var tokens: [Token]?
    
    var meaning: String
    
    var note: String?
    
    init(cDate: Date = Date(), text: String, tokens: [Token]? = nil, meaning: String, note: String? = nil) {
        
        self.id = UUID().uuidString
        self.cDate = cDate
        self.mDate = cDate
        
        self.text = text.normalized(caseInsensitive: true, diacriticInsensitive: false)
        self.tokens = tokens
        
        self.meaning = meaning.lowercased().strip()
        
        self.note = note?.strip()
    }
    
    mutating func update(newText: String? = nil, newTokens: [Token]? = nil, newMeaning: String? = nil, newNote: String? = nil) {
        
        if let newText = newText {
            self.text = newText.normalized(caseInsensitive: true, diacriticInsensitive: false)
        }
        
        if let newTokens = newTokens {
            self.tokens = newTokens
        }
        
        if let newMeaning = newMeaning {
            self.meaning = newMeaning.lowercased().strip()
        }
        
        if let newNote = newNote {
            self.note = newNote.strip()
        }
        
        self.mDate = Date()
    }
}

extension Word: Codable {
    
    enum CodingKeys: String, CodingKey {
        
        case id
        case cDate
        case mDate
        
        case text
        case tokens
        
        case meaning
        
        case note
        
        // Old vars.
        
        case creationDate  // cDate.
        case modificationDate  // mDate.
        
        case word  // text.
        
        case groupNote  // note
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(cDate, forKey: .cDate)
        try container.encode(mDate, forKey: .mDate)
        
        try container.encode(text, forKey: .text)
        try container.encode(tokens, forKey: .tokens)
        
        try container.encode(meaning, forKey: .meaning)
        
        try container.encode(note, forKey: .note)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            id = try values.decode(String.self, forKey: .id)
        } catch {
            id = UUID().uuidString
        }
        
        do {
            cDate = try values.decode(Date.self, forKey: .cDate)
        } catch {
            cDate = try values.decode(Date.self, forKey: .creationDate)
        }
        
        do {
            mDate = try values.decode(Date.self, forKey: .mDate)
        } catch {
            mDate = try values.decode(Date.self, forKey: .modificationDate)
        }
        
        do {
            text = try values.decode(String.self, forKey: .text)
        } catch {
            text = try values.decode(String.self, forKey: .word)
        }
        
        do {
            tokens = try values.decode([Token].self, forKey: .tokens)
        } catch {
            tokens = nil
        }
        
        meaning = try values.decode(String.self, forKey: .meaning)
        
        do {
            note = try values.decode(String?.self, forKey: .note)
        } catch {
            note = try values.decode(String?.self, forKey: .groupNote)
        }
    }
}

extension Word {
    
    // MARK: - IO
    
    static func fileName(for lang: String) -> String {
        return "words.\(lang).json"
    }
    
    static func load(for lang: String) -> [Word] {
        do {
            let words = try readSequenceDataFromJson(fileName: Word.fileName(for: lang), type: Word.self) as! [Word]
            return words
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static func save(_ words: inout [Word], for lang: String) {
        do {
            try writeSequenceDataFromJson(fileName: Word.fileName(for: lang), data: words)
        } catch {
            print(error)
            exit(1)
        }
    }
}

extension Word {
    
    static func metaDataFileName(for lang: String) -> String {
        return "words.meta.\(lang).json"
    }
    
    static func loadMetaData(for lang: String) -> [String: String] {
        do {
            let metaData = try readMappingDataFromJson(
                fileName: Word.metaDataFileName(for: lang),
                keyType: String.self,
                valType: String.self
            ) as! [String:String]
            return metaData
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static func saveMetaData(_ metaData: inout [String:String], for lang: String) {
        do {
            try writeMappingDataFromJson(
                fileName: Word.metaDataFileName(for: lang),
                data: metaData
            )
        } catch {
            print(error)
            exit(1)
        }
    }
}

extension Word {
    
    static var samples: [Word] = [
        Word(cDate: Date(), text: "中間試験", meaning: "期中考"),
        Word(cDate: Date(), text: "秘密兵器", meaning: "秘密兵器"),
        Word(cDate: Date(), text: "出題範囲", meaning: "出题范围"),
        Word(cDate: Date(), text: "図工", meaning: "手工"),
        Word(cDate: Date(), text: "戦争から立ち直る", meaning: "从战争中重振"),
        Word(cDate: Date(), text: "作戦する", meaning: "行动"),
        Word(cDate: Date(), text: "水道水", meaning: "自来水"),
        Word(cDate: Date(), text: "辺鄙な", meaning: "偏僻的"),
        Word(cDate: Date(timeInterval: 300000, since: Date()), text: "作戦する", meaning: "行动"),
        Word(cDate: Date(timeInterval: 300000, since: Date()), text: "水道水", meaning: "自来水"),
        Word(cDate: Date(timeInterval: 300000, since: Date()), text: "辺鄙な", meaning: "偏僻的")
    ]
    
}


extension Word {
    
    // TODO: - Temporary solution.
    var isOldJaAccents: Bool {
        guard let tokens = self.tokens else {
            return false
        }
        for token in tokens {
            if token.text.count != 1 {
                return true
            }
        }
        return false
    }
    
    static func makeJaTokensFor(jaWord word: Word, completion: @escaping ([Token]) -> Void) {
        
        let json: [String: Any] = [
            "word": word.text
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json) else {
            return
        }
        
        let url = URL(string: "http://4o51096o21.zicp.vip/ja/word_accent/")!
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("\(String(describing: jsonData.count))", forHTTPHeaderField: "Content-Length")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data, error == nil {
                guard let responseJson = try? JSONSerialization.jsonObject(
                    with: data,
                    options: []
                    ) as? [String: Any] else {
                        return
                }
                
                guard let code = responseJson["code"] as? Int, code == 200 else {
                    return
                }
                guard let chars = responseJson["chars"] as? [String] else {
                    return
                }
                guard let accentIndices = responseJson["accent_indices"] as? [Int] else {
                    return
                }
                
                print(code)
                print(chars)
                print(accentIndices)
                var tokens: [Token] = []
                for i in 0..<chars.count {
                    let char = chars[i]
                    var accentLoc: Int? = nil
                    if accentIndices.contains(i) {
                        accentLoc = 0
                    }
                    
                    tokens.append(Token(
                        text: char,
                        baseForm: char,
                        pronunciation: char,
                        accentLoc: accentLoc
                    ))
                }
                
                completion(tokens)
            }
            
            if error != nil {
                if let errDescription = error?.localizedDescription {
                    print(errDescription)
                } else {
                    print("error")
                }
            }
        }
        task.resume()
    }
    
    static func makeRuTokensFor(ruWord word: Word, completion: @escaping ([Token]) -> Void) {
        
        func removeAccentMark(string: String) -> String {
            return string
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
        }
        
        let json: [String: Any] = [
            "word": word.text
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json) else {
            return
        }
        
        let url = URL(string: "http://4o51096o21.zicp.vip/ru/word_accent/")!
        var request = URLRequest(url: url, timeoutInterval: TimeInterval(3 * word.text.split(with: " ").count))  // TODO: - Update the timeout interval.
        request.httpMethod = "POST"
        request.setValue("\(String(describing: jsonData.count))", forHTTPHeaderField: "Content-Length")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data, error == nil {
                guard let responseJson = try? JSONSerialization.jsonObject(
                    with: data,
                    options: []
                    ) as? [String: Any] else {
                        return
                }
                
                guard let code = responseJson["code"] as? Int, code == 200 else {
                    return
                }
                guard let originalWords = responseJson["original_words"] as? [String] else {
                    return
                }
                guard let accentedWords = responseJson["accented_words"] as? [String] else {
                    return
                }
                guard let baseForms = responseJson["base_forms"] as? [String] else {
                    return
                }
                
                print(originalWords)
                print(accentedWords)
                var tokens: [Token] = []
                for i in 0..<accentedWords.count {
                    let originalWord = originalWords[i]
                    let accentedWord = accentedWords[i]
                    let baseForm = removeAccentMark(string: baseForms[i])
                    
                    let accentLoc: Int?
                    var pronunciation: String = ""
                    if accentedWord != "[error]" {
                        accentLoc = Array(accentedWord).firstIndex(of: "[")
                        pronunciation = removeAccentMark(string: accentedWord)
                    } else {
                        accentLoc = nil
                        pronunciation = originalWord
                    }
                    
                    tokens.append(Token(
                        text: originalWord,
                        baseForm: baseForm,
                        pronunciation: pronunciation,
                        accentLoc: accentLoc
                    ))
                }
                
                completion(tokens)
            }
            
            if error != nil {
                if let errDescription = error?.localizedDescription {
                    print(errDescription)
                } else {
                    print("error")
                }
            }
        }
        task.resume()
    }
}
