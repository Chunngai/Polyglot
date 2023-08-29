//
//  ContentCreator.swift
//  Polyglot
//
//  Created by Sola on 2023/8/27.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct ContentCreator {

    private func makePrompt(for word: String, in language: String) -> String {
        switch language {
        case LangCode.zh: return "写一个包含词语“\(word)”的句子。请注意，不要更改所提供单词的形式。"
        case LangCode.en: return "Write a sentence that contains the word \"\(word)\". Note that do not change the form of the provided word."
        case LangCode.ja: return "「\(word)」という単語を含む文を書いてください。提供された単語の形式を変更しないでください。"
        case LangCode.es: return "Escribe una oración que contenga la palabra \"\(word)\". Tenga en cuenta que no cambie la forma de la palabra proporcionada."
        case LangCode.ru: return "Напишите предложение, в котором есть слово «\(word)». Обратите внимание: не меняйте форму предоставленного слова."
        case LangCode.ko: return "\"\(word)\"이라는 단어를 포함하는 문장을 작성하세요. 제공된 단어의 형태를 변경하지 마십시오."
        case LangCode.de: return "Schreiben Sie einen Satz, der das Wort „\(word)“ enthält. Beachten Sie, dass Sie die Form des angegebenen Worts nicht ändern."
        default: return ""
        }
    }
    
    func createContent(for word: String, in language: String, completion: @escaping (String?) -> Void) {
        
        guard !word.isEmpty else {
            completion(nil)
            return
        }
        
        
        guard let url = URL(string: "https://api.chatanywhere.com.cn/v1/chat/completions") else {
            completion(nil)
            return
        }
        
        var request: URLRequest = URLRequest(
            url: url,
            timeoutInterval: Constants.requestTimeLimit
        )
        request.setValue(Constants.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIKeys.chatGptAPIKey)", forHTTPHeaderField: "Authorization")
        // https://stackoverflow.com/questions/31937686/how-to-make-http-post-request-with-json-body-in-swift
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "model": "gpt-3.5-turbo",
            "messages": [[
                "role": "user",
                "content": makePrompt(for: word, in: language)
            ]]
        ])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "Error.")
                completion(nil)
                return
            }
            if let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                // TODO: - Improve here.
                if let choicesArr = responseJSON["choices"] as? [Any] {
                    if let choiceDict = choicesArr[0] as? [String: Any] {
                        if let messageDict = choiceDict["message"] as? [String: String] {
                            completion(messageDict["content"] ?? nil)
                        }
                    }
                }
            } else if let responseString = String(data: data, encoding: .utf8) {
                print(responseString)
                completion(nil)
            } else {
                completion(nil)
            }
        }
        task.resume()
    }
}
