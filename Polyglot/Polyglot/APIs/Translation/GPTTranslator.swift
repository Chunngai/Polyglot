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
    
    var gpt = ContentCreator(.gpt4o)
    
    init(srcLang: LangCode, trgLang: LangCode) {
        self.srcLang = srcLang
        self.trgLang = trgLang
                
    }
    
    func translate(query: String, completion: @escaping ([String]) -> Void) {
        
        guard !query.strip().isEmpty else {
            completion([query])
            return
        }
        
        self.gpt.createContent(
            withPrompt: "Translate the following sentence from \(Strings.languageNamesOfAllLanguages[self.srcLang]![LangCode.en]!) to \(Strings.languageNamesOfAllLanguages[self.trgLang]![LangCode.en]!) without explaining: \(query)."
        ) { gptResponse in
            
            guard let translation = gptResponse else {
                completion([])
                return
            }
            completion([translation])
            
        }
        
    }
    
}
