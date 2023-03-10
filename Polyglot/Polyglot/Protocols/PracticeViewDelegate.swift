//
//  PracticeViewDelegate.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation
import UIKit
import NaturalLanguage

protocol PracticeViewDelegate: UIView {
    
}

protocol WordPracticeViewDelegate: PracticeViewDelegate {
    
    func submit() -> String
    func updateViews(for correctness: WordPractice.Correctness, key: String, tokenizer: NLTokenizer)
    
}
