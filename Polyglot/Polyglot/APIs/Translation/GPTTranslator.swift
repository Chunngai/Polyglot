//
//  GPTTranslator.swift
//  Polyglot
//
//  Created by Ho on 2/23/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import Foundation

struct GPTTranslator: TranslationProtocol {
    
    var srcLang: LangCode
    var trgLang: LangCode
    
    var enNameOfSrcLang: String!
    var enNameOfTrgLang: String!
    
    var gpt = {
        var gpt = ContentCreator(.gpt5_4)
//        gpt.requestTimeLimit = Constants.shortRequestTimeLimit
        return gpt
    }()
    
    init(srcLang: LangCode, trgLang: LangCode) {
        self.srcLang = srcLang
        self.trgLang = trgLang
        
        self.enNameOfSrcLang = Strings.languageNamesOfAllLanguages[self.srcLang]![LangCode.en]!
        self.enNameOfTrgLang = Strings.languageNamesOfAllLanguages[self.trgLang]![LangCode.en]!
        
    }
    
    var promptText1: [LangCode: String] {
        return [
            LangCode.zh: "我正在学习人工智能理论",
            LangCode.en: "I am studying artificial intelligence theory",
            LangCode.ja: "私は人工知能の理論を勉強しています",
            LangCode.es: "Estoy estudiando la teoría de la inteligencia artificial",
            LangCode.ru: "Я изучаю теорию искусственного интеллекта",
            LangCode.ko: "저는 인공지능 이론을 공부하고 있습니다",
            LangCode.de: "Ich studiere die Theorie der künstlichen Intelligenz"
        ]
    }
    var promptText2: [LangCode: String] {
        return [
            LangCode.zh: "榴莲很美味",
            LangCode.en: "Durian is delicious",
            LangCode.ja: "ドリアンは美味しいです",
            LangCode.es: "El durián es delicioso",
            LangCode.ru: "Дуриан очень вкусный",
            LangCode.ko: "두리안은 맛있어요",
            LangCode.de: "Durian ist lecker"
        ]
    }
    
    func systemPrompt() -> String {
        return """
Translate the given text from \(self.enNameOfSrcLang!) to \(self.enNameOfTrgLang!).

# Format
<input> input text
<output> output text

# Examples

<input> \(promptText1[self.srcLang]!)
<output> \(promptText1[self.trgLang]!)

<input> \(promptText2[self.srcLang]!)
<output> \(promptText2[self.trgLang]!)
"""
    }

    func userPrompt(with query: String) -> String {
        return """
<input> \(query)
<output>
"""
    }

    func translate(query: String, completion: @escaping ([String]) -> Void) {

        guard !query.strip().isEmpty else {
            completion([query])
            return
        }

        self.gpt.createContent(
            withSystemPrompt: systemPrompt(),
            userPrompt: userPrompt(with: query)
        ) { gptResponse in
            guard let translation = gptResponse else {
                completion([])
                return
            }
            completion([translation.strip()])
        }

    }
    
}
