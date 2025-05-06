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
    
    // MARK: - Ranges
    
    func nsRange(from textRange: UITextRange) -> NSRange {
        // Ref: https://stackoverflow.com/questions/21149767/convert-selectedtextrange-uitextrange-to-nsrange
        let location = offset(from: beginningOfDocument, to: textRange.start)
        let length = offset(from: textRange.start, to: textRange.end)
        return NSRange(location: location, length: length)
    }
    
    func textRange(from nsRange: NSRange) -> UITextRange? {
        // Ref: https://stackoverflow.com/questions/9126709/create-uitextrange-from-nsrange
        if let rangeStart = position(from: beginningOfDocument, offset: nsRange.location),
           let rangeEnd = position(from: rangeStart, offset: nsRange.length) {
            return textRange(from: rangeStart, to: rangeEnd)
        }
        return nil
    }
    
}

extension UITextView {
    
    func selectBeginning() {
        self.selectedTextRange = self.textRange(
            from: self.beginningOfDocument,
            to: self.beginningOfDocument
        )
    }
    
    func scrollToTop(for range: NSRange, animated: Bool) {
        
        guard range.location != NSNotFound else { return }
        
        // Get the start position of the range
        guard let startPosition = self.position(from: self.beginningOfDocument, offset: range.location) else {
            return
        }
        
        // Get the rect for the caret at the start position
        let caretRect = self.caretRect(for: startPosition)
        
        // Scroll to make the caret rect visible at the top
        let desiredOffset = max(0, caretRect.origin.y - self.contentInset.top)
        self.setContentOffset(CGPoint(x: 0, y: desiredOffset), animated: animated)
        
    }
    
}

extension UITextView {
    
    func valueOf(textPosition: UITextPosition) -> Int {
        // https://stackoverflow.com/questions/19369438/uitextposition-to-int
        
        return offset(from: beginningOfDocument, to: textPosition)
    }
    
    func contentOffset(for range: NSRange) -> CGPoint? {
        
        // https://chatgpt.com/share/67339f83-c420-800d-8940-76dbce8c05d2
        
        guard
            let startPosition = position(
                from: beginningOfDocument,
                offset: range.location
            ),
            let endPosition = position(
                from: startPosition,
                offset: range.length
            ),
            let textRange = textRange(
                from: startPosition,
                to: endPosition
            ) else {
            return nil
        }
        
        let boundingRect = firstRect(for: textRange)
        
        var contentOffset = CGPoint()
        contentOffset.x = textContainerInset.left
        contentOffset.y = boundingRect.origin.y - textContainerInset.top
        return contentOffset
        
    }
    
}

extension UITextView {
    
    var lineCount: Int {
        // https://cloud.tencent.com.cn/developer/information/Swift%203-%20UITextView总行计数器
        var lineCount = 0
        self.layoutManager.enumerateLineFragments(forGlyphRange: NSRange(
            location: 0,
            length: self.text.count
        )) { (_, _, _, _, _) in
            lineCount += 1
        }
        return lineCount
    }
    
}

protocol TextAnimationDelegate: UITextView {
    
    var isColorAnimating: Bool { get set }
    
    var colorAnimationOriginalColor: UIColor { get set }
    var colorAnimationIntermediateColor: UIColor { get set }
    
}

extension TextAnimationDelegate {
    
    func startTextColorTransitionAnimation(for range: NSRange) {

        func animateToIntermidiateColor() {
            
            UIView.transition(
                with: self,
                duration: 1.0,
                options: .transitionCrossDissolve
            ) {
                self.textStorage.setTextColor(
                    for: range,
                    with: self.colorAnimationIntermediateColor
                )
            } completion: { ifFinished in
                if self.isColorAnimating {
                    animateToOriginalColor()
                } else {
                    // Reset to true for the animation next time.
                    self.isColorAnimating = true
                    return
                }
            }
            
        }
        
        func animateToOriginalColor() {
            
            UIView.transition(
                with: self,
                duration: 1.0,
                options: .transitionCrossDissolve
            ) {
                self.textStorage.setTextColor(
                    for: range,
                    with: self.colorAnimationOriginalColor
                )
            } completion: { ifFinished in
                if self.isColorAnimating {
                    animateToIntermidiateColor()
                } else {
                    // Reset to true for the animation next time.
                    self.isColorAnimating = true
                    return
                }
            }
            
        }
        
        animateToIntermidiateColor()
    }
    
}
