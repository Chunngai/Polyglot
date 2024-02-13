//
//  PracticeProducerDelegate.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

protocol PracticeItemDelegate {
        
}

protocol PracticeProducerDelegate {
    
    // https://stackoverflow.com/questions/31765806/can-my-class-override-protocol-property-type-in-swift
    
    associatedtype U: PracticeItemDelegate
    
    var words: [Word] { get set }
    var articles: [Article] { get set }
    var batchSize: Int { get set }
    
    var practiceList: [U] { get set }
    var currentPracticeIndex: Int { get set }
    var currentPractice: U { get set }
    
    func make() -> [U]
    mutating func next()
    
}

extension PracticeProducerDelegate {
    
    mutating func next() {
        currentPracticeIndex += 1
    }
    
}

extension PracticeProducerDelegate {
    
    // MARK: - Constants
    
    static var defaultBatchSize: Int {
        6
    }
    
}

enum TextGranularity: String {
    case sentence
    case paragraph
}
