//
//  JapanesePAAnalyzer.swift
//  Polyglot
//
//  Created by Sola on 2023/2/4.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation
import SwiftSoup

struct JapanesePAAnalyzer {
    
    private func constructUrl(from query: String) -> URL? {
        
        var queryItems = JapanesePAAnalyzer.queryItems
        queryItems["q"] = query

        var components = URLComponents()
        components.scheme = JapanesePAAnalyzer.scheme
        components.host = JapanesePAAnalyzer.host
        components.path = JapanesePAAnalyzer.path
        components.queryItems = queryItems.map {
            URLQueryItem(name: $0.key, value: $0.value)
        }

        return components.url
        
    }
    
    private func getPAInfo(from html: String) -> [Token] {
        
        var res: [Token] = []
        
        do {
            let doc: Document = try SwiftSoup.parse(html)
            
            // Obtain query tokens.
            var queryTokens: [(token: String, divId: String?)] = []  // [{ token : divId }]
            let divOfFloatingSentence = try doc.getElementsByClass("floating-sentence")[0]
            for div in divOfFloatingSentence.children() {
                let a = try div.getElementsByTag("a")
                if a.count == 0 {
                    queryTokens.append((token: try div.text(), divId: nil))
                }
                
                // Remove furiganas.
                try a.select("rt").remove()

                let queryToken: String = try a.text()
                if queryToken.isEmpty {
                    continue
                }
                
                let divId: String = try a.attr("href").replacingOccurrences(of: "#", with: "")
                
                queryTokens.append((token: queryToken, divId: divId))
            }
            
            for (token, divId) in queryTokens {
                guard let divId = divId else {
                    res.append(Token(
                        text: token,
                        baseForm: token,
                        pronunciation: token,
                        accentLoc: nil
                    ))
                    continue
                }
                
                let divOfResult = try doc.getElementById(divId)!
                
                // Make the text.
                var text: String = ""
                let divOfPrimarySpelling = try divOfResult.getElementsByClass("primary-spelling")[0]
                let rubyOfV = try divOfPrimarySpelling.getElementsByClass("v")[0]
                for elem in rubyOfV.textNodes() {
                    text += elem.text()
                }

                let divsOfSubsectionPitchAccent = try divOfResult.getElementsByClass("subsection-pitch-accent")
                if divsOfSubsectionPitchAccent.count == 0 {  // No pa.
                    res.append(Token(
                        text: token,
                        baseForm: text,
                        pronunciation: text,
                        accentLoc: nil
                    ))
                    continue
                }
                
                let subsection = try divsOfSubsectionPitchAccent[0].getElementsByClass("subsection")[0]
                let pitchDivs = subsection.child(0).child(0).child(1).children()
                
                // Make the kana.
                let kana = try pitchDivs.text()
                    .replacingOccurrences(of: " ", with: "")
                
                // Make the pa.
                var locCounter: Int = -1
                var pitchLoc: Int = -1
                var prevPitch: Pitch? = nil
                for (i, pitchDiv) in pitchDivs.enumerated() {
                    
                    let pitch = try pitchDiv.attr("style").contains(Pitch.high.rawValue) ?
                        Pitch.high :
                        Pitch.low
                    // High -> low.
                    if prevPitch == Pitch.high && pitch == Pitch.low {
                        pitchLoc = locCounter
                    }
                    prevPitch = pitch
                    
                    // Count the loc.
                    let partialKanas = try pitchDiv.text()
                    locCounter += partialKanas.count
                    print(partialKanas, partialKanas.count, locCounter)
                    
                    // The accent is on the last char.
                    let isRightContained = try pitchDiv.attr("style").contains("right")
                    if i + 1 == pitchDivs.count && isRightContained {
                        pitchLoc = kana.count - 1
                    }
                }
                
                res.append(Token(
                    text: token,
                    baseForm: text,
                    pronunciation: kana,
                    accentLoc: pitchLoc
                ))
            }
                        
            return res
            
        } catch Exception.Error(let type, let message) {
            print(type)
            print(message)
        } catch {
            print("error")
        }
                
        return []
    }
    
    func analyze(query: String, completion: @escaping ([Token]) -> Void) {
        
        let query = query + "○"  // Ensure that there is a floating sentence at the bottom.
        
        guard let url = constructUrl(from: query) else {
            return
        }
        
        var request: URLRequest = URLRequest(url: url, timeoutInterval: Constants.requestTimeLimit)
        // https://stackoverflow.com/questions/36889970/change-user-agent
        request.setValue(Constants.userAgent, forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "Unknown error.")
                return
            }
            
            let html = String(data: data, encoding: .utf8)
            if let html = html {
                var paInfo = self.getPAInfo(from: html)
                paInfo.removeLast()  // Remove the "○".
                
                completion(paInfo)
            } else {
                completion([])
            }
        }
        task.resume()
    }
}

extension JapanesePAAnalyzer {
    
    enum Pitch: String {
        case low
        case high
    }
    
}

extension JapanesePAAnalyzer {
    
    static private let scheme = "https"
    static private let host = "jpdb.io"
    static private let path = "/search"
    static private let queryItems: [String: String] = [
        "q": ""
    ]
    
}
