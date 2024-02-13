//
//  UIImageExt.swift
//  Polyglot
//
//  Created by Sola on 2022/12/20.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    func resize(to targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        return resize(widthRatio: widthRatio, heightRatio: heightRatio)
    }
    
    func resize(widthRatio: CGFloat, heightRatio: CGFloat) -> UIImage {
        let newSize = widthRatio > heightRatio
            ? CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
            : CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func scale(to ratio: CGFloat) -> UIImage {
        return resize(widthRatio: ratio, heightRatio: ratio)
    }
}

extension UIImage {
    
    func scaledToListIconSize() -> UIImage {
        // https://stackoverflow.com/questions/72082141/how-to-get-default-system-size-of-symbol-image-in-uilistcontentconfiguration
        let font = UIFont.preferredFont(forTextStyle: .body)
        let currentFontHeight = font.lineHeight
        let scaleFactor = currentFontHeight / self.size.height
        let scaledImage = self.resize(widthRatio: scaleFactor, heightRatio: scaleFactor)
        return scaledImage
        
    }
    
}
