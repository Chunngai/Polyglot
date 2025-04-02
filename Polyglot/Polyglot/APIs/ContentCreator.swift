//
//  ContentCreator.swift
//  Polyglot
//
//  Created by Sola on 2023/8/27.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct ContentCreator {

    enum LLM: String {
        case gpt3_5 = "gpt-3.5-turbo-1106"
        case gpt4 = "gpt-4"
        case gpt4o = "gpt-4o"
    }
    
    var llm: LLM!
    
    var requestTimeLimit = Constants.requestTimeLimit
    
    init(_ llm: LLM = LLM.gpt3_5) {
        self.llm = llm
    }
    
    func createContent(withPrompt prompt: String, completion: @escaping (String?) -> Void) {
        
        print("ContentCreator: Creating content with prompt: \(prompt)")
        
        guard let urlString = globalConfigs.ChatGPTAPIURL,
              let url = URL(string: urlString) 
        else {
            completion(nil)
            return
        }
        guard let apiKey = globalConfigs.ChatGPTAPIKey else {
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
                "model": self.llm.rawValue,
                "messages": [[
                    "role": "user",
                    "content": prompt
                ]]
            ])
        } catch {
            print("\(Self.self): \(error.localizedDescription)")
            
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard
                let data = data,
                error == nil
            else {
                print(error?.localizedDescription ?? "Error.")
                
                completion(nil)
                return
            }
            
            if let responseJSON = try? JSONSerialization.jsonObject(
                with: data,
                options: []
            ) as? [String: Any] {

                guard let choicesArr = responseJSON["choices"] as? [Any] else {
                    completion(nil)
                    return
                }
                guard let choiceDict = choicesArr[0] as? [String: Any] else {
                    completion(nil)
                    return
                }
                guard let messageDict = choiceDict["message"] as? [String: String] else {
                    completion(nil)
                    return
                }
                guard let content = messageDict["content"] else {
                    completion(nil)
                    return
                }
                
                completion(content)
                return
                
            } else if let responseString = String(data: data, encoding: .utf8) {
                
                print(responseString)
                
                completion(nil)
                return
                
            } else {
                
                completion(nil)
                return
                
            }
        }
        task.resume()
        
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
