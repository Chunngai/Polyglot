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
    
    private func makeSentenceGenerationPrompt(for word: String) -> String {
        
//        switch self.lang {
//        case LangCode.zh: return "请使用以下单词列表中的单词编写一个流畅自然的段落。注意：（1）不要改变所提供单词的形式；（2）如果使用全部单词难以编写一个流畅自然的段落，你可以选择部分单词编写，但至少选择一个。单词列表如下：\(words)"
//        case LangCode.en: return "Please write a paragraph that flows naturally using words from the word list below. Note: (1) Do not change the form of the words provided; (2) If it is difficult to write a smooth and natural paragraph using all the words, you can choose some words to write, but choose at least one. The word list is as follows: \(words)"
//        case LangCode.ja: return "以下の単語リストの単語を使用して、自然に流れる段落を書いてください。注意: (1) 提供された単語の形式を変更しないでください; (2) すべての単語を使用して滑らかで自然な段落を書くことが難しい場合は、いくつかの単語を選択して書くことができますが、少なくとも1つは選択してください。単語リストは次のとおりです。\(words)"
//        case LangCode.es: return "Por favor escriba un párrafo que fluya naturalmente usando palabras de la lista de palabras a continuación. Nota: (1) No cambie la forma de las palabras proporcionadas; (2) Si le resulta difícil escribir un párrafo fluido y natural utilizando todas las palabras, puede elegir algunas palabras para escribir, pero elija al menos una. La lista de palabras es la siguiente: \(words)"
//        case LangCode.ru: return "Пожалуйста, напишите абзац, который будет естественным, используя слова из списка слов ниже. Примечание: (1) Не меняйте форму предоставленных слов; (2) Если сложно написать плавный и естественный абзац, используя все слова, вы можете выбрать несколько слов для написания, но выберите хотя бы одно. Список слов следующий: \(words)"
//        case LangCode.ko: return "아래 단어 목록의 단어를 사용하여 자연스럽게 흐르는 문단을 작성해주세요. 참고: (1) 제공된 단어의 형태를 변경하지 마십시오; (2) 모든 단어를 사용하여 매끄럽고 자연스러운 문단을 작성하기 어려운 경우, 작성할 단어를 몇 개 선택하되 적어도 하나를 선택하십시오. 단어 목록은 다음과 같습니다. \(words)"
//        case LangCode.de: return "Bitte schreiben Sie einen Absatz, der natürlich fließt, und verwenden Sie dabei Wörter aus der folgenden Wortliste. Hinweis: (1) Ändern Sie nicht die Form der bereitgestellten Wörter. (2) Wenn es schwierig ist, einen reibungslosen und natürlichen Absatz mit allen Wörtern zu schreiben, können Sie einige Wörter zum Schreiben auswählen, aber wählen Sie mindestens eines aus. Die Wortliste lautet wie folgt: \(words)"
//        default: return ""
//        }
        
        switch self.lang {
        case LangCode.en: return "Please write a sentence containing the phrase: \(word). Note that you cannot change the form of the given phrase."
        case LangCode.ja: return "「\(word)」というフレーズを含む文を書いてください。指定されたフレーズの形式を変更することはできないことに注意してください。"
        case LangCode.es: return "Por favor escribe una oración que contenga la frase: \(word). Tenga en cuenta que no puede cambiar la forma de la frase dada."
        case LangCode.ru: return "Напишите, пожалуйста, предложение, содержащее словосочетание: \(word). Обратите внимание, что вы не можете изменить форму данной фразы."
        case LangCode.ko: return "\(word)이라는 문구를 포함하는 문장을 작성해주세요. 주어진 문구의 형태는 변경할 수 없습니다."
        case LangCode.de: return "Bitte schreiben Sie einen Satz mit der Phrase: \(word). Beachten Sie, dass Sie die Form der angegebenen Phrase nicht ändern können."
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
        
        var prompt: String
        if words.count == 1 {
            prompt = makeSentenceGenerationPrompt(for: words[0])
        } else {
            // Not implemented.
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
            "model": "gpt-3.5-turbo-1106",
            "messages": [[
                "role": "user",
                "content": prompt
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
