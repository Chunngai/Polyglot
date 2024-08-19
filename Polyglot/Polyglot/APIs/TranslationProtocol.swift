//
//  TranslationProtocol.swift
//  Polyglot
//
//  Created by Ho on 8/19/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation

protocol TranslationProtocol {
    
    var srcLang: LangCode { get set }
    var trgLang: LangCode { get set }
    
    func translate(query: String, completion: @escaping ([String]) -> Void)
    
}
