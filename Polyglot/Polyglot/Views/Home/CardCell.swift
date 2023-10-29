//
//  CardCell.swift
//  Polyglot
//
//  Created by Ho on 9/30/23.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class CardCellContentConfiguration: UIContentConfiguration {
    
    var header: String?
    
    var lang: String?
    var words: [String]?
    var meanings: [String]?
    var pronunciations: [String]?
    var content: String?
    var contentSource: ContentCard.ContentSource?
    
    var shouldDisplayMeanings: Bool = false
   
    func makeContentView() -> UIView & UIContentView {
        return CardCellContentView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> Self {
        // Same for all states.
        return self
    }
}

class CardCellContentView: UIView, UIContentView {
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    let contentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private var currentConfiguration: CardCellContentConfiguration!
    var configuration: UIContentConfiguration {
        get {
            return currentConfiguration
        }
        set {
            guard let newConfiguration = newValue as? CardCellContentConfiguration else {
                return
            }
            apply(configuration: newConfiguration)
        }
    }
    
    init(configuration: CardCellContentConfiguration) {
        super.init(frame: .zero)
                
        apply(configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateSetups() {
        
    }
    
    private func updateViews() {
        if headerLabel.text != nil {
            addSubview(headerLabel)
        }
        if contentLabel.text != nil {
            addSubview(contentLabel)
        }
    }
    
    private func updateLayouts() {
        if headerLabel.text != nil {
            headerLabel.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(20)
                make.bottom.equalToSuperview().inset(10)
            }
        }
        
        if contentLabel.text != nil {
            contentLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(15)
                make.leading.trailing.equalToSuperview().inset(20)
                make.bottom.equalToSuperview().inset(15)
            }
        }
    }
    
    private func apply(configuration: CardCellContentConfiguration) {

        currentConfiguration = configuration
        
        if let header = configuration.header {
            headerLabel.text = header
            headerLabel.textColor = Colors.weakTextColor
            headerLabel.font = UIFont.systemFont(
                ofSize: headerLabel.font.pointSize,
                weight: .medium
            )
        }
        
        if let lang = configuration.lang,
           var words = configuration.words,
           let meanings = configuration.meanings,
           let pronunciations = configuration.pronunciations,
           var content = configuration.content,
           let contentSource = configuration.contentSource {
                        
            var contentString = "\(LangCode.toFlagIcon(langCode: lang)) "
            if contentSource == .chatgpt {
                contentString += " \(Tokens.chatgptToken) "
            }
            contentString += content
            
            for i in 0 ..< words.count {
                let shouldAddPronunciation = pronunciations[i].normalized(
                    caseInsensitive: true,
                    diacriticInsensitive: false
                ).replacingOccurrences(
                    of: String(Token.accentSymbol),
                    with: ""
                ) != words[i].normalized(
                    caseInsensitive: true,
                    diacriticInsensitive: false
                )
                
                contentString = contentString.replacingOccurrences(
                    of: words[i],
                    with: (
                        shouldAddPronunciation
                        ? "\(words[i]) [\(pronunciations[i])] "
                        : pronunciations[i]
                    ) + (
                        configuration.shouldDisplayMeanings
                        ? " [\(meanings[i])] "
                        : ""
                    ),
                    options: [.caseInsensitive]
                )
                
                if !shouldAddPronunciation {
                    words[i] = pronunciations[i]  // For underlining.
                }
            }
            
            let attributedText = NSMutableAttributedString(string: contentString)
            attributedText.setTextColor(
                for: Tokens.chatgptToken,
                with: Colors.inactiveTextColor
            )
            for i in 0 ..< words.count {
                attributedText.setUnderline(
                    for: words[i],
                    ignoreCasing: true
                )
                attributedText.setTextColor(
                    for: "[\(meanings[i])]",
                    with: Colors.inactiveTextColor
                )
                attributedText.setTextColor(
                    for: "[\(pronunciations[i])]",
                    with: Colors.inactiveTextColor
                )
            }
            contentLabel.attributedText = attributedText
        }
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
}

class CardCell: UICollectionViewListCell {
        
    // https://swiftsenpai.com/development/uicollectionview-list-custom-cell/
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        contentConfiguration = contentConfiguration?.updated(for: state)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
}
