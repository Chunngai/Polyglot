//
//  GoogleTranslator.swift
//  Polyglot
//
//  Created by Sola on 2023/1/26.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct GoogleTranslator: TranslationProtocol {
    
    var srcLang: LangCode
    var trgLang: LangCode
    
    init(srcLang: LangCode, trgLang: LangCode) {
        self.srcLang = srcLang
        self.trgLang = trgLang
    }
    
    private func constructUrl(from query: String) -> URL? {
        
        // https://www.swiftbysundell.com/articles/constructing-urls-in-swift/
        // https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/使用-baseurl-urlcomponents-urlqueryitem-產生-url-1e4539a33a89
        
        var queryItems = GoogleTranslator.queryItems
        queryItems["sl"] = srcLang.rawValue
        queryItems["tl"] = trgLang.rawValue
        queryItems["q"] = query
        
        var components = URLComponents()
        components.scheme = GoogleTranslator.scheme
        components.host = GoogleTranslator.host
        components.path = GoogleTranslator.path
        components.queryItems = queryItems.map {
            URLQueryItem(name: $0.key, value: $0.value)
        }

        return components.url
    }

    func translate(query: String, completion: @escaping ([String]) -> Void) {
        
        guard !query.strip().isEmpty else {
            completion([query])
            return
        }
        
        guard let url = constructUrl(from: query) else {
            completion([])
            return
        }
        
        var request: URLRequest = URLRequest(
            url: url,
            timeoutInterval: Constants.shortRequestTimeLimit
        )
        request.setValue(
            Constants.userAgent,
            forHTTPHeaderField: "User-Agent"
        )
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard
                let data = data,
                error == nil
            else {
                print("\(Self.self): \(error?.localizedDescription ?? "Unknown error.")")
                
                completion([])
                return
            }
            
            do {
                guard let jsonArray = try JSONSerialization.jsonObject(
                    with: data,
                    options: []
                ) as? [Any] else {
                    completion([])
                    return
                }
                
                guard let resArray = jsonArray[5] as? [Any] else {
                    completion([])
                    return
                }
                
                if resArray.count == 1 {
                    // Return multiple translation candidates.
                    guard let res = resArray[0] as? [Any] else {
                        completion([])
                        return
                    }
                    guard let translationArrays = res[2] as? [Any] else {
                        completion([])
                        return
                    }
                    
                    let translations = translationArrays.compactMap { (arr) -> String? in
                        (arr as? [Any])?[0] as? String
                    }
                    completion(translations)
                    return
                } else {
                    // Return one translation.
                    var translation: String = ""
                    for res in resArray {
                        guard let res = res as? [Any] else {
                            completion([])
                            return
                        }
                        if let translationArrays = res[2] as? [Any] {
                            let sentenceTranslation = (translationArrays[0] as? [Any])?[0] as? String ?? ""
                            translation += sentenceTranslation
                        } else if let spaces = res[0] as? String, spaces.strip().isEmpty {
                            translation += spaces
                        } else {
                            continue
                        }
                    }
                    completion([translation])
                    return
                }
            } catch {
                
                print("\(Self.self): \(error.localizedDescription)")
                
                completion([])
                return
                
            }
            
        }
        task.resume()
    }
}

extension GoogleTranslator {
    
    static private let scheme = "https"
    static private let host = "translate.googleapis.com"
    static private let path = "/translate_a/single"
    static private let queryItems: [String: String] = [
        // https://stackoverflow.com/questions/26714426/what-is-the-meaning-of-google-translate-query-params
        "client": "gtx",
        "dt": "at",
        "ie": "UTF-8",
        "oe": "UTF-8",
        
        "sl": "",
        "tl": "",
        "q": ""
    ]
    
}
