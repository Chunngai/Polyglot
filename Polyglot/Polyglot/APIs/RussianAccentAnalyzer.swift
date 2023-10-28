//
//  RussianAccentAnalyzer.swift
//  Polyglot
//
//  Created by Ho on 10/29/23.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct RussianAccentAnalyzer {
    
    static func makeTokens(for word: Word, completion: @escaping ([Token]) -> Void) {
        
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
