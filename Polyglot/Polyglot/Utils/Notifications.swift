//
//  Notifications.swift
//  Polyglot
//
//  Created by Sola on 2023/6/26.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation
import UIKit

func makeNotificationRequest(title: String, body: String, triggerDateComponents: DateComponents, identifier: String) -> UNNotificationRequest {
    
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    
    let trigger = UNCalendarNotificationTrigger(
        dateMatching: triggerDateComponents,
        repeats: false
    )
    
    let request = UNNotificationRequest(
        identifier: identifier,
        content: content,
        trigger: trigger
    )
    return request
}

func removeAllNotificationRequests() {
    // https://stackoverflow.com/questions/40562912/how-to-cancel-usernotifications
    let notificationCenter = UNUserNotificationCenter.current()
    notificationCenter.removeAllPendingNotificationRequests()
    notificationCenter.removeAllDeliveredNotifications()
}

func createWordCardContent(words: [Word], articles: [Article]) -> String {
    let randomWord = words.randomElement()!
//    let paraCandidates = makeParaCandidates(for: randomWord, shouldIgnoreCaseAndAccent: true)
//
//    if !paraCandidates.isEmpty {
//        let randomPara = paraCandidates.randomElement()!
//        // https://stackoverflow.com/questions/32305891/index-of-a-substring-in-a-string-with-swift
//        if let range = randomPara.text.range(of: randomWord.text) {
//            return String(randomPara.text[range.lowerBound..<range.upperBound])
//        }
//
//        return randomWord.text
//    } else {
//        return randomWord.text
//    }
    return randomWord.text
}

func generateWordcardNotifications(for lang: String, words: [Word], articles: [Article]) {
    guard !words.isEmpty else {
        return
    }
    removeAllNotificationRequests()
    
    let notificationCenter = UNUserNotificationCenter.current()
    // https://stackoverflow.com/questions/40270598/ios-10-how-to-view-a-list-of-pending-notifications-using-unusernotificationcente
    notificationCenter.getPendingNotificationRequests(completionHandler: { requests in
        var allPendingNotificationIds: [String] = []
        for request in requests {
            allPendingNotificationIds.append(request.identifier)
        }
        print(allPendingNotificationIds)
        
        // Create word cards for 10, 13, 16, 19, 21.
        for day in Date().nextNDays(n: 3) {
            for hour in [10, 13, 16, 19, 21] {
                let title = LangCode.toFlagIcon(langCode: lang)
                let body = createWordCardContent(words: words, articles: articles)
                let triggerDateComponents = DateComponents(
                    year: day.get(.year),
                    month: day.get(.month),
                    day: day.get(.day),
                    hour: hour
                )
                let identifier = "\(lang)-" +
                    "\(triggerDateComponents.year!)\(triggerDateComponents.month!)\(triggerDateComponents.day!)\(triggerDateComponents.hour!)"
                
                if !allPendingNotificationIds.contains(identifier) {
                    print("Adding a word card.")
                    print("  [title] \(title)")
                    print("  [body] \(body)")
                    print("  [trigger date components] \(triggerDateComponents)")
                    print("  [identifier] \(identifier)")
                    notificationCenter.add(makeNotificationRequest(
                        title: title,
                        body: body,
                        triggerDateComponents: triggerDateComponents,
                        identifier: identifier
                    ))
                }
            }
        }
    })
}
