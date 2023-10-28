//
//  ContentCreator.swift
//  Polyglot
//
//  Created by Sola on 2023/8/27.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct ContentCreator {

    let lang: String!
    
    init(lang: String!) {
        self.lang = lang
    }
    
    private func makePrompt(for words: [String]) -> String {
        let words = words.joined(separator: "\n")
        
        switch self.lang {
        case LangCode.zh: return "请写一个包含以下单词的段落，注意不要改变所提供单词的形式。\n\(words)"
        case LangCode.en: return "Please write a paragraph containing the following words, taking care not to change the form of the words provided.\n\(words)"
        case LangCode.ja: return "次の言葉を含む段落を、提供された言葉の形を変えないように注意して書いてください。\n\(words)"
        case LangCode.es: return "Por favor escriba un párrafo que contenga las siguientes palabras, teniendo cuidado de no cambiar la forma de las palabras proporcionadas.\n\(words)"
        case LangCode.ru: return "Пожалуйста, напишите абзац, содержащий следующие слова, стараясь не менять форму предоставленных слов.\n\(words)"
        case LangCode.ko: return "제공된 단어의 형태가 변경되지 않도록 주의하면서 다음 단어를 포함하는 단락을 작성하십시오.\n\(words)"
        case LangCode.de: return "Bitte schreiben Sie einen Absatz mit den folgenden Wörtern und achten Sie darauf, die Form der angegebenen Wörter nicht zu ändern.\n\(words)"
        default: return ""
        }
    }
    
    func createContent(for words: [String], completion: @escaping (String?) -> Void) {
        
        guard !words.isEmpty else {
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
                "content": makePrompt(for: words)
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
