//
//  NSMutableAttributedStringExt.swift
//  Polyglot
//
//  Created by Sola on 2022/12/22.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation
import UIKit

extension NSMutableAttributedString {
    
//    func locateRange(text: String? = nil) -> NSRange {
//        let range: NSRange?
//        if let text = text {
//            range = self.mutableString.range(of: text)
//        } else {
//            range = NSMakeRange(0, self.length)
//        }
//        return range!
//    }
    
    func add(attributes: [NSAttributedString.Key: Any], for text: String? = nil) {

        // https://stackoverflow.com/questions/27180184/color-all-occurrences-of-string-in-swift
        
        let attrStr = self
        let attrStrLen = attrStr.string.count
        
        let searchStr = text ?? self.string
        let searchStrLen = searchStr.count
        
        var range = NSRange(location: 0, length: attrStr.length)
        while (range.location != NSNotFound) {
            range = (attrStr.string as NSString).range(of: searchStr, options: [], range: range)
            if (range.location != NSNotFound) {
                attrStr.add(attributes: attributes, for: NSRange(location: range.location, length: searchStrLen))
                range = NSRange(location: range.location + range.length, length: attrStrLen - (range.location + range.length))
            }
        }
    }
    
    func add(attributes: [NSAttributedString.Key: Any], for range: NSRange) {
        addAttributes(attributes, range: range)
    }
}

extension NSMutableAttributedString {
    
//    func set(backgroundColor: UIColor, for range: NSRange) {
//        set(attributes: [NSAttributedString.Key.backgroundColor : backgroundColor], for: range)
//    }
    
//    // MARK: - Customized Attribute Settings
//
//    // https://stackoverflow.com/questions/33818529/swift-strikethroughstyle-for-label-middle-delete-line-for-label
//    func setDeleteLine(for text: String? = nil) {
//        set(
//            attributes: [
//                .strikethroughStyle: NSUnderlineStyle.single.rawValue
//            ],
//            for: text
//        )
//    }
//
    func setTextColor(for text: String? = nil, with color: UIColor) {
        add(
            attributes: [
                .foregroundColor : color
            ],
            for: text
        )
    }
//
//    func setUnderline(for text: String? = nil, style: NSUnderlineStyle = .single, color: UIColor = .black) {
//        set(
//            attributes: [
//                .underlineStyle: style.rawValue,
//                .underlineColor: color
//            ],
//            for: text
//        )
//    }
//
//    func removeUnderline(for text: String? = nil) {
//        setUnderline(for: text, style: [], color: .black)
//    }
}
