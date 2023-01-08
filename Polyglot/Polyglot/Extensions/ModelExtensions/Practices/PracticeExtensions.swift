//
//  PracticeExtensions.swift
//  Polyglot
//
//  Created by Sola on 2022/12/27.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation

enum PracticeStatus: UInt {
    case beforeAnswering = 0  // Before selection or filling in.
    case afterAnswering = 1  // After selection or filling in, but the done button has not been tapped.
    case finished = 2  // The done button has been tapped.
}
