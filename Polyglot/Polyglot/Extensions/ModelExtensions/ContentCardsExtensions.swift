//
//  ContentCardsExtensions.swift
//  Polyglot
//
//  Created by Ho on 2/3/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation

extension ContentCards {
        
    static func sentenceSectionIdentifier(for hour: Int) -> Int {
        hour * 100
    }
    
    static func paragraphSectionIdentifier(for hour: Int) -> Int {
        hour * 1000
    }
    
}
