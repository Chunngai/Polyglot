//
//  NSAttributedStringExt.swift
//  Polyglot
//
//  Created by Sola on 2022/12/22.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation
import UIKit

extension NSAttributedString {
    
    func backgroundColor(at location: Int) -> UIColor? {
        if location >= 0 && location < length {
            return attributes(
                at: location,
                effectiveRange: nil
            )[.backgroundColor] as? UIColor
        }
        return nil
    }
    
    func textColor(at location: Int) -> UIColor? {
        if location >= 0 && location < length {
            return attributes(
                at: location,
                effectiveRange: nil
            )[.foregroundColor] as? UIColor
        }
        return nil
    }
    
}

extension NSAttributedString {
    
    static func imageAttributedString(icon: UIImage, font: UIFont) -> NSAttributedString {
        
        let textAttachment = NSTextAttachment()
        textAttachment.image = icon
        
        // Use the line height of the font for the image height to align with the text height
        let lineHeight = font.lineHeight
        // Adjust the width of the image to maintain the aspect ratio, if necessary
        let aspectRatio = textAttachment.image!.size.width / textAttachment.image!.size.height
        let imageWidth = lineHeight * aspectRatio
        textAttachment.bounds = CGRect(
            x: 0,
            y: (font.capHeight - lineHeight) / 2,
            width: imageWidth,
            height: lineHeight
        )
        
        return NSAttributedString(attachment: textAttachment)
    }
    
}

extension NSMutableAttributedString {
    
    func replacingAll(_ stringToReplace: String, with replacement: String) {
                
        var range = NSRange(
            location: 0,
            length: length
        )
        while range.location != NSNotFound {
            range = (string as NSString).range(
                of: stringToReplace,
                options: [],
                range: range
            )
            if range.location != NSNotFound {
                replaceCharacters(
                    in: range,
                    with: ""
                )
                range = NSRange(
                    location: range.location,
                    length: length - range.location
                )
            }
            
        }
        
    }
    
}

extension NSMutableAttributedString {
    
    func add(attributes: [NSAttributedString.Key: Any], for text: String? = nil, ignoreCasing: Bool = false, ignoreAccents: Bool = false) {

        // https://stackoverflow.com/questions/27180184/color-all-occurrences-of-string-in-swift
        
        let searchString = text ?? string
        
        var options: NSString.CompareOptions = NSString.CompareOptions()
        if ignoreCasing {
            options.insert(.caseInsensitive)
        }
        if ignoreAccents {
            options.insert(.diacriticInsensitive)
        }
        
        var rangeToSearch = string.startIndex..<string.endIndex
        while let matchingRange = string.range(
            of: searchString,
            options: options,
            range: rangeToSearch
        ) {
          addAttributes(
            attributes,
            range: NSRange(
                matchingRange,
                in: string
            )
          )
          rangeToSearch = matchingRange.upperBound..<string.endIndex
        }
    }
    
    func add(attributes: [NSAttributedString.Key: Any], for range: NSRange) {
        
        addAttributes(
            attributes,
            range: range
        )
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
    
    func setTextColor(for range: NSRange, with color: UIColor) {
        add(
            attributes: [
                .foregroundColor : color
            ],
            for: range
        )
    }
    
    func setBackgroundColor(for text: String? = nil, with color: UIColor, ignoreCasing: Bool = false, ignoreAccents: Bool = false) {
        add(
            attributes: [
                .backgroundColor : color
            ],
            for: text,
            ignoreCasing: ignoreCasing,
            ignoreAccents: ignoreAccents
        )
    }
    
    func setBackgroundColor(for range: NSRange, with color: UIColor) {
        add(
            attributes: [
                .backgroundColor : color
            ],
            for: range
        )
    }

    func setUnderline(for text: String? = nil, style: NSUnderlineStyle = .single, color: UIColor = .black, ignoreCasing: Bool = false, ignoreAccents: Bool = false) {
        add(
            attributes: [
                .underlineStyle: style.rawValue,
                .underlineColor: color
            ],
            for: text,
            ignoreCasing: ignoreCasing,
            ignoreAccents: ignoreAccents
        )
    }
    
    func setUnderline(for range: NSRange, style: NSUnderlineStyle = .single, color: UIColor = .black) {
        add(
            attributes: [
                .underlineStyle: style.rawValue,
                .underlineColor: color
            ],
            for: range
        )
    }

    func removeUnderline(for text: String? = nil, ignoreCasing: Bool = false, ignoreAccents: Bool = false) {
        setUnderline(
            for: text,
            style: [],
            ignoreCasing: ignoreCasing,
            ignoreAccents: ignoreAccents
        )
    }
    
    func removeUnderline(for range: NSRange) {
        setUnderline(
            for: range,
            style: []
        )
    }
    
    func bold(for range: NSRange, ignoreCasing: Bool = false, ignoreAccents: Bool = false) {
        guard let font = attributes(
            at: range.location,
            effectiveRange: nil
        )[.font] as? UIFont else {
            return
        }
        
        add(
            attributes: [
                .font: UIFont.systemFont(
                    ofSize: font.pointSize,
                    weight: .bold
                )
            ],
            for: range
        )
    }
    
}
