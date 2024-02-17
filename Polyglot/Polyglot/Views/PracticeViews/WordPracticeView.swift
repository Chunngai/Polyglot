//
//  WordPracticeView.swift
//  Polyglot
//
//  Created by Ho on 2/17/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation
import NaturalLanguage

class WordPracticeView: BasePracticeView {
    
    func submit() -> String {
        fatalError("submit() has not been implemented.")
    }
    
    func updateViewsAfterSubmission(
        for correctness: WordPractice.Correctness,
        key: String,
        tokenizer: NLTokenizer
    ) {
        fatalError("updateViewsAfterSubmission(for correctness:key:tokenizer:) has not been implemented.")
    }
    
}

protocol WordPracticeViewDelegate {
    
    func activateDoneButton()
    func deactivateDoneButton()
    
}
