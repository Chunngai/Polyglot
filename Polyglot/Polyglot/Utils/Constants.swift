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
    
    // MARK: - Timing.
    
    static let practiceDuration: TimeInterval = TimeInterval.minute * 5
    static let maxPracticeDuration: TimeInterval = Constants.practiceDuration * 6
    
    // MARK: - Network.
    
    static let requestTimeLimit: TimeInterval = TimeInterval.second * 10
    static let shortRequestTimeLimit: TimeInterval = TimeInterval.second * 3
    static let userAgent: String = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
    
}
