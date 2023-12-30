//
//  CardCell.swift
//  Polyglot
//
//  Created by Ho on 9/30/23.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit
import AVFoundation

class CardCellContentConfiguration: UIContentConfiguration {
    
    var header: String?
    
    var lang: String?
    var words: [String]?
    var meanings: [String]?
    var pronunciations: [String]?
    var content: String?
    var contentSource: String?
    
    var shouldDisplayMeanings: Bool = false
    
    var delegate: CardCellDelegate!
   
    func makeContentView() -> UIView & UIContentView {
        return CardCellContentView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> Self {
        // Same for all states.
        return self
    }
}

class CardCellContentView: UIView, UIContentView {
    
    // MARK: - Views
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    let contentHeader: UIView = UIView()
    let flagIconLabel: UILabel = UILabel()
    let chatgptImageView: UIImageView = UIImageView(image: Icons.chatgptIcon)
    let displayMeaningsButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.systemBlue, for: .normal)
        button.setImage(CardCellContentView.buttonImageWhenNotDisplayingMeanings, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 0)  // https://stackoverflow.com/questions/31873049/how-to-remove-the-top-and-bottom-padding-of-uibutton-when-create-it-using-auto
        return button
    }()
    let textToSpeechButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.systemBlue, for: .normal)
        button.setImage(CardCellContentView.buttonImageWhenNotProducingVoice, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 0)
        return button
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
        displayMeaningsButton.addTarget(self, action: #selector(displayMeanings), for: .touchUpInside)
        textToSpeechButton.addTarget(self, action: #selector(textToSpeech), for: .touchUpInside)
    }
    
    private func updateViews() {
        if headerLabel.text != nil {
            addSubview(headerLabel)
        }
        if contentLabel.text != nil {
            contentHeader.addSubview(flagIconLabel)
            contentHeader.addSubview(chatgptImageView)
            contentHeader.addSubview(displayMeaningsButton)
            contentHeader.addSubview(textToSpeechButton)
            
            addSubview(contentHeader)
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
            contentHeader.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(15)
                make.leading.trailing.equalToSuperview().inset(20)
                make.height.equalTo(displayMeaningsButton.intrinsicContentSize.height)
            }
            flagIconLabel.snp.makeConstraints { make in
                make.leading.equalToSuperview()
                make.top.equalToSuperview()
                make.width.equalTo(flagIconLabel.intrinsicContentSize.width)
            }
            chatgptImageView.snp.makeConstraints { make in
                make.leading.equalTo(flagIconLabel.snp.trailing).offset(5)
                make.top.equalToSuperview()
                make.width.equalTo(contentHeader.snp.height)
                make.height.equalTo(contentHeader.snp.height)
            }
            textToSpeechButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview()
                make.top.equalToSuperview()
                make.width.equalTo(textToSpeechButton.intrinsicContentSize.width)
            }
            displayMeaningsButton.snp.makeConstraints { make in
                make.trailing.equalTo(textToSpeechButton.snp.leading).offset(-5)
                make.top.equalToSuperview()
                make.width.equalTo(displayMeaningsButton.intrinsicContentSize.width)
            }
            
            contentLabel.snp.makeConstraints { make in
                make.top.equalTo(contentHeader.snp.bottom).offset(10)
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
           let content = configuration.content,
           let contentSource = configuration.contentSource {
                        
            flagIconLabel.text = LangCode.toFlagIcon(langCode: lang)
            chatgptImageView.isHidden = contentSource != "chatgpt"
            
            var contentString = content
            
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
            
            // Handle the case when the form of the word is changed.
            // TODO: - Should handle with a better method.
            var hiddenWords: [String] = []  // Words that the forms are changed.
            for word in words {
                if !contentString.contains(word) {
                    hiddenWords.append(word)
                }
            }
            var textOfHiddenWords: String? = nil
            if !hiddenWords.isEmpty {
                textOfHiddenWords = "(\(hiddenWords.joined(separator: "/")))"
                contentString += "\(Strings._wordSeparators[lang]!)\(textOfHiddenWords!)"
            }

            let attributedText = NSMutableAttributedString(string: contentString)
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
            if let textOfHiddenWords = textOfHiddenWords {
                attributedText.setTextColor(
                    for: textOfHiddenWords,
                    with: Colors.inactiveTextColor
                )
                // Remove the underline added with the code above.
                attributedText.removeUnderline(for: textOfHiddenWords)
            }
            contentLabel.attributedText = attributedText
        }
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
}

extension CardCellContentView {
    
    // MARK: - Selectors
    
    @objc
    private func displayMeanings() {
        Feedbacks.defaultFeedbackGenerator.selectionChanged()
        guard let config = configuration as? CardCellContentConfiguration else {
            return
        }
        
        config.shouldDisplayMeanings.toggle()
        configuration = config
        
        config.delegate.updateCellHeight()
        
        if config.shouldDisplayMeanings {
            displayMeaningsButton.setImage(CardCellContentView.buttonImageWhenDisplayingMeanings, for: .normal)
        } else {
            displayMeaningsButton.setImage(CardCellContentView.buttonImageWhenNotDisplayingMeanings, for: .normal)
        }
    }
    
    @objc
    private func textToSpeech() {
        Feedbacks.defaultFeedbackGenerator.selectionChanged()
        guard let config = configuration as? CardCellContentConfiguration else {
            return
        }
        
        guard let lang = config.lang else {
            return
        }
        guard let content = config.content else {
            return
        }
        
        if textToSpeechButton.imageView?.image == CardCellContentView.buttonImageWhenNotProducingVoice {  // Not producing speech.
            
            // Stop the current speech (of another cell).
            if config.delegate.activeTextToSpeechButton != nil {
                
                // Re-create one. If stopping the synthesizer instead of
                // the re-creation, the speechSynthesizer(_ synthesizer:didFinish utterance:) delegate method will be executed twice,
                // once from synthesizer.stopSpeaking() and once from the finishing of synthesizer.speak(),
                // producing strange behaviours.
                config.delegate.synthesizer = AVSpeechSynthesizer()
                config.delegate.synthesizer.delegate = config.delegate as! AVSpeechSynthesizerDelegate
                
                config.delegate.activeTextToSpeechButton?.setImage(CardCellContentView.buttonImageWhenNotProducingVoice, for: .normal)
                config.delegate.activeTextToSpeechButton = nil
            }
            
            let utterance = AVSpeechUtterance(string: content)
            utterance.voice = AVSpeechSynthesisVoice(identifier: LangCode.toVoiceIdentifier(langCode: lang))
            config.delegate.synthesizer.speak(utterance)
            
            textToSpeechButton.setImage(CardCellContentView.buttonImageWhenProducingVoice, for: .normal)
            config.delegate.activeTextToSpeechButton = self.textToSpeechButton
        } else {  // Producing speech.
            config.delegate.synthesizer.stopSpeaking(at: .immediate)
            
            // May be redundant, as the speechSynthesizer(_ synthesizer:didFinish utterance:) delegate method
            // in the delegate class will be executed after
            // `config.delegate.synthesizer.stopSpeaking(at: .immediate)`.
            textToSpeechButton.setImage(CardCellContentView.buttonImageWhenNotProducingVoice, for: .normal)
            config.delegate.activeTextToSpeechButton = nil
        }
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

protocol CardCellDelegate {
    
    var synthesizer: AVSpeechSynthesizer { get set }
    var activeTextToSpeechButton: UIButton? { get set }
    
    func updateCellHeight()
    
}

extension CardCellContentView {
    
    // MARK: - Constants
    
    static let buttonImageWhenDisplayingMeanings: UIImage = UIImage(systemName: "questionmark.app.fill")!
    static let buttonImageWhenNotDisplayingMeanings: UIImage = UIImage(systemName: "questionmark.app")!
    
    static let buttonImageWhenProducingVoice: UIImage = UIImage(systemName: "waveform.circle.fill")!
    static let buttonImageWhenNotProducingVoice: UIImage = UIImage(systemName: "waveform.circle")!
    
}
