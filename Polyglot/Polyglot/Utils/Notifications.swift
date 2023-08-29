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

func updateNotificationRequest(
    oldNotificationRequest: UNNotificationRequest,
    newTitle: String? = nil, newBody: String? = nil, newTriggerDateComponents: DateComponents? = nil
) {
    let notificationCenter = UNUserNotificationCenter.current()
    notificationCenter.add(makeNotificationRequest(
        title: newTitle != nil ?
            newTitle! :
            oldNotificationRequest.content.title,
        body: newBody != nil ?
            newBody! :
            oldNotificationRequest.content.body,
        triggerDateComponents: newTriggerDateComponents != nil ?
            newTriggerDateComponents! :
            (oldNotificationRequest.trigger as! UNCalendarNotificationTrigger).dateComponents,
        identifier: oldNotificationRequest.identifier
    ))
}

func removeAllNotifications() {
    // https://stackoverflow.com/questions/40562912/how-to-cancel-usernotifications
    let notificationCenter = UNUserNotificationCenter.current()
    notificationCenter.removeAllPendingNotificationRequests()
    notificationCenter.removeAllDeliveredNotifications()
}
