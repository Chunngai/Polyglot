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
    
    static let defaultDateFormat: String = "yy MMM d"
    static let defaultDateFormatter: DateFormatter = Date.formatter(of: Date.defaultDateFormat)
    
    static let defaultTimeFormat: String = "HH:mm"
    static let defaultTimeFormatter: DateFormatter = Date.formatter(of: Date.defaultTimeFormat)
    
    static let defaultDateAndTimeFormat: String = Date.defaultDateFormat + " " + Date.defaultTimeFormat
    static let defaultDateAndTimeFormatter: DateFormatter = Date.formatter(of: Date.defaultDateAndTimeFormat)
    
    static func formatter(of dateFormat: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        return formatter
    }
}
 
extension Date {
    
    func repr(from formatter: DateFormatter) -> String {
        return formatter.string(from: self)
    }
    
    func repr(of format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        return repr(from: formatter)
    }
}

extension Date {
    
    static func fromComponents(components: DateComponents, calendar: Calendar = Calendar.current) -> Date? {
        return calendar.date(from: components)
    }
    
    // https://stackoverflow.com/questions/5979462/problem-combining-a-date-and-a-time-into-a-single-nsdate
    static func fromYearMonthDay(year: Int, month: Int, day: Int, calendar: Calendar = Calendar.current) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)
    }
    
    static func from(string: String, of formatter: DateFormatter) -> Date? {
        return formatter.date(from: string)
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
