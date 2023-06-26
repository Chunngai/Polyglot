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

func removeAllNotifications() {
    // https://stackoverflow.com/questions/40562912/how-to-cancel-usernotifications
    let notificationCenter = UNUserNotificationCenter.current()
    notificationCenter.removeAllPendingNotificationRequests()
    notificationCenter.removeAllDeliveredNotifications()
}

func generateWordcardNotifications(for lang: String, words: [Word], articles: [Article]) {
    guard !words.isEmpty else {
        return
    }
//    removeAllNotifications()
    
    let notificationCenter = UNUserNotificationCenter.current()
    // https://stackoverflow.com/questions/40270598/ios-10-how-to-view-a-list-of-pending-notifications-using-unusernotificationcente
    notificationCenter.getPendingNotificationRequests(completionHandler: { requests in
        let learningLangs = LangCode.loadLearningLanguages()
        let maxRequestPerLang = 64 / learningLangs.count  // 64: max pending request num.
        
        var pendingNotificationRequestsMapping: [String: [String]] = [:]  // {lang code: request ids}
        for lang in learningLangs {  // Init with an empty arr.
            pendingNotificationRequestsMapping[lang] = []
        }
        for request in requests {
            let rid = request.identifier
            let langCode = rid.split(with: "-")[0]
            pendingNotificationRequestsMapping[langCode]!.append(rid)
        }
        print(pendingNotificationRequestsMapping)
                
        // Create word cards for 10-22.
        for day in Date().nextNDays(n: 3) {
            for hour in 10...22 {
                let worcCardContent = createWordCardContent(words: words, articles: articles)
                
                let title = "\(LangCode.toFlagIcon(langCode: lang)) \(worcCardContent.word)"
                let body = worcCardContent.content
                let triggerDateComponents = DateComponents(
                    year: day.get(.year),
                    month: day.get(.month),
                    day: day.get(.day),
                    hour: hour
                )
                let identifier = "\(lang)-" +
                    "\(triggerDateComponents.year!)\(triggerDateComponents.month!)\(triggerDateComponents.day!)\(triggerDateComponents.hour!)"

                if pendingNotificationRequestsMapping[lang]!.contains(identifier) || pendingNotificationRequestsMapping[lang]!.count >= maxRequestPerLang {
                    continue
                }
                
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
                pendingNotificationRequestsMapping[lang]!.append(identifier)
            }
        }
    })
}
