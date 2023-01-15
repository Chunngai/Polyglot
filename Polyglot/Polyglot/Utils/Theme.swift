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
    static let lightGrayBackgroundColor: UIColor = UIColor.intRGB2UIColor(red: 238, green: 237, blue: 244)
    
    static let normalTextColor: UIColor = .black
    static let weakTextColor: UIColor = UIColor.intRGB2UIColor(red: 106, green: 106, blue: 106)
        
    static let lightBlue: UIColor = UIColor.intRGB2UIColor(red: 206, green: 238, blue: 255)
    static let strongLightBlue: UIColor = UIColor.intRGB2UIColor(red: 135, green: 211, blue: 255)
    
    static let inactivateSelectionButtonBackgroundColor: UIColor = Colors.lightBlue
    static let activateSelectionButtonBackgroundColor: UIColor = Colors.strongLightBlue
        
    static let lightCorrectColor: UIColor = UIColor.intRGB2UIColor(red: 196, green: 245, blue: 177)
    static let lightInorrectColor: UIColor = UIColor.intRGB2UIColor(red: 251, green: 125, blue: 130)
    static let strongCorrectColor: UIColor = UIColor.intRGB2UIColor(red: 176, green: 225, blue: 157)
    static let strongIncorrectColor: UIColor = UIColor.intRGB2UIColor(red: 231, green: 105, blue: 110)
    
    static let timingBarTintColor: UIColor = .systemGray5

    static let separatorColor: UIColor = .lightGray
    
}

struct Images {
    
    static let backgroundImage: UIImage = UIImage(imageLiteralResourceName: "background")
    
    // Lang images.
    
    static let enImage: UIImage = UIImage(imageLiteralResourceName: LangCodes.en).scale(to: Sizes.langImageScalingFactor)
    static let jaImage: UIImage = UIImage(imageLiteralResourceName: LangCodes.ja).scale(to: Sizes.langImageScalingFactor)
    static let esImage: UIImage = UIImage(imageLiteralResourceName: LangCodes.es).scale(to: Sizes.langImageScalingFactor)
    
    private static let _langImages: [String : UIImage] = [
        LangCodes.en: Images.enImage,
        LangCodes.ja: Images.jaImage,
        LangCodes.es: Images.esImage
    ]
    static var langImage: UIImage {
        return Images._langImages[Variables.lang]!
    }
}

struct Icons {
    
    static let practiceIcon = UIImage(imageLiteralResourceName: "practice")
    static let cancelIcon = UIImage(imageLiteralResourceName: "cancel")
    static let doneIcon = UIImage(imageLiteralResourceName: "done")
    static let deleteIcon = UIImage(imageLiteralResourceName: "delete")
    static let translateIcon = UIImage(imageLiteralResourceName: "translate")
    static let previousIcon = UIImage(imageLiteralResourceName: "previous")
    static let nextIcon = UIImage(imageLiteralResourceName: "next")
    static let addIcon = UIImage(imageLiteralResourceName: "add")
    
}

struct Sizes {
    
    // MARK: - Radii.
    
    static let backgroundRoundViewRadius: CGFloat = 800
    static let roundButtonRadius: CGFloat = 55
    static let defaultCornerRadius: CGFloat = 15
    static let smallCornerRadius: CGFloat = 10
    
    // MARK: - Font Sizes.
    
    static let primaryPromptFontSize: CGFloat = 50
    static let secondaryPromptFontSize: CGFloat = 20
    static let largeFontSize: CGFloat = 23
    static let mediumFontSize: CGFloat = 20
    static let smallFontSize: CGFloat = 14
    
    // MARK: - Scaling.
    
    static let langImageScalingFactor: CGFloat = 0.6
    static let minimumScaleFactorForText: CGFloat = 0.5
    
    // MARK: - Spacings.
    
    static let defaultStackSpacing: CGFloat = 15
    
}

struct Attributes {
    
    // MARK: - Language Strings.
    
    static let langStringAttrs = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.mediumFontSize, weight: .regular),
        NSAttributedString.Key.foregroundColor : Colors.weakTextColor
    ]
    
    // MARK: - Paras.
    
    static var defaultParaStyle: NSMutableParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 10
        paragraph.alignment = .left
        return paragraph
    }
    
    static let longTextAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.smallFontSize),
        NSAttributedString.Key.foregroundColor : Colors.normalTextColor,
        NSAttributedString.Key.paragraphStyle: Attributes.defaultParaStyle
    ]
    
    // MARK: - Black Prompts.
    
    static let primaryPromptAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.primaryPromptFontSize, weight: .regular)
    ]
    static let secondaryPromptAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.secondaryPromptFontSize, weight: .regular)
    ]
    
    static let practicePromptAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.largeFontSize),
        NSAttributedString.Key.paragraphStyle : Attributes.defaultParaStyle
    ]
    
    // MARK: - Grey Prompts.
    
    static let promptTextColorAttribute = [
        NSAttributedString.Key.foregroundColor : Colors.weakTextColor,
    ]
    
    static let newArticleTitleAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.secondaryPromptFontSize, weight: .heavy),
        NSAttributedString.Key.foregroundColor : Colors.normalTextColor,
        NSAttributedString.Key.paragraphStyle: Attributes.defaultParaStyle
    ]
    static let newArticleTopicAttributes = Attributes.longTextAttributes
    static let newArticleBodyAttributes = Attributes.longTextAttributes
    static let newArticleSourceAttributes = Attributes.longTextAttributes
    
    // MARK: - Buttons.
    
    static let inactiveSelectionButtonTextAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.mediumFontSize, weight: .regular),
        NSAttributedString.Key.foregroundColor : Colors.weakTextColor
    ]
    static let activeSelectionButtonTextAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.mediumFontSize, weight: .regular),
        NSAttributedString.Key.foregroundColor : Colors.normalTextColor
    ]
}	
