//
//  YoutubeTranscriptAPISwift.swift
//  Polyglot
//
//  Created by Ho on 10/3/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import Foundation

// MARK: - 错误类型
enum YouTubeTranscriptError: Error, LocalizedError {
    case ipBlocked(String)
    case requestFailed(String, Error)
    case youTubeDataUnparsable(String)
    case requestBlocked(String)
    case ageRestricted(String)
    case invalidVideoId(String)
    case videoUnavailable(String)
    case videoUnplayable(String, String, [String])
    case transcriptsDisabled(String)
    case networkError(Error)
    case invalidURL
    case invalidResponse
    case noSubtitleForLanguage(String)

    var errorDescription: String? {
        switch self {
        case .ipBlocked(let videoId):
            return "IP blocked for video: \(videoId)"
        case .requestFailed(let videoId, let error):
            return "Request failed for video \(videoId): \(error.localizedDescription)"
        case .youTubeDataUnparsable(let videoId):
            return "YouTube data unparsable for video: \(videoId)"
        case .requestBlocked(let videoId):
            return "Request blocked (bot detected) for video: \(videoId)"
        case .ageRestricted(let videoId):
            return "Age restricted video: \(videoId)"
        case .invalidVideoId(let videoId):
            return "Invalid video ID: \(videoId)"
        case .videoUnavailable(let videoId):
            return "Video unavailable: \(videoId)"
        case .videoUnplayable(let videoId, let reason, let subreasons):
            return "Video unplayable: \(videoId) - \(reason) - \(subreasons.joined(separator: ", "))"
        case .transcriptsDisabled(let videoId):
            return "Transcripts disabled for video: \(videoId)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .noSubtitleForLanguage(let language):
            return "No subtitle found for language: \(language)"
        }
    }
}

// MARK: - 数据模型
struct TranscriptSegment {
    let tStartMs: Int
    let dDurationMs: Int
    let text: String
}

struct TranscriptResponse {
    let events: [TranscriptSegment]
}

struct CaptionTrack {
    let languageCode: String
    let vssId: String
    let baseUrl: String
}

// MARK: - 主类
class YoutubeTranscriptAPISwift {
    
    // MARK: - 私有常量
    private let watchUrlTemplate = "https://www.youtube.com/watch?v=%@"
    private let innertubeApiUrlTemplate = "https://www.youtube.com/youtubei/v1/player?key=%@"
    private let innertubeContext: [String: Any] = [
        "client": [
            "clientName": "ANDROID",
            "clientVersion": "20.10.38"
        ]
    ]
    
    // MARK: - 私有属性
    private let session: URLSession
    private let decoder = JSONDecoder()
    
    // MARK: - 初始化
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - 公开方法
    func fetchTranscript(videoId: String, language: String = "ko") async throws -> TranscriptResponse {
        let html = try await fetchVideoHtml(videoId: videoId)
        let apiKey = try extractInnertubeApiKey(html: html, videoId: videoId)
        let innertubeData = try await fetchInnertubeData(videoId: videoId, apiKey: apiKey)
        let captionsJson = try extractCaptionsJson(innertubeData: innertubeData, videoId: videoId)
        let transcript = try await fetchAndParseTranscript(captionsJson: captionsJson, language: language, videoId: videoId)
        return transcript
    }
    
    // MARK: - 私有方法
    
    /// 获取视频HTML页面
    private func fetchVideoHtml(videoId: String) async throws -> String {
        let urlString = String(format: watchUrlTemplate, videoId)
        guard let url = URL(string: urlString) else {
            throw YouTubeTranscriptError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("en-US", forHTTPHeaderField: "Accept-Language")
        
        do {
            let (data, response) = try await session.data(for: request)
            try checkHttpResponse(response: response, videoId: videoId)
            guard let html = String(data: data, encoding: .utf8) else {
                throw YouTubeTranscriptError.invalidResponse
            }
            return html.removingPercentEncoding ?? html
        } catch {
            throw YouTubeTranscriptError.networkError(error)
        }
    }
    
    /// 提取Innertube API密钥
    private func extractInnertubeApiKey(html: String, videoId: String) throws -> String {
        let pattern = #""INNERTUBE_API_KEY":\s*"([a-zA-Z0-9_-]+)""#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              match.numberOfRanges == 2 else {
            
            if html.contains("class=\"g-recaptcha\"") {
                throw YouTubeTranscriptError.ipBlocked(videoId)
            }
            throw YouTubeTranscriptError.youTubeDataUnparsable(videoId)
        }
        
        let range = Range(match.range(at: 1), in: html)!
        return String(html[range])
    }
    
    /// 获取Innertube数据
    private func fetchInnertubeData(videoId: String, apiKey: String) async throws -> [String: Any] {
        let urlString = String(format: innertubeApiUrlTemplate, apiKey)
        guard let url = URL(string: urlString) else {
            throw YouTubeTranscriptError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("en-US", forHTTPHeaderField: "Accept-Language")
        
        let requestBody: [String: Any] = [
            "context": innertubeContext,
            "videoId": videoId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await session.data(for: request)
            try checkHttpResponse(response: response, videoId: videoId)
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw YouTubeTranscriptError.invalidResponse
            }
            
            return json
        } catch {
            throw YouTubeTranscriptError.networkError(error)
        }
    }
    
    /// 检查HTTP响应
    private func checkHttpResponse(response: URLResponse, videoId: String) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeTranscriptError.invalidResponse
        }
        
        if httpResponse.statusCode == 429 {
            throw YouTubeTranscriptError.ipBlocked(videoId)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let error = NSError(domain: "HTTP", code: httpResponse.statusCode)
            throw YouTubeTranscriptError.requestFailed(videoId, error)
        }
    }
    
    /// 断言视频可播放性
    private func assertPlayability(playabilityStatusData: [String: Any], videoId: String) throws {
        guard let playabilityStatus = playabilityStatusData["status"] as? String else {
            return
        }
        
        if playabilityStatus != "OK" {
            let reason = playabilityStatusData["reason"] as? String ?? ""
            
            if playabilityStatus == "LOGIN_REQUIRED" {
                if reason.contains("Sign in to confirm you’re not a bot") {
                    throw YouTubeTranscriptError.requestBlocked(videoId)
                }
                if reason.contains("This video may be inappropriate for some users.") {
                    throw YouTubeTranscriptError.ageRestricted(videoId)
                }
            }
            
            if playabilityStatus == "ERROR" && reason.contains("This video is unavailable") {
                if videoId.hasPrefix("http://") || videoId.hasPrefix("https://") {
                    throw YouTubeTranscriptError.invalidVideoId(videoId)
                }
                throw YouTubeTranscriptError.videoUnavailable(videoId)
            }
            
            let errorScreen = playabilityStatusData["errorScreen"] as? [String: Any]
            let playerErrorMessageRenderer = errorScreen?["playerErrorMessageRenderer"] as? [String: Any]
            let subreason = playerErrorMessageRenderer?["subreason"] as? [String: Any]
            let runs = subreason?["runs"] as? [[String: Any]] ?? []
            
            let subreasonTexts = runs.compactMap { $0["text"] as? String }
            throw YouTubeTranscriptError.videoUnplayable(videoId, reason, subreasonTexts)
        }
    }
    
    /// 提取字幕JSON数据
    private func extractCaptionsJson(innertubeData: [String: Any], videoId: String) throws -> [String: Any] {
        guard let playabilityStatus = innertubeData["playabilityStatus"] as? [String: Any] else {
            throw YouTubeTranscriptError.invalidResponse
        }
        
        try assertPlayability(playabilityStatusData: playabilityStatus, videoId: videoId)
        
        guard let captions = innertubeData["captions"] as? [String: Any],
              let captionsJson = captions["playerCaptionsTracklistRenderer"] as? [String: Any],
              let captionTracks = captionsJson["captionTracks"] as? [[String: Any]] else {
            throw YouTubeTranscriptError.transcriptsDisabled(videoId)
        }
        
        return captionsJson
    }
    
    /// 获取并解析字幕
    private func fetchAndParseTranscript(captionsJson: [String: Any], language: String, videoId: String) async throws -> TranscriptResponse {
        guard let captionTracks = captionsJson["captionTracks"] as? [[String: Any]] else {
            throw YouTubeTranscriptError.transcriptsDisabled(videoId)
        }
        
        // 创建 VSS ID 到字幕轨道的映射
        var vssIdToTrack: [String: CaptionTrack] = [:]
        
        for trackData in captionTracks {
            guard let languageCode = trackData["languageCode"] as? String,
                  let vssId = trackData["vssId"] as? String,
                  let baseUrl = trackData["baseUrl"] as? String,
                  languageCode == language else {
                continue
            }
            
            let track = CaptionTrack(
                languageCode: languageCode,
                vssId: vssId,
                baseUrl: baseUrl
            )
            vssIdToTrack[vssId] = track
        }
        
        // 选择最佳字幕轨道
        let targetVssId: String
        let isASR: Bool
        
        if vssIdToTrack[".\(language)"] != nil {
            targetVssId = ".\(language)"
            isASR = false
        } else if vssIdToTrack["a.\(language)"] != nil {
            targetVssId = "a.\(language)"
            isASR = true
        } else {
            throw YouTubeTranscriptError.noSubtitleForLanguage(language)
        }
        
        guard let targetTrack = vssIdToTrack[targetVssId] else {
            throw YouTubeTranscriptError.noSubtitleForLanguage(language)
        }
        
        // 获取字幕内容
        guard let url = URL(string: targetTrack.baseUrl) else {
            throw YouTubeTranscriptError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("en-US", forHTTPHeaderField: "Accept-Language")
        
        do {
            let (data, response) = try await session.data(for: request)
            try checkHttpResponse(response: response, videoId: videoId)
            
            let xmlString = String(data: data, encoding: .utf8) ?? ""
            let transcript: TranscriptResponse
            
            if isASR {
                transcript = try parseXmlToJsonASR(xmlString: xmlString)
            } else {
                transcript = try parseXmlToJson(xmlString: xmlString)
            }
            
            return transcript
        } catch {
            throw YouTubeTranscriptError.networkError(error)
        }
    }
    
    /// 解析普通 XML 到 JSON 结构
    private func parseXmlToJson(xmlString: String) throws -> TranscriptResponse {
        let parser = XMLParser(data: Data(xmlString.utf8))
        let delegate = TranscriptXMLParser()
        parser.delegate = delegate
        
        if parser.parse() {
            return TranscriptResponse(events: delegate.segments)
        } else {
            throw YouTubeTranscriptError.invalidResponse
        }
    }
    
    /// 解析 ASR (自动语音识别) XML 到 JSON 结构
    private func parseXmlToJsonASR(xmlString: String) throws -> TranscriptResponse {
        let parser = XMLParser(data: Data(xmlString.utf8))
        let delegate = TranscriptXMLParserASR()
        parser.delegate = delegate
        
        if parser.parse() {
            return TranscriptResponse(events: delegate.segments)
        } else {
            throw YouTubeTranscriptError.invalidResponse
        }
    }
}

// MARK: - 普通 XML 解析器
private class TranscriptXMLParser: NSObject, XMLParserDelegate {
    var segments: [TranscriptSegment] = []
    private var currentElement = ""
    private var currentText = ""
    private var currentT = 0
    private var currentD = 0
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "p" {
            currentT = Int(attributeDict["t"] ?? "0") ?? 0
            currentD = Int(attributeDict["d"] ?? "0") ?? 0
            currentText = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElement == "p" {
            currentText += string
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "p" {
            let segment = TranscriptSegment(
                tStartMs: currentT,
                dDurationMs: currentD,
                text: currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            segments.append(segment)
        }
    }
}

// MARK: - ASR XML 解析器
private class TranscriptXMLParserASR: NSObject, XMLParserDelegate {
    var segments: [TranscriptSegment] = []
    private var currentElement = ""
    private var currentTextParts: [String] = []
    private var currentT = 0
    private var currentD = 0
    private var hasSTags = false
    private var inPTag = false
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "p" {
            inPTag = true
            currentT = Int(attributeDict["t"] ?? "0") ?? 0
            currentD = Int(attributeDict["d"] ?? "0") ?? 0
            currentTextParts = []
            hasSTags = false
        } else if elementName == "s" && inPTag {
            hasSTags = true
            currentTextParts.append("") // 为 s 标签准备空字符串
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inPTag {
            if currentElement == "p" {
                // p 标签的直接文本内容
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    currentTextParts.append(trimmed)
                }
            } else if currentElement == "s" {
                // s 标签的文本内容
                if let lastIndex = currentTextParts.indices.last {
                    currentTextParts[lastIndex] += string
                }
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "p" {
            // 如果 p 标签不包含 s 标签，跳过该 p 标签
            if !hasSTags {
                inPTag = false
                return
            }
            
            // 清理文本部分
            let cleanedTextParts = currentTextParts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            let text = cleanedTextParts.isEmpty ? "" : cleanedTextParts.joined(separator: " ")
            
            let segment = TranscriptSegment(
                tStartMs: currentT,
                dDurationMs: currentD,
                text: text
            )
            segments.append(segment)
            inPTag = false
        }
    }
}
