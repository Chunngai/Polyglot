//
//  PracticeProducerDelegate.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

protocol PracticeItemDelegate {
    
    associatedtype T: Any
    
    var practice: T { get set }
    
}

protocol PracticeProducerDelegate {
    
    // https://stackoverflow.com/questions/31765806/can-my-class-override-protocol-property-type-in-swift
    
    associatedtype T: Any
    associatedtype U: PracticeItemDelegate
    
    var dataSource: [T] { get set }
    
    var practiceList: [U] { get set }
    var currentPracticeIndex: Int { get set }
    var currentPractice: U { get set }
    
    func make() -> U
    mutating func next()
    
}
