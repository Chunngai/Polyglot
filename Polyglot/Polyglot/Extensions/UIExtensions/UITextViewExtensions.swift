//
//  UITextViewExt.swift
//  Polyglot
//
//  Created by Sola on 2022/12/25.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation
import UIKit

extension UITextView {
    
    func valueOf(textPosition: UITextPosition) -> Int {
        // https://stackoverflow.com/questions/19369438/uitextposition-to-int
        
        return offset(from: beginningOfDocument, to: textPosition)
    }
    
    func selectBeginning() {
        self.selectedTextRange = self.textRange(
            from: self.beginningOfDocument,
            to: self.beginningOfDocument
        )
    }
    
}

extension UITextView {
    
    func imageAttributedString(icon: UIImage, font: UIFont) -> NSAttributedString {
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
