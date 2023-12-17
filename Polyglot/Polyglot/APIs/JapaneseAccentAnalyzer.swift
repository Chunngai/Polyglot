//
//  JapaneseAccentAnalyzer.swift
//  Polyglot
//
//  Created by Ho on 10/29/23.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct JapaneseAccentAnalyzer {
    
    static func isOldAccents(_ word: Word) -> Bool {
        guard let tokens = word.tokens else {
            return false
        }
        for token in tokens {
            if token.text == "" {  // Due to a bug the text of the last token may be an empty string.
                continue
            }
            if token.text.count == 1 {
                if token.accentLoc == nil || token.accentLoc == 0 {
                    continue
                }
            }
            if token.text.count == 2 {  // ?ya/?yu/?yo.
                if token.accentLoc == nil || token.accentLoc == 0 || token.accentLoc == 1 {
                    continue
                }
            }
            return true
        }
        return false
    }
    
    static func makeTokens(for word: Word, completion: @escaping ([Token]) -> Void) {
        
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
}
