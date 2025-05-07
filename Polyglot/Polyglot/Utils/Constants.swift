//
//  Values.swift
//  Polyglot
//
//  Created by Sola on 2023/1/12.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation
import UIKit
import NaturalLanguage

struct Constants {
    
    static let filesToSend: [String] = {
        var fileNames: [String] = []
        for learningLang in LangCode.learningLanguages {
            fileNames.append(Word.fileName(for: learningLang))
            fileNames.append(Article.fileName(for: learningLang))
        }
        return fileNames
    }()
    
    // MARK: - Network
    
    static let requestTimeLimit: TimeInterval = TimeInterval.second * 6
    static let shortRequestTimeLimit: TimeInterval = TimeInterval.second * 3
    static let userAgent: String = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
    
    // MARK: - URL sharing
    
    static let youtubeURLSchemeName: String = "youtubeprocessor"
    static let youtubeURLHostName: String = "share"
    
}
