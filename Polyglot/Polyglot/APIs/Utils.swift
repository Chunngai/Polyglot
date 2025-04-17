//
//  Utils.swift
//  Polyglot
//
//  Created by Ho on 4/18/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let apiDidFail = Notification.Name("APIDidFailNotification")
}

func sendErrorMessage(_ message: String) {
    NotificationCenter.default.post(
        name: .apiDidFail,
        object: nil,
        userInfo: ["message": message]
    )
}
