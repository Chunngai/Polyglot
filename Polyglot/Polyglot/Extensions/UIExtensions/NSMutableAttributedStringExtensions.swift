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
    
    func locateRange(text: String? = nil) -> NSRange? {
        let range: NSRange?
        if let text = text {
            range = self.mutableString.range(of: text)
        } else {
            range = NSMakeRange(0, self.length)
        }
        return range
    }
    
//    func set(attributes: [NSAttributedString.Key: Any], for range: NSRange) {
//        set(attributes: attributes, for: range)
//    }
//    
//    func set(attributes: [NSAttributedString.Key: Any], for text: String? = nil) {
//        let range = locateRange(text: text)
//        
//        if range!.location != NSNotFound {
//            set(attributes: attributes, for: range!)
//        }
//    }
    
    func add(attributes: [NSAttributedString.Key: Any], for text: String? = nil) {
        let range = locateRange(text: text)
        
        if range!.location != NSNotFound {
            add(attributes: attributes, for: range!)
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
