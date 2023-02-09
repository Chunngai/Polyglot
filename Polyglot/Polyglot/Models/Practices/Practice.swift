//
//  Practice.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation

protocol Practice: Codable {
    // https://stackoverflow.com/questions/50346052/protocol-extending-encodable-or-codable-does-not-conform-to-it
    // https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types
    // Due to the Practice protocol, manual coding for the practices is needed.
}

enum PracticeDirection: UInt, Codable {
    case textToMeaning = 0
    case meaningToText = 1
    case text = 2
}
