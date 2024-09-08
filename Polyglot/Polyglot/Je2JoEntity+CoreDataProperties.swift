//
//  Je2JoEntity+CoreDataProperties.swift
//  Polyglot
//
//  Created by Ho on 9/9/24.
//  Copyright © 2024 Sola. All rights reserved.
//
//

import Foundation
import CoreData


extension Je2JoEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Je2JoEntity> {
        return NSFetchRequest<Je2JoEntity>(entityName: "Je2JoEntity")
    }

    @NSManaged public var je_text: String?
    @NSManaged public var jo_pos: Int16

}

extension Je2JoEntity : Identifiable {

}
