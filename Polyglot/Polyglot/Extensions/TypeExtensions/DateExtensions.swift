//
//  DateExt.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation
 
extension Date {
        
    private var defaultDateFormat: String {
        "yy MMM d"
    }
    
    private func makeRepresentation(with format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        return dateFormatter.string(from: self)
    }
    
    func repr(ofFormat format: String = "") -> String {
        let dateFormat = format.isEmpty
            ? defaultDateFormat
            : format
        return makeRepresentation(with: dateFormat)
    }
}

extension Date {
        
    // https://stackoverflow.com/questions/5979462/problem-combining-a-date-and-a-time-into-a-single-nsdate
    static func fromYearMonthDay(year: Int, month: Int, day: Int) -> Date {
        let calendar = Calendar.current

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)!
    }
}
