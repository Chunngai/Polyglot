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
    static let lightGrayBackgroundColor: UIColor = .secondarySystemBackground
    static let maskBackgroundColor: UIColor = UIColor.intRGB2UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
    
    static let normalTextColor: UIColor = .black
    static let weakTextColor: UIColor = UIColor.intRGB2UIColor(red: 106, green: 106, blue: 106)
    static let inactiveTextColor: UIColor = .lightGray
    static let lightTextColor: UIColor = .white
        
    static let activeSystemButtonColor: UIColor = .systemBlue
    static let inactiveSystemButtonColor: UIColor = .lightGray
    
    static let lightBlue: UIColor = UIColor.intRGB2UIColor(red: 213, green: 236, blue: 248)
    static let strongLightBlue: UIColor = UIColor.intRGB2UIColor(red: 154, green: 207, blue: 238)
    
    static let inactivateSelectionButtonBackgroundColor: UIColor = Colors.lightBlue
    static let activateSelectionButtonBackgroundColor: UIColor = Colors.strongLightBlue
        
    static let correctColor: UIColor = UIColor.intRGB2UIColor(red: 186, green: 220, blue: 173)
    static let incorrectColor: UIColor = UIColor.intRGB2UIColor(red: 201, green: 113, blue: 117)
    
    static let timingBarTintColor: UIColor = .systemGray5
    
    static let borderColor: UIColor = .systemGray5

    static let separatorColor: UIColor = .lightGray
    
    static let clozeMaskColor: UIColor = .systemGray5
    static let clozeMatchedTextColor: UIColor = Colors.strongLightBlue
    
}

struct Images {
    
    static let backgroundImage: UIImage = UIImage(imageLiteralResourceName: "background")
    
    // Lang images.
    
    static let enImage: UIImage = UIImage(imageLiteralResourceName: LangCode.en.rawValue).scale(to: Sizes.langImageScalingFactor)
    static let jaImage: UIImage = UIImage(imageLiteralResourceName: LangCode.ja.rawValue).scale(to: Sizes.langImageScalingFactor)
    static let esImage: UIImage = UIImage(imageLiteralResourceName: LangCode.es.rawValue).scale(to: Sizes.langImageScalingFactor)
    static let ruImage: UIImage = UIImage(imageLiteralResourceName: LangCode.ru.rawValue).scale(to: Sizes.langImageScalingFactor)
    static let koImage: UIImage = UIImage(imageLiteralResourceName: LangCode.ko.rawValue).scale(to: Sizes.langImageScalingFactor)
    static let deImage: UIImage = UIImage(imageLiteralResourceName: LangCode.de.rawValue).scale(to: Sizes.langImageScalingFactor)
    
    static let langImages: [LangCode : UIImage] = [
        LangCode.en: Images.enImage,
        LangCode.ja: Images.jaImage,
        LangCode.es: Images.esImage,
        LangCode.ru: Images.ruImage,
        LangCode.ko: Images.koImage,
        LangCode.de: Images.deImage,
    ]
    static var langImage: UIImage {
        return Images.langImages[LangCode.currentLanguage]!
    }
    
    // Cell images.
    
    static let wordsImage: UIImage = UIImage.init(systemName: "list.bullet")!
    static let articlesImage: UIImage = UIImage.init(systemName: "books.vertical")!
    
    static let wordPracticeImage: UIImage = UIImage.init(systemName: "square.and.pencil")!
    static let listeningPracticeImage: UIImage = UIImage.init(systemName: "beats.headphones")!
    static let translationPracticeImage: UIImage = UIImage.init(systemName: "bubble")!
    
    static let contentCardProduceSpeechImage: UIImage = UIImage.init(systemName: "play.circle")!
    static let contentCardStopSpeechImage: UIImage = UIImage.init(systemName: "stop.circle")!
    static let contentCardHidingMeaningImage: UIImage = UIImage.init(systemName: "questionmark.app")!
    static let contentCardDisplayingMeaningImage: UIImage = UIImage.init(systemName: "questionmark.app.fill")!
    
    static let listeningPracticeProduceSpeechImage: UIImage = UIImage.init(systemName: "play.circle")!
    static let listeningPracticePauseSpeechImage: UIImage = UIImage.init(systemName: "pause.circle")!
    static let listeningPracticeStartToRecordSpeechImage: UIImage = UIImage.init(systemName: "mic.circle")!
    static let listeningPracticeRecordingSpeechImage: UIImage = UIImage.init(systemName: "mic.circle.fill")!
    static let listeningPracticeDisallowSpeechRecordingImage: UIImage = UIImage.init(systemName: "mic.slash.circle")!
    
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
    static let startIcon = UIImage(imageLiteralResourceName: "start")
    static let pauseIcon = UIImage(imageLiteralResourceName: "pause")
    static let chatgptIcon = UIImage(imageLiteralResourceName: "chatgpt").whiteBackgroundToTransparent()!
    static let googleTranslateIcon = UIImage(imageLiteralResourceName: "google-translate")
    
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
//    static let largeFontSize: CGFloat = 23
    static let mediumFontSize: CGFloat = 17
    static let smallFontSize: CGFloat = 15
    static let practiceFontSize: CGFloat = 20
    
    // MARK: - Scaling.
    
    static let langImageScalingFactor: CGFloat = 0.6
    static let minimumScaleFactorForText: CGFloat = 0.5
    
    // MARK: - Spacings.
    
    static let defaultStackSpacing: CGFloat = 15
    static let defaultLineSpacing: CGFloat = 10
    static let defaultParagraphSpacing: CGFloat = 10
    static let smallLineSpacing: CGFloat = 5
    static let defaultCollectionLayoutMinimumLineSpacing: CGFloat = 0
    static let defaultCollectionLayoutMinimumInteritemSpacing: CGFloat = 0
    
    // MARK: - Widths.
    
    static let reorderingRowStackWidth: CGFloat = UIScreen.main.bounds.width * 0.8
    static let reorderingWordBankWidth: CGFloat = UIScreen.main.bounds.width * 0.8
    static let defaultBorderWidth: CGFloat = 2
    
}

struct Attributes {
    
    // MARK: - Language Strings.
    
    static let langStringAttrs = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.mediumFontSize, weight: .regular),
        NSAttributedString.Key.foregroundColor : Colors.weakTextColor
    ]
    
    // MARK: - Paras.
    
    static var defaultParaStyle: NSMutableParagraphStyle {
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineSpacing = Sizes.defaultLineSpacing
        paraStyle.paragraphSpacing = Sizes.defaultParagraphSpacing
        paraStyle.alignment = .justified
        return paraStyle
    }
    static var leftAlignedParaStyle: NSMutableParagraphStyle {
        let paraStyle = Attributes.defaultParaStyle
        paraStyle.alignment = .left
        return paraStyle
    }
    static var practicePromptParaStyle: NSMutableParagraphStyle {
        let paraStyle = Attributes.leftAlignedParaStyle
        paraStyle.lineSpacing = Sizes.smallLineSpacing
        return paraStyle
    }
    
    static let defaultLongTextAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.smallFontSize),
        NSAttributedString.Key.foregroundColor : Colors.normalTextColor,
        NSAttributedString.Key.paragraphStyle: Attributes.defaultParaStyle
    ]
    static var leftAlignedLongTextAttributes: [NSAttributedString.Key: Any] {
        var attrs = Attributes.defaultLongTextAttributes
        attrs[NSAttributedString.Key.paragraphStyle] = Attributes.leftAlignedParaStyle
        return attrs
    }
    
    // MARK: - Black Prompts.
    
    static let primaryPromptAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.primaryPromptFontSize, weight: .regular)
    ]
    static let secondaryPromptAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.secondaryPromptFontSize, weight: .regular)
    ]
    
    static let practicePromptAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.practiceFontSize),
        NSAttributedString.Key.paragraphStyle : Attributes.practicePromptParaStyle,
        NSAttributedString.Key.foregroundColor : Colors.weakTextColor
    ]
    static let practiceWordAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.practiceFontSize),
        NSAttributedString.Key.foregroundColor : Colors.normalTextColor
    ]
    
    // MARK: - Grey Prompts.
    
    static let promptTextColorAttribute = [
        NSAttributedString.Key.foregroundColor : Colors.weakTextColor,
    ]
    
    static let newArticleTitleAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(
            ofSize: Sizes.smallFontSize,
            weight: .bold
        ),
        NSAttributedString.Key.foregroundColor : Colors.normalTextColor,
        NSAttributedString.Key.paragraphStyle: Attributes.leftAlignedParaStyle
    ]
    static let newArticleTopicAttributes = Attributes.leftAlignedLongTextAttributes
    static let newArticleBodyAttributes = {
        var attrs = Attributes.leftAlignedLongTextAttributes
        let paraStyle = attrs[.paragraphStyle] as! NSMutableParagraphStyle
        paraStyle.paragraphSpacing = 0
        attrs[.paragraphStyle] = paraStyle
        return attrs
    }()
    static let newArticleSourceAttributes = Attributes.leftAlignedLongTextAttributes
    
    // MARK: - Buttons.
    
    static let inactiveSelectionButtonTextAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.practiceFontSize, weight: .regular),  // TODO: - Should be set in the stack.
        NSAttributedString.Key.foregroundColor : Colors.weakTextColor
    ]
    static let activeSelectionButtonTextAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.practiceFontSize, weight: .regular),  // TODO: - Should be set in the stack.
        NSAttributedString.Key.foregroundColor : Colors.normalTextColor
    ]
}	

struct Feedbacks {
    
    static let defaultFeedbackGenerator = UISelectionFeedbackGenerator()
    
}
