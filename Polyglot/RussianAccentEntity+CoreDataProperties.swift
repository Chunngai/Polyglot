//
//  Entity+CoreDataProperties.swift
//  Polyglot
//
//  Created by Ho on 8/28/24.
//  Copyright © 2024 Sola. All rights reserved.
//
//

import Foundation
import CoreData


extension RussianAccentEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RussianAccentEntity> {
        return NSFetchRequest<RussianAccentEntity>(entityName: "RussianAccentEntity")
    }

    @NSManaged public var bare_form: String?
    @NSManaged public var accent_pos: Int16
    @NSManaged public var base_form: String?

}

extension RussianAccentEntity : Identifiable {

}
