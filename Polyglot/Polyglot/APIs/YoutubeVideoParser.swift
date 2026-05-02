//
//  YoutubeVideoCaptionRetriever.swift
//  Polyglot
//
//  Created by Ho on 4/29/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import Foundation

struct YoutubeVideoParser {
    
    struct CaptionEvent: Codable {
        let startMs: Double
        let durationMs: Double
        let segs: String
    }
    
    var url: URL!
    var videoID: String!
    
    init?(urlString: String) {
        
        guard let url = YoutubeVideoParser.constructUrl(from: urlString) else {
            return nil
        }
        
        self.url = url
        self.videoID = YoutubeVideoParser.getVideoID(from: urlString)
    }
    
    static func constructUrl(from urlString: String) -> URL? {
        
        // Check if the string is a valid URL
        guard let urlComponents = URLComponents(string: urlString) else {
            return nil
        }
        
        // Check for YouTube host
        guard let host = urlComponents.host else {
            return nil
        }
                
        // Check if host matches any YouTube domains
        guard youtubeHosts.contains(where: host.contains) else {
            return nil
        }
        
        let url = URL.init(string: urlString)
        
        // Check for video ID in different URL formats
        if host.contains("youtu.be") {
            // Shortened URL format: https://youtu.be/VIDEO_ID
            if urlComponents.path.count > 1 { // Path should be "/VIDEO_ID"
                return url
            } else {
                return nil
            }
        } else {
            // Standard URL formats:
            // - https://www.youtube.com/watch?v=VIDEO_ID
            // - https://www.youtube.com/embed/VIDEO_ID
            // - https://www.youtube.com/v/VIDEO_ID
            
            // Check path for embed or v formats
            let path = urlComponents.path.lowercased()
            if path.hasPrefix("/embed/") || path.hasPrefix("/v/") {
                if path.count > 7 { // "/embed/".count == 7
                    return url
                } else {
                    return nil
                }
            }
            
            // Check query parameters for watch?v= format
            if let queryItems = urlComponents.queryItems {
                if queryItems.contains(where: { $0.name == "v" && !($0.value?.isEmpty ?? true) }) {
                    return url
                } else {
                    return nil
                }
            }
        }
        
        return nil
    }
    
    static func getVideoID(from urlString: String) -> String? {
        
        // Pattern for YouTube video ID extraction
        let pattern = videoIDPattern
        
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: .caseInsensitive
        ) else {
            return nil
        }
        
        let wholeRange = NSRange(
            location: 0,
            length: urlString.utf16.count
        )
        guard let match = regex.firstMatch(
            in: urlString,
            options: [],
            range: wholeRange
        ) else {
            return nil
        }
        
        guard let targetRange = Range(match.range(at: 1), in: urlString) else {
            return nil
        }
        
        return String(urlString[targetRange])
    }
    
    func getHTML(completion: @escaping (String?, Error?) -> Void) {
        
        // First request to get the video HTML
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = Self.htmlRequestHeaders
        request.timeoutInterval = Constants.requestTimeLimit
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard
                let data = data,
                let html = String(
                    data: data,
                    encoding: .utf8
                )
            else {
                completion(nil, NSError(domain: "", code: -101, userInfo: [NSLocalizedDescriptionKey: "Failed to get video HTML"]))
                return
            }
            
            completion(html, nil)
            
        }
        task.resume()
        
    }
    
    func retrieveTitle(from html: String) -> String? {
        
        let pattern = Self.titlePattern
        if let range = html.range(
            of: pattern,
            options: .regularExpression
        ) {
            
            let title = String(html[range])
                .replacingOccurrences(of: "<meta name=\"title\" content=\"", with: "")
                .replacingOccurrences(of: "\">", with: "")
            
            return title
            
        } else {
            
            return nil
            
        }
        
    }
    
    func retrieveCaptions(from videoID: String, maxTries: Int, completion: @escaping ([CaptionEvent], Error?) -> Void) {
        let api = YoutubeTranscriptAPISwift()
        
        Task {
            var currentTry = 0
            var lastError: Error?
            
            while currentTry < maxTries {
                currentTry += 1
                print("retrieveCaptions: 尝试获取字幕 (第 \(currentTry)/\(maxTries) 次)")
                
                do {
                    let transcript = try await api.fetchTranscript(
                        videoId: videoID,
                        language: LangCode.currentLanguage.rawValue
                    )
                    
                    var captionEvents: [CaptionEvent] = []
                    for segment in transcript.events {
                        captionEvents.append(CaptionEvent(
                            startMs: Double(segment.tStartMs),
                            durationMs: Double(segment.dDurationMs),
                            segs: segment.text
                        ))
                    }
                    
                    // 成功获取，返回结果
                    completion(captionEvents, nil)
                    return
                    
                } catch {
                    print("retrieveCaptions: 第 \(currentTry) 次尝试失败: \(error.localizedDescription)")
                    lastError = error
                    
                    // 如果不是最后一次尝试，等待一段时间后重试
                    if currentTry < maxTries {
                        let delay = 0.5
                        print("retrieveCaptions: 等待 \(delay) 秒后重试...")
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                }
            }
            
            // 所有尝试都失败了
            print("retrieveCaptions: 所有 \(maxTries) 次尝试均失败")
            completion([], lastError)
        }
    }
    
//    func replaceLangParameter(in url: URL, with languageCode: String) -> URL? {
//        // Parse the URL components
//        guard var components = URLComponents(
//            url: url,
//            resolvingAgainstBaseURL: false
//        ) else {
//            return nil
//        }
//        
//        // Parse the query items
//        var queryItems = components.queryItems ?? []
//        
//        // Check if lang parameter already exists
//        if let existingIndex = queryItems.firstIndex(where: { $0.name == "lang" }) {
//            // Replace the existing lang value
//            queryItems[existingIndex].value = languageCode
//        } else {
//            // Add new lang parameter
//            let langQueryItem = URLQueryItem(
//                name: "lang",
//                value: languageCode
//            )
//            queryItems.append(langQueryItem)
//        }
//        
//        components.queryItems = queryItems
//        
//        return components.url
//    }
//
//    func retrieveCaptions(from html: String, completion: @escaping ([CaptionEvent]?, Error?) -> Void) {
//        
//        // Extract timed text URL
//        guard let timedTextUrlRange = html.range(
//            of: Self.timedTextURLPattern,
//            options: .regularExpression
//        ) else {
//            completion(nil, NSError(domain: "", code: -201, userInfo: [NSLocalizedDescriptionKey: "Failed to find caption tracks"]))
//            return
//        }
//        
//        var timedTextUrlStr = String(html[timedTextUrlRange])
//            .replacingOccurrences(of: #"\{"captionTracks":\[\{"baseUrl":""#, with: "", options: .regularExpression)
//            .replacingOccurrences(of: "\"", with: "")
//            .replacingOccurrences(of: "\\u0026", with: "&")
//        print("timedTextUrl: \(timedTextUrlStr)")
//        // Add additional parameters
//        timedTextUrlStr += Self.timedTextAdditionalKVArgs
//        print("timedTextUrl: \(timedTextUrlStr)")
//        
//        guard var timedTextUrl: URL = URL(string: timedTextUrlStr) else {
//            completion(nil, NSError(domain: "", code: -202, userInfo: [NSLocalizedDescriptionKey: "Failed to convert the timed text url \(timedTextUrlStr) to a URL object"]))
//            return
//        }
//        timedTextUrl = replaceLangParameter(
//            in: timedTextUrl,
//            with: LangCode.currentLanguage.rawValue
//        ) ?? timedTextUrl
//        
//        // Second request to get the captions
//        var timedTextRequest = URLRequest(url: timedTextUrl)
//        timedTextRequest.allHTTPHeaderFields = Self.timedTextRequestHeaders
//        timedTextRequest.timeoutInterval = Constants.requestTimeLimit
//        
//        let captionTask = URLSession.shared.dataTask(with: timedTextRequest) { data, response, error in
//            
//            if let error = error {
//                completion(nil, error)
//                return
//            }
//            
//            guard let data = data else {
//                completion(nil, NSError(domain: "", code: -203, userInfo: [NSLocalizedDescriptionKey: "Failed to get caption data"]))
//                return
//            }
//            
//            do {
//                // Parse JSON
//                if
//                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
//                    let events = json["events"] as? [[String: Any]]
//                {
//                    
//                    var captionEvents: [CaptionEvent] = []
//                    
//                    for event in events {
//                        guard let startMs = event["tStartMs"] as? Double,
//                              let durationMs = event["dDurationMs"] as? Double,
//                              let segsArray = event["segs"] as? [[String: Any]]
//                        else {
//                            continue
//                        }
//                        
//                        let segs = segsArray.compactMap {
//                            if
//                                let s = $0["utf8"] as? String,
//                                !s.strip().isEmpty
//                            {
//                                return s.strip().replacingOccurrences(
//                                    of: "\n",
//                                    with: " "
//                                )
//                            }
//                            return nil
//                        }.joined(separator: " ").strip()
//                        if segs.isEmpty {
//                            continue
//                        }
//
//                        captionEvents.append(CaptionEvent(
//                            startMs: startMs,
//                            durationMs: durationMs,
//                            segs: segs
//                        ))
//                    }
//                    
//                    completion(captionEvents, nil)
//                } else {
//                    completion(nil, NSError(domain: "", code: -204, userInfo: [NSLocalizedDescriptionKey: "Invalid caption JSON format"]))
//                }
//            } catch {
//                completion(nil, error)
//            }
//        }
//        
//        captionTask.resume()
//        
//    }
    
}

extension YoutubeVideoParser {
    
    // MARK: - Consonants
    
    static let youtubeHosts = [
        "youtube.com",
        "www.youtube.com",
        "m.youtube.com",
        "youtu.be",
        "www.youtu.be"
    ]
    
    static let videoIDPattern: String = #"(?:youtube(?:-nocookie)?\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})"#
//    static let timedTextURLPattern: String = #"\{"captionTracks":\[\{"baseUrl":"(https.+?timedtext\?.+?)""#
    static let titlePattern: String = "<meta name=\"title\" content=\"(.*?)\">"
    
    static let htmlRequestHeaders = [
        "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
        "accept-language": "ko,zh-CN;q=0.9,zh;q=0.8,es-ES;q=0.7,es;q=0.6,en;q=0.5",
        "cache-control": "no-cache",
        "pragma": "no-cache",
        "sec-ch-ua": "\"Google Chrome\";v=\"135\", \"Not-A.Brand\";v=\"8\", \"Chromium\";v=\"135\"",
        "sec-ch-ua-mobile": "?0",
        "sec-ch-ua-platform": "\"Windows\"",
        "sec-fetch-dest": "document",
        "sec-fetch-mode": "navigate",
        "sec-fetch-site": "same-origin",
        "sec-fetch-user": "?1",
        "upgrade-insecure-requests": "1",
        "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36"
    ]
//    static let timedTextRequestHeaders = [
//        "accept": "*/*",
//        "accept-encoding": "gzip, deflate, br",
//        "accept-language": "ko,zh-CN;q=0.9,zh;q=0.8,es-ES;q=0.7,es;q=0.6,en;q=0.5",
//        "cache-control": "no-cache",
//        "pragma": "no-cache",
//        "sec-ch-ua": "\"Google Chrome\";v=\"135\", \"Not-A.Brand\";v=\"8\", \"Chromium\";v=\"135\"",
//        "sec-ch-ua-mobile": "?0",
//        "sec-ch-ua-platform": "\"Windows\"",
//        "sec-fetch-dest": "empty",
//        "sec-fetch-mode": "cors",
//        "sec-fetch-site": "same-origin",
//        "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36",
//        "x-youtube-client-name": "1",
//        "x-youtube-client-version": "2.20250428.01.00"
//    ]
    
//    static let timedTextAdditionalKVArgs = "&potc=1&pot=&fmt=json3&xorb=2&xobt=3&xovt=3&cbr=Chrome&cbrver=135.0.0.0&c=WEB&cver=2.20250428.01.00&cplayer=UNIPLAYER&cos=Windows&cosver=10.0&cplatform=DESKTOP"
    
}
