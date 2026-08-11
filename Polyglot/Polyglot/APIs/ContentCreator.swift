//
//  ContentCreator.swift
//  Polyglot
//
//  Created by Sola on 2023/8/27.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct ContentCreator {

    var apiURL: String?
    var apiKey: String?
    var model: String?
    var requestTimeLimit: TimeInterval

    init(
        apiURL: String? = globalConfigs.ChatGPTAPIURL,
        apiKey: String? = globalConfigs.ChatGPTAPIKey,
        model: String? = globalConfigs.ChatGPTModel,
        requestTimeLimit: TimeInterval = Constants.llmRequestTimeLimit
    ) {
        self.apiURL = apiURL
        self.apiKey = apiKey
        self.model = model
        self.requestTimeLimit = requestTimeLimit
    }
    
    func createContent(withSystemPrompt systemPrompt: String, userPrompt: String, displayErrorMessageWhenFailed: Bool = false, completion: @escaping (String?) -> Void) {
        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user",   "content": userPrompt]
        ]
        createContent(withMessages: messages, displayErrorMessageWhenFailed: displayErrorMessageWhenFailed, completion: completion)
    }

    func createContent(withSystemPrompt systemPrompt: String, conversationMessages: [[String: String]], displayErrorMessageWhenFailed: Bool = false, completion: @escaping (String?) -> Void) {
        var messages: [[String: String]] = [["role": "system", "content": systemPrompt]]
        messages.append(contentsOf: conversationMessages)
        createContent(withMessages: messages, displayErrorMessageWhenFailed: displayErrorMessageWhenFailed, completion: completion)
    }

    func streamContent(
        withSystemPrompt systemPrompt: String,
        conversationMessages: [[String: String]],
        onChunk: @escaping (String) -> Void,
        onFinish: @escaping () -> Void,
        onError: @escaping () -> Void
    ) {
        var messages: [[String: String]] = [["role": "system", "content": systemPrompt]]
        messages.append(contentsOf: conversationMessages)

        guard let baseURLString = apiURL,
              let baseURL = URL(string: baseURLString),
              let apiKey = apiKey
        else {
            onError()
            return
        }
        let url = baseURL.appendingPathComponent("v1/chat/completions")

        var request = URLRequest(url: url, timeoutInterval: requestTimeLimit)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        guard let body = try? JSONSerialization.data(withJSONObject: [
            "model": model ?? "",
            "messages": messages,
            "stream": true
        ]) else { onError(); return }
        request.httpBody = body

        let delegate = SSESessionDelegate(onChunk: onChunk, onFinish: onFinish, onError: onError)
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        session.dataTask(with: request).resume()
        // Retain the session until streaming completes.
        delegate.session = session
    }

    func createContent(withPrompt prompt: String, displayErrorMessageWhenFailed: Bool = false, completion: @escaping (String?) -> Void) {
        createContent(withMessages: [["role": "user", "content": prompt]], displayErrorMessageWhenFailed: displayErrorMessageWhenFailed, completion: completion)
    }

    private func createContent(withMessages messages: [[String: String]], displayErrorMessageWhenFailed: Bool = false, completion: @escaping (String?) -> Void) {

        print("ContentCreator: Creating content with messages: \(messages)")

        guard let baseURLString = apiURL,
              let baseURL = URL(string: baseURLString)
        else {
            if displayErrorMessageWhenFailed {
                displayErrorMessage("Invalid API URL: \(apiURL ?? "")")
            }
            completion(nil)
            return
        }
        let url = baseURL.appendingPathComponent("v1/chat/completions")
        guard let apiKey = apiKey else {
            if displayErrorMessageWhenFailed {
                displayErrorMessage("Invalid API key: \(apiKey ?? "")")
            }
            completion(nil)
            return
        }

        var request: URLRequest = URLRequest(
            url: url,
            timeoutInterval: requestTimeLimit
        )
        request.setValue(Constants.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        // https://stackoverflow.com/questions/31937686/how-to-make-http-post-request-with-json-body-in-swift
        request.httpMethod = "POST"
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "model": model ?? "",
                "messages": messages
            ])
        } catch {
            print("\(Self.self): \(error.localizedDescription)")
            if displayErrorMessageWhenFailed {
                displayErrorMessage(error.localizedDescription)
            }
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard
                let data = data,
                error == nil
            else {
                let errorMsg = error?.localizedDescription ?? "Request error."
                print(errorMsg)
                if displayErrorMessageWhenFailed {
                    displayErrorMessage(errorMsg)
                }
                completion(nil)
                return
            }
            
            if let responseJSON = try? JSONSerialization.jsonObject(
                with: data,
                options: []
            ) as? [String: Any] {

                if let error = responseJSON["error"] as? [String: String?],
                   let message = error["message"] as? String {

                    if displayErrorMessageWhenFailed {
                        displayErrorMessage(message)
                    }
                    completion(nil)
                    return
                }
                
                guard let choicesArr = responseJSON["choices"] as? [Any] else {
                    if displayErrorMessageWhenFailed {
                        displayErrorMessage("Failed to parse the response json: `guard let choicesArr = responseJSON[\"choices\"] as? [Any]`")
                    }
                    completion(nil)
                    return
                }
                guard let choiceDict = choicesArr[0] as? [String: Any] else {
                    if displayErrorMessageWhenFailed {
                        displayErrorMessage("Failed to parse the response json: `guard let choiceDict = choicesArr[0] as? [String: Any]`")
                    }
                    completion(nil)
                    return
                }
                guard let messageDict = choiceDict["message"] as? [String: Any] else {
                    if displayErrorMessageWhenFailed {
                        displayErrorMessage("Failed to parse the response json: `guard let messageDict = choiceDict[\"message\"] as? [String: String]`")
                    }
                    completion(nil)
                    return
                }
                guard let content = messageDict["content"] as? String else {
                    if displayErrorMessageWhenFailed {
                        displayErrorMessage("Failed to parse the response json: `guard let content = messageDict[\"content\"]`")
                    }
                    completion(nil)
                    return
                }
                
                completion(content)
                return
                
            } else {
                if displayErrorMessageWhenFailed {
                    displayErrorMessage("Failed to parse the response.")
                }
                completion(nil)
                return
                
            }
        }
        task.resume()
        
    }
    
    private func displayErrorMessage(_ msg: String) {
        sendErrorMessage("[\(Self.self)] \(msg)")
    }
    
}

extension ContentCreator {

    func generateImage(for word: String, completion: @escaping (String?) -> Void) {

        guard let apiKey = apiKey,
              let baseURLString = apiURL,
              let baseURL = URL(string: baseURLString)
        else {
            completion(nil)
            return
        }
        let url = baseURL.appendingPathComponent("v1/images/generations")

        var request = URLRequest(url: url, timeoutInterval: requestTimeLimit)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "model": model ?? "",
                "prompt": "A clear, simple illustration representing '\(word)' WITHOUT TEXT",
                "n": 1,
                "size": "256x256",
                "response_format": "b64_json"
            ])
        } catch {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            
            guard let data = data, error == nil,
                  let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let dataArr = json["data"] as? [[String: Any]],
                  let b64 = dataArr.first?["b64_json"] as? String,
                  let imageData = Data(base64Encoded: b64)
            else {
                completion(nil)
                return
            }

            let fileName = "practice_image_\(UUID().uuidString).png"
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(fileName)
            do {
                try imageData.write(to: fileURL)
                completion(fileName)
            } catch {
                completion(nil)
            }
        }.resume()

    }

}

extension ContentCreator {

    private func makeSentenceGenerationPrompt(for word: String, in lang: LangCode) -> String {
        switch lang {
        case LangCode.en: return "Please write a sentence containing the phrase: \(word). Note that you cannot change the form of the given phrase."
        case LangCode.ja: return "「\(word)」というフレーズを含む文を書いてください。指定されたフレーズの形式を変更することはできないことに注意してください。"
        case LangCode.es: return "Por favor escribe una oración que contenga la frase: \(word). Tenga en cuenta que no puede cambiar la forma de la frase dada."
        case LangCode.ru: return "Напишите, пожалуйста, предложение, содержащее фразу: \(word). Обратите внимание, что вы не можете изменить форму данной фразы."
        case LangCode.ko: return "\(word)이라는 문구를 포함하는 문장을 작성해주세요. 주어진 문구의 형태는 변경할 수 없습니다."
        case LangCode.de: return "Bitte schreiben Sie einen Satz mit der Phrase: \(word). Beachten Sie, dass Sie die Form der angegebenen Phrase nicht ändern können."
        default: return ""
        }
    }

    private func makeParagraphGenerationPrompt(for word: String, in lang: LangCode) -> String {
        switch lang {
        case LangCode.en: return "Please write a paragraph containing the phrase: \(word). Note that you cannot change the form of the given phrase."
        case LangCode.ja: return "「\(word)」というフレーズを含む段落を書いてください。指定されたフレーズの形式を変更することはできないことに注意してください。"
        case LangCode.es: return "Por favor escribe un párrafo que contenga la frase: \(word). Tenga en cuenta que no puede cambiar la forma de la frase dada."
        case LangCode.ru: return "Напишите, пожалуйста, абзац, содержащее фразу: \(word). Обратите внимание, что вы не можете изменить форму данной фразы."
        case LangCode.ko: return "\(word)이라는 문구를 포함하는 단락을 작성해주세요. 주어진 문구의 형태는 변경할 수 없습니다."
        case LangCode.de: return "Bitte schreiben Sie einen Absatz mit der Phrase: \(word). Beachten Sie, dass Sie die Form der angegebenen Phrase nicht ändern können."
        default: return ""
        }
    }
    
    func createContent(
        for words: [String],
        inLang lang: LangCode,
        inGranularity granularity: TextGranularity,
        completion: @escaping (String?
        ) -> Void) {
        
        var prompt: String
        if words.count == 1 {
            if granularity == .sentence || granularity == .subsentence {
                prompt = makeSentenceGenerationPrompt(
                    for: words[0],
                    in: lang
                )
            } else if granularity == .paragraph {
                prompt = makeParagraphGenerationPrompt(
                    for: words[0],
                    in: lang
                )
            } else {
                completion(nil)
                return
            }
        } else {
            // Not implemented.
            completion(nil)
            return
        }
        
        createContent(
            withPrompt: prompt,
            completion: completion
        )

    }

}

private class SSESessionDelegate: NSObject, URLSessionDataDelegate {

    var session: URLSession?
    private var buffer = ""
    private let onChunk: (String) -> Void
    private let onFinish: () -> Void
    private let onError: () -> Void

    init(onChunk: @escaping (String) -> Void, onFinish: @escaping () -> Void, onError: @escaping () -> Void) {
        self.onChunk = onChunk
        self.onFinish = onFinish
        self.onError = onError
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        buffer += text

        // SSE lines are separated by "\n\n"; each line starts with "data: "
        while let range = buffer.range(of: "\n\n") {
            let line = String(buffer[buffer.startIndex..<range.lowerBound])
            buffer.removeSubrange(buffer.startIndex..<range.upperBound)

            guard line.hasPrefix("data: ") else { continue }
            let json = String(line.dropFirst(6))
            if json == "[DONE]" { continue }

            guard let jsonData = json.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let choices = obj["choices"] as? [[String: Any]],
                  let delta = choices.first?["delta"] as? [String: Any],
                  let content = delta["content"] as? String,
                  !content.isEmpty
            else { continue }

            DispatchQueue.main.async { self.onChunk(content) }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            if error != nil {
                self.onError()
            } else {
                self.onFinish()
            }
        }
        self.session = nil
    }
}
