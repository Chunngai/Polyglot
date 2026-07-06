//
//  StringExt.swift
//  Polyglot
//
//  Created by Sola on 2022/12/25.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation
import UIKit
import NaturalLanguage

extension String {
    
    func strip() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    func split(with separator: String) -> [String] {
        // https://stackoverflow.com/questions/49472570/in-swift-can-you-split-a-string-by-another-string-not-just-a-character
        return self.components(separatedBy: separator)  // Split by a string.
    }
}

extension String {
    
    func replaceMultipleBlankLinesWithSingleLine() -> String {
        // https://stackoverflow.com/questions/47796228/remove-whitespace-and-multiple-line-from-string
        // https://chatgpt.com/share/1ce05efa-aa79-40c4-a229-7daf748db62c
        self.replacingOccurrences(of: "\\s*(\\n\\s*){2,}", with: "\n\n", options: .regularExpression)
    }
    
    func replaceMultipleSpacesWithSingleOne() -> String {
        // https://stackoverflow.com/questions/36363415/replace-sequence-of-spaces-in-string-with-a-single-character-in-swift
        return self.replacingOccurrences(of: " +", with: " ", options: .regularExpression)
    }
    
    func normalizeQuotes() -> String {
        return self
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "“", with: "\"")
            .replacingOccurrences(of: "”", with: "\"")
    }
    
    func normalized(shouldStrip: Bool = true, caseInsensitive: Bool = false, diacriticInsensitive: Bool = false) -> String {
        var normalizedString = self
        
        if shouldStrip {
            normalizedString = normalizedString.strip()
        }
        
        normalizedString = normalizedString
            .replaceMultipleSpacesWithSingleOne()
            .normalizeQuotes()
        
        // https://stackoverflow.com/questions/36727310/is-there-a-way-to-convert-special-characters-to-normal-characters-in-swift
        if caseInsensitive {
            normalizedString = normalizedString.folding(options: [.caseInsensitive], locale: nil)
        }
        if diacriticInsensitive {
            normalizedString = normalizedString.folding(options: [.diacriticInsensitive], locale: nil)
        }
        
        return normalizedString
    }
}

extension String {
    
    func nsrange(from range : Range<String.Index>) -> NSRange {
        // https://www.jianshu.com/p/beb4e463e6da
        return NSRange(range, in: self)
    }
    
    var tokenRanges: [NSRange] {
        
        var tokenRanges: [NSRange] = []
        
        // For Japanese and some languages, tokenization is crucial.
        var tokens = self.tokenized(with: LangCode.currentLanguage.wordTokenizer)
        guard !tokens.isEmpty else {
            return []
        }
        
        var tokenBuffer: String = ""
        var location: Int = 0
        var length: Int = 0
        for (i, character) in self.enumerated() {
            
            if tokenBuffer == tokens[0] {
                tokenRanges.append(NSRange(
                    location: location,
                    length: length
                ))
                tokens.remove(at: 0)
                tokenBuffer = ""
                
                //                print(
                //                    location,
                //                    length,
                //                    (text as NSString).substring(with: NSRange(
                //                        location: location,
                //                        length: length
                //                    ))
                //                )
            }
            
            if tokens.isEmpty {
                break
            }
            
            if character == tokens[0].first! && tokenBuffer.isEmpty {
                location = i
                length = 1
                tokenBuffer = String(character)
                continue
            }
            
            if tokens[0].starts(with: tokenBuffer + String(character)) {
                tokenBuffer += String(character)
                length += 1
                continue
            }
            
            tokenBuffer = ""
        }
        
        if !tokenBuffer.isEmpty {
            tokenRanges.append(NSRange(
                location: location,
                length: length
            ))
        }
        
        return tokenRanges
    }
    
}

extension String {
    
    func textSize(withFont font: UIFont) -> CGSize {
        return self.size(withAttributes: [NSAttributedString.Key.font : font])
    }
}

extension String {
    
    func tokenized(with tokenizer: NLTokenizer) -> [String] {
        
//        let stringToTokenize = self
//            // If the string starts with 「,
//            // the tokenization does not work properly (returns an empty list).
//            // Therefore, preprocess the string before the tokenization.
//            .replacingOccurrences(of: "「", with: "")
//            .replacingOccurrences(of: "」", with: "")
        let stringToTokenize = self
        tokenizer.string = stringToTokenize
        
        var components: [String] = []
        tokenizer.enumerateTokens(in: stringToTokenize.startIndex..<stringToTokenize.endIndex) { (range, attributes) -> Bool in
            components.append(String(stringToTokenize[range]))
            return true
        }

        return components
    }
    
    var tokensWithPunctMarks: [String] {
        
        // Example:
        let _ = """
        Ру́сский язы́к (МФА: [ˈruskʲɪi̯ jɪˈzɨk]о файле)[~ 3][⇨] — язык восточнославянской группы славянской ветви индоевропейской языковой семьи, национальный язык русского народа. Является одним из наиболее распространённых языков мира — восьмым среди всех языков мира по общей численности говорящих[5] и седьмым по численности владеющих им как родным (2022)[2]. Русский является также самым распространённым славянским языком[8] и самым распространённым языком в Европе — географически и по числу носителей языка как родного[6].
        """
        
        guard self.count != 0 else {
            return []
        }
        
        let tokens = self.tokenized(with: LangCode.currentLanguage.wordTokenizer)
        guard tokens.count != 0 else {
            return [self]
        }
        
        var tokensWithPunctMarks: [String] = []
        
        var substringStartingIndex: Int = 0
        var currentTokenIndex: Int = 0
        while true {
            
            if substringStartingIndex >= self.count {
                break
            }
            if currentTokenIndex >= tokens.count {
                // At this point, there may be a remaining substring ("]." in the example),
                // which is skipped by the built-in word tokenizer.
                if substringStartingIndex < self.count {
                    let remainingSubstring = String(self.substring(from: substringStartingIndex))
                    tokensWithPunctMarks.append(remainingSubstring)
                }
                
                break
            }
            
            let currentToken: String = tokens[currentTokenIndex]
            // https://stackoverflow.com/questions/24029163/finding-index-of-character-in-swift-string
            // Note that: `let indexOfCurrentTokenInString = (self as! NSString).range(of: currentToken).location`
            // does not work properly with characters like у́.
            guard let rangeOfCurrentTokenInString = self.range(
                of: currentToken,
                // Skip the previously processed substring.
                // Without providing the `range` arg, errors may be raised.
                // E.g., when reaching "славянской" in the example,
                // an error will be raised without this arg, as the string "славянской"
                // also appears in the previously processed substring "восточнославянской".
                range: self.index(
                    self.startIndex,
                    offsetBy: substringStartingIndex
                )..<self.endIndex
            ) else {
                return []
            }
            let indexOfCurrentTokenInString = self.distance(
                from: self.startIndex,
                to: rangeOfCurrentTokenInString.lowerBound
            )
            
            if indexOfCurrentTokenInString == substringStartingIndex {  // Found a token (e.g., "Ру́сский" in the example).
                tokensWithPunctMarks.append(currentToken)
                
                substringStartingIndex += currentToken.count  // Move on.
                currentTokenIndex += 1  // Consider the next token.
            } else {
                // Find the substring skipped by the built-in word tokenizer.
                // E.g., " (" in the example.
                // https://stackoverflow.com/questions/39677330/how-does-string-substring-work-in-swift
                let skippedStringInWordTokenization = String(self.substring(from: substringStartingIndex, to: indexOfCurrentTokenInString))
                tokensWithPunctMarks.append(skippedStringInWordTokenization)
                
                substringStartingIndex += skippedStringInWordTokenization.count  // Move on.
            }
            
            // Skip white spaces.
            while true {
                
                if substringStartingIndex >= self.count {
                    break
                }
                
                let nextChar = self.character(at: substringStartingIndex)
                if nextChar == " " {
                    substringStartingIndex += 1  // Move on.
                } else {
                    break
                }
            }
            
        }
        
        return tokensWithPunctMarks
        
    }
    
}

extension String {
    
    func character(at index: Int) -> Character {
        return self[self.index(
            self.startIndex,
            offsetBy: index
        )]
    }
    
    func substring(from startIndex: Int? = nil, to endIndex: Int? = nil) -> Substring {
        let startIndex = startIndex ?? 0
        let endIndex = endIndex ?? self.count
        return self[self.index(
            self.startIndex, 
            offsetBy: startIndex
        )..<self.index(
            self.startIndex,
            offsetBy: endIndex
        )]
    }
    
}

extension String {
    
    static let emojiNumber2Int: [Character: Int] = [
        "0️⃣": 0,
        "1️⃣": 1,
        "2️⃣": 2,
        "3️⃣": 3,
        "4️⃣": 4,
        "5️⃣": 5,
        "6️⃣": 6,
        "7️⃣": 7,
        "8️⃣": 8,
        "9️⃣": 9,
        "🔢": 1234,
    ]
    static let unicodeNumberForms2Float: [Character: Float] = [
        "⅐": 1/7,
        "⅑": 1/9,
        "⅒": 1/10,
        "⅓": 1/3,
        "⅔": 2/3,
        "⅕": 1/5,
        "⅖": 2/5,
        "⅗": 3/5,
        "⅘": 4/5,
        "⅙": 1/6,
        "⅚": 5/6,
        "⅛": 1/8,
        "⅜": 3/8,
        "⅝": 5/8,
        "⅞": 7/8,
        "Ↄ": 100,
        "ↄ": 100,
        "↊": 10,
        "↋": 11,
    ]
    
    var isNumericText: Bool {
        
        return Int(self) != nil || Float(self) != nil || Double(self) != nil || self.allSatisfy({ char in  // https://sarunw.com/posts/how-to-check-if-string-is-number-in-swift/
            char.isNumber || char == "." || char == "," || String.emojiNumber2Int.keys.contains(char) || String.unicodeNumberForms2Float.keys.contains(char)
        }) || LangCode.currentLanguage.numberFormatter.number(from: self.lowercased())?.stringValue != nil
        
    }

    var numericRepresentation: String? {
        var s = self.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: ", ", with: "")
        if let intRepr = Int(s) {
            return String(intRepr)
        } else if let floatRepr = Float(s) {
            return String(floatRepr)
        } else if let doubleRepr = Double(s) {
            return String(doubleRepr)
        }
        
        
        let wholeNumberString = s.compactMap({ c in
            if let v = c.wholeNumberValue {
                return String(v)
            } else if let v = String.emojiNumber2Int[c] {
                return String(v)
            } else if let v = String.unicodeNumberForms2Float[c] {
                return String(v)
            } else {
                return ""
            }
        }).joined(separator: "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if wholeNumberString.count != 0 {
            return wholeNumberString
        }
        
        if let formattedS = LangCode.currentLanguage.numberFormatter.number(from: s.lowercased())?.stringValue {
            return formattedS
        }
        
        return nil
    }
    
}

import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG
extension String {
    
    // https://stackoverflow.com/questions/32163848/how-can-i-convert-a-string-to-an-md5-hash-in-ios-using-swift
    
    private var _md5: Data {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = self.data(using:.utf8)!
        var digestData = Data(count: length)
        
        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData
    }
    
    var md5: String {
        self._md5.map { String(format: "%02hhx", $0) }.joined()
    }

}

extension String {

    // MARK: - Syllabification for phrase construction practice

    func syllabified(for lang: LangCode) -> [String] {
        syllabifyPhrase(self, lang: lang)
    }

}
