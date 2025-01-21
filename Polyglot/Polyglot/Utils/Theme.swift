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
    static let activeTextColor: UIColor = .systemBlue
    static let inactiveTextColor: UIColor = .lightGray
    static let lightTextColor: UIColor = .white
        
    static let activeSystemButtonColor: UIColor = .systemBlue
    static let inactiveSystemButtonColor: UIColor = .lightGray
    static let inactivateSelectionButtonBackgroundColor: UIColor = Colors.lightBlue
    static let activateSelectionButtonBackgroundColor: UIColor = Colors.strongLightBlue
    
    static let lightBlue: UIColor = UIColor.intRGB2UIColor(red: 213, green: 236, blue: 255)
    static let strongLightBlue: UIColor = UIColor.intRGB2UIColor(red: 203, green: 226, blue: 255)
    
    static let correctColor: UIColor = UIColor.intRGB2UIColor(red: 186, green: 220, blue: 173)
    static let incorrectColor: UIColor = UIColor.intRGB2UIColor(red: 201, green: 113, blue: 117)
    
    static let timingBarTintColor: UIColor = .systemGray5
    static let borderColor: UIColor = .systemGray5
    static let separatorColor: UIColor = .lightGray
    
    static let clozeMaskColor: UIColor = .systemGray5
    static let clozeMatchedTextColor: UIColor = Colors.strongLightBlue
    
    static let newWordHighlightingColor = Self.lightBlue
    static let oldWordHighlightingColor = Self.strongLightBlue
    
}

struct Images {
    
    static let backgroundImage: UIImage = UIImage(imageLiteralResourceName: "background")
    
    // Lang images.
    
    static let zhImage: UIImage = UIImage(imageLiteralResourceName: LangCode.zh.rawValue).scale(to: Sizes.langImageScalingFactor)
    static let enImage: UIImage = UIImage(imageLiteralResourceName: LangCode.en.rawValue).scale(to: Sizes.langImageScalingFactor)
    static let jaImage: UIImage = UIImage(imageLiteralResourceName: LangCode.ja.rawValue).scale(to: Sizes.langImageScalingFactor)
    static let esImage: UIImage = UIImage(imageLiteralResourceName: LangCode.es.rawValue).scale(to: Sizes.langImageScalingFactor)
    static let ruImage: UIImage = UIImage(imageLiteralResourceName: LangCode.ru.rawValue).scale(to: Sizes.langImageScalingFactor)
    static let koImage: UIImage = UIImage(imageLiteralResourceName: LangCode.ko.rawValue).scale(to: Sizes.langImageScalingFactor)
    static let deImage: UIImage = UIImage(imageLiteralResourceName: LangCode.de.rawValue).scale(to: Sizes.langImageScalingFactor)
    
    static let langImages: [LangCode : UIImage] = [
        LangCode.zh: Images.zhImage,
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
    static let readingPracticeImage: UIImage = UIImage.init(systemName: "book.closed")!
    static let podcastPracticeImage: UIImage = UIImage.init(systemName: "radio")!
    
    static let configImage: UIImage = UIImage(systemName: "slider.horizontal.3")!
    
    // Content card images.
    
    static let contentCardProduceSpeechImage: UIImage = UIImage.init(systemName: "play.circle")!
    static let contentCardStopSpeechImage: UIImage = UIImage.init(systemName: "stop.circle")!
    static let contentCardHidingMeaningImage: UIImage = UIImage.init(systemName: "questionmark.app")!
    static let contentCardDisplayingMeaningImage: UIImage = UIImage.init(systemName: "questionmark.app.fill")!
    
    // Practice images.
    
    static let listeningPracticeProduceSpeechImage: UIImage = Icons.start1Icon
    static let listeningPracticePauseSpeechImage: UIImage = Icons.pause1Icon
    static let listeningPracticeStartToRecordSpeechImage: UIImage = Icons.micIcon
    static let listeningPracticeRecordingSpeechImage: UIImage = Icons.micFilledIcon
//    static let listeningPracticeDisallowSpeechRecordingImage: UIImage = UIImage.init(systemName: "mic.slash")!
 
    static let textMeaningPracticeReinforceImage: UIImage = Icons.refreshIcon
    
    // Settings images.
    
    static let settingsImage: UIImage = UIImage.init(systemName: "gearshape")!
    
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
    static let baiduTranslateIcon = UIImage(imageLiteralResourceName: "baidu-translate")
    
    // Ref: https://stackoverflow.com/questions/31803157/how-can-i-color-a-uiimage-in-swift
    static let start1Icon = UIImage(imageLiteralResourceName: "start_1").withRenderingMode(.alwaysTemplate)
    static let pause1Icon = UIImage(imageLiteralResourceName: "pause_1").withRenderingMode(.alwaysTemplate)
    static let micIcon = UIImage(imageLiteralResourceName: "mic").resize(widthRatio: 0.8, heightRatio: 0.8).withRenderingMode(.alwaysTemplate)
    static let micFilledIcon = UIImage(imageLiteralResourceName: "mic.filled").resize(widthRatio: 0.8, heightRatio: 0.8).withRenderingMode(.alwaysTemplate)
    static let refreshIcon = UIImage(imageLiteralResourceName: "refresh").withRenderingMode(.alwaysTemplate)
    
}

struct Sizes {
    
    // MARK: - Radii.
    
    static let backgroundRoundViewRadius: CGFloat = 800
    static let roundButtonRadius: CGFloat = 55
    static let defaultCornerRadius: CGFloat = 15
    static let smallCornerRadius: CGFloat = 10
    
    // MARK: - Font Sizes.
    
    static let mediumFontSize: CGFloat = 17
    static let smallFontSize: CGFloat = 15
    static let wordPracticeFontSize: CGFloat = 20
    
    // MARK: - Scaling.
    
    static let langImageScalingFactor: CGFloat = 0.6
    static let minimumScaleFactorForText: CGFloat = 0.5
    
    // MARK: - Spacings.
    
    static let defaultStackSpacing: CGFloat = 15
    
    // MARK: - Widths.
    
    static let reorderingRowStackWidth: CGFloat = UIScreen.main.bounds.width * 0.8
    static let reorderingWordBankWidth: CGFloat = UIScreen.main.bounds.width * 0.8
    static let defaultBorderWidth: CGFloat = 2
    
}

struct Attributes {
    
    // MARK: - Paras.
    
    static func defaultParaStyle(fontSize: CGFloat, alignment: NSTextAlignment = .left) -> NSMutableParagraphStyle {
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineSpacing = fontSize * 0.6
        paraStyle.paragraphSpacing = fontSize * 0.8
        paraStyle.alignment = alignment
        return paraStyle
    }
    
    static func defaultLongTextAttributes(fontSize: CGFloat) -> [NSAttributedString.Key : Any] {[
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: fontSize),
        NSAttributedString.Key.foregroundColor : Colors.normalTextColor,
        NSAttributedString.Key.paragraphStyle: Attributes.defaultParaStyle(fontSize: fontSize)
    ]}
    
    // MARK: - Black Prompts.
    
    static let practicePromptAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.wordPracticeFontSize),
        NSAttributedString.Key.paragraphStyle : Attributes.defaultParaStyle(fontSize: 5),  // lineSpacing = 5.
        NSAttributedString.Key.foregroundColor : Colors.weakTextColor
    ]
    static let practiceWordAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.wordPracticeFontSize),
        NSAttributedString.Key.foregroundColor : Colors.normalTextColor
    ]
    
    // MARK: - Buttons.
    
    static let inactiveSelectionButtonTextAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.wordPracticeFontSize, weight: .regular),  // TODO: - Should be set in the stack.
        NSAttributedString.Key.foregroundColor : Colors.weakTextColor
    ]
    static let activeSelectionButtonTextAttributes = [
        NSAttributedString.Key.font : UIFont.systemFont(ofSize: Sizes.wordPracticeFontSize, weight: .regular),  // TODO: - Should be set in the stack.
        NSAttributedString.Key.foregroundColor : Colors.normalTextColor
    ]
}	

struct Feedbacks {
    
    static let defaultFeedbackGenerator = UISelectionFeedbackGenerator()
    
}
