//
//  TextTranslator.swift
//  Polyglot
//
//  Created by Ho on 8/19/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation

enum MachineTranslatorType: String, Codable {
    
    case google
    case baidu
    case none
    
    init(with translator: TranslationProtocol) {
        // https://medium.com/@mahigarg/type-checking-is-operator-in-swift-7a4f72ccb12e#:~:text=In%20Swift%2C%20the%20is%20keyword,or%20a%20more%20specific%20type.
        if translator is GoogleTranslator {
            self = .google
        } else if translator is BaiduTranslator {
            self = .baidu
        } else {
            self = .none
        }
    }
}

struct MachineTranslator {
    
    var srcLang: LangCode
    var trgLang: LangCode
    
    var translators: [TranslationProtocol]
    
    init(srcLang: LangCode, trgLang: LangCode) {
        
        self.srcLang = srcLang
        self.trgLang = trgLang
        
        self.translators = [
            GoogleTranslator(
                srcLang: srcLang,
                trgLang: trgLang
            ),
            BaiduTranslator(
                srcLang: srcLang,
                trgLang: trgLang
            )
        ]
        
    }
    
    private func _translate(withTranslatorOfIndex i: Int, query: String, completion: @escaping ([String], MachineTranslatorType) -> Void) {

        if self.translators.isEmpty || i >= self.translators.count {
            completion(
                [],
                MachineTranslatorType.none
            )
        } else {
            translators[i].translate(query: query) { translations in
                if !translations.isEmpty {
                    completion(
                        translations,
                        MachineTranslatorType(with: translators[i])
                    )
                } else {
                    self._translate(
                        withTranslatorOfIndex: i + 1,
                        query: query,
                        completion: completion
                    )
                }
            }
        }
    }

    func translate(query: String, completion: @escaping (
        [String],
        MachineTranslatorType
    ) -> Void) {
        self._translate(
            withTranslatorOfIndex: 0,
            query: query,
            completion: completion
        )
    }
    
}