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
