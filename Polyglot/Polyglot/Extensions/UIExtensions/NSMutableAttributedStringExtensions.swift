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
    
    func add(attributes: [NSAttributedString.Key: Any], for text: String? = nil, ignoreCasing: Bool = false, ignoreAccents: Bool = false) {

        // https://stackoverflow.com/questions/27180184/color-all-occurrences-of-string-in-swift
        
        let attrStr = self.string
        let attrStrLen = attrStr.count
        
        let searchStr = text ?? self.string
        let searchStrLen = searchStr.count
        
        var options: NSString.CompareOptions = NSString.CompareOptions()
        if ignoreCasing {
            options.insert(.caseInsensitive)
        }
        if ignoreAccents {
            options.insert(.diacriticInsensitive)
        }
        
        var range = NSRange(location: 0, length: attrStr.count)
        while (range.location != NSNotFound) {
            range = (attrStr as NSString).range(of: searchStr, options: options, range: range)
            if (range.location != NSNotFound) {
                self.addAttributes(attributes, range: NSRange(location: range.location, length: searchStrLen))
                range = NSRange(location: range.location + range.length, length: attrStrLen - (range.location + range.length))
            }
        }
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
    func setTextColor(for text: String? = nil, with color: UIColor, ignoreCasing: Bool = false, ignoreAccents: Bool = false) {
        add(
            attributes: [
                .foregroundColor : color
            ],
            for: text,
            ignoreCasing: ignoreCasing,
            ignoreAccents: ignoreAccents
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
