//
//  DateExt.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation
 
extension Date {
        
    func get(_ component: Calendar.Component, from calendar: Calendar = Calendar.current) -> Int {
        // https://stackoverflow.com/questions/38248941/how-to-get-time-hour-minute-second-in-swift-3-using-nsdate
        return calendar.component(
            component,
            from: self
        )
    }
    
    func get(_ components: [Calendar.Component], from calendar: Calendar = Calendar.current) -> [Int] {
        // https://stackoverflow.com/questions/38248941/how-to-get-time-hour-minute-second-in-swift-3-using-nsdate
        return components.compactMap { (component) -> Int in
            get(
                component,
                from: calendar
            )
        }
    }
}

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
    
    func nextNDays(n: Int, from calendar: Calendar = Calendar.current) -> [Date] {
        // https://stackoverflow.com/questions/26996330/swift-get-last-7-days-starting-from-today-in-array
        
        guard n > 0 else {
            return []
        }
        
        var nextNDays: [Date] = []
        for i in 0...(n - 1) {
            nextNDays.append(calendar.date(
                byAdding: .day,
                value: i,
                to: self
            )!)
        }
        return nextNDays
    }
}
