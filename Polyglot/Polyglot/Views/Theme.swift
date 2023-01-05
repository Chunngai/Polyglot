//
//  Theme.swift
//  Polyglot
//
//  Created by Sola on 2022/12/20.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation
import UIKit

struct Colors {
    static let defaultBackgroundColor: UIColor = .white
    static let weakBackgroundColor: UIColor = UIColor.intRGB2UIColor(red: 238, green: 237, blue: 244)
    static let defaultTextColor: UIColor = .black
    static let weakTextColor: UIColor = UIColor.intRGB2UIColor(red: 106, green: 106, blue: 106)
    static let placeHolderColor: UIColor = Colors.weakTextColor
    
    static let speechBubbleColor: UIColor = UIColor.intRGB2UIColor(red: 238, green: 237, blue: 244)
    
    static let weakLightBlue: UIColor = UIColor.intRGB2UIColor(red: 206, green: 238, blue: 255)
    static let strongLightBlue: UIColor = UIColor.intRGB2UIColor(red: 135, green: 211, blue: 255)
    
    static let timingBarTintColor: UIColor = .systemGray5
    
    static let inactivateSelectionButtonBackgroundColor: UIColor = Colors.weakLightBlue
    static let activateSelectionButtonBackgroundColor: UIColor = Colors.strongLightBlue
    
    static let lightCorrectColor: UIColor = UIColor.intRGB2UIColor(red: 196, green: 245, blue: 177)
    static let lightInorrectColor: UIColor = UIColor.intRGB2UIColor(red: 251, green: 125, blue: 130)
    static let strongCorrectColor: UIColor = UIColor.intRGB2UIColor(red: 176, green: 225, blue: 157)
    static let strongIncorrectColor: UIColor = UIColor.intRGB2UIColor(red: 231, green: 105, blue: 110)
    
    static let separatorColor: UIColor = .lightGray
}

struct Icons {
    static let practiceIcon = UIImage(imageLiteralResourceName: "practice")
    static let cancelIcon = UIImage(imageLiteralResourceName: "cancel")
    static let doneIcon = UIImage(imageLiteralResourceName: "done")
    static let deleteIcon = UIImage(imageLiteralResourceName: "delete")
    static let translateIcon = UIImage(imageLiteralResourceName: "translate")
    static let previousIcon = UIImage(imageLiteralResourceName: "previous")
    static let nextIcon = UIImage(imageLiteralResourceName: "next")
}

struct Sizes {
    static let backgroundRoundViewRadius: CGFloat = 800
    
    static let primaryPromptFontSize: CGFloat = 50
    static let secondaryPromptFontSize: CGFloat = 20
    
    static let languageFlagScaleFactor: CGFloat = 0.6
    
    static let bigFontSize: CGFloat = 23
    static let mediumFontSize: CGFloat = 20
    static let smallFontSize: CGFloat = 14
    
    static let defaultCornerRadius: CGFloat = 15
    static let smallCornerRadius: CGFloat = 10
    static let defaultStackSpacing: CGFloat = 15
    
    static let roundButtonRadius: CGFloat = 55
}

struct Attributes {
    
    static let primaryPromptAttributes = [NSAttributedString.Key.font : UIFont.systemFont(
        ofSize: Sizes.primaryPromptFontSize,
        weight: .black
    )]
    static let secondaryPromptAttributes = [NSAttributedString.Key.font : UIFont.systemFont(
        ofSize: Sizes.secondaryPromptFontSize,
        weight: .black
    )]
    
    static let inactiveSelectionButtonTextAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.mediumFontSize, weight: .black),
        NSAttributedString.Key.foregroundColor : Colors.weakTextColor
    ]
    static let activeSelectionButtonTextAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.mediumFontSize, weight: .black),
        NSAttributedString.Key.foregroundColor : Colors.defaultTextColor
    ]
    
    static var defaultParaStyle: NSMutableParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 10
        paragraph.alignment = .left
        return paragraph
    }
    // TODO: - Update here.
    static let promptTextColorAttribute = [
        NSAttributedString.Key.foregroundColor : Colors.weakTextColor,
    ]
    static let newArticleTitleAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(
            ofSize: Sizes.secondaryPromptFontSize,
            weight: .heavy
        ),
        NSAttributedString.Key.foregroundColor : Colors.defaultTextColor,
        NSAttributedString.Key.paragraphStyle: Attributes.defaultParaStyle
    ]
    
    static let longTextAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.smallFontSize),
        NSAttributedString.Key.foregroundColor : Colors.defaultTextColor,
        NSAttributedString.Key.paragraphStyle: Attributes.defaultParaStyle
    ]
    
    static let practicePromptAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.bigFontSize),
        NSAttributedString.Key.paragraphStyle : Attributes.defaultParaStyle
    ]
}	

struct Vars {
    static let practiceDuration: TimeInterval = TimeInterval.minute * 10
    static let maxPracticeDuration: TimeInterval = Vars.practiceDuration * 3
}
