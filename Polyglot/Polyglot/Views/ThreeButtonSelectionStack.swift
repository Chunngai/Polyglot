//
//  ThreeButtonSelectionStack.swift
//  Polyglot
//
//  Created by Sola on 2022/12/20.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class ThreeButtonSelectionStack: UIStackView {

    var isSelectionEnabled: Bool = true {
        didSet {
            if isSelectionEnabled {
                self.isUserInteractionEnabled = true
            } else {
                self.isUserInteractionEnabled = false
            }
        }
    }

    private var selectedButtonIndex: Int!
    var selectedButton: UIButton? {
        guard let selectedButtonIndex = selectedButtonIndex else {
            return nil
        }
        return buttons[selectedButtonIndex]
    }

    private var storedVerbAspectAnnotations: [[VerbAspectAnnotation]] = []
    private var storedNounCaseAnnotations: [[NounCaseAnnotation]] = []
        
    // MARK: - Controllers
    
    var delegate: ThreeItemSelectionStackDelegate! {
        didSet {
            for i in 0..<buttons.count {
                // https://stackoverflow.com/questions/37870701/how-to-use-one-ibaction-for-multiple-buttons-in-swift
                buttons[i].addTarget(
                    self,
                    action: #selector(buttonSelected(sender:)),
                    for: .touchUpInside
                )
            }
        }
    }
    
    // MARK: - Views
    
    var buttons: [UIButton] = {
        var buttons: [UIButton] = []
        for i in 0..<3 {
            buttons.append({
                let button = UIButton()
                button.titleLabel?.textColor = Colors.weakTextColor
                button.titleLabel?.lineBreakMode = .byTruncatingTail
                // https://stackoverflow.com/questions/4865458/dynamically-changing-font-size-of-uilabel
                button.titleLabel?.adjustsFontSizeToFitWidth = true
                button.titleLabel?.minimumScaleFactor = Sizes.minimumScaleFactorForText
                // https://stackoverflow.com/questions/31353302/change-a-uibuttons-text-padding-programmatically-in-swift
                button.titleEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
                button.backgroundColor = Colors.lightBlue
                button.layer.masksToBounds = false
                button.layer.cornerRadius = Sizes.defaultCornerRadius
                button.tag = i
                return button
            }())
        }
        return buttons
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateSetups() {
        for button in buttons {
            addArrangedSubview(button)
        }
    }
    
    private func updateViews() {
        axis = .vertical
        alignment = .center
        distribution = .equalSpacing
        spacing = Sizes.defaultStackSpacing
    }
    
    private func updateLayouts() {
        for i in 0..<buttons.count {
            buttons[i].snp.makeConstraints { (make) in
                make.width.equalToSuperview()
                make.height.equalTo(60)
            }
        }
    }
}

extension ThreeButtonSelectionStack {
    
    // MARK: - Selectors
    
    @objc private func buttonSelected(sender: UIButton) {
        Feedbacks.defaultFeedbackGenerator.selectionChanged()
        delegate.buttonSelected(sender: sender)
    }
    
}

extension ThreeButtonSelectionStack {
    
    func set(texts: [String], verbAspectAnnotations: [[VerbAspectAnnotation]] = [], nounCaseAnnotations: [[NounCaseAnnotation]] = []) {
        storedVerbAspectAnnotations = verbAspectAnnotations
        storedNounCaseAnnotations = nounCaseAnnotations

        for i in 0..<buttons.count {
            let attrStr = NSMutableAttributedString(
                string: texts[i],
                attributes: Attributes.inactiveSelectionButtonTextAttributes
            )
            if !verbAspectAnnotations.isEmpty && i < verbAspectAnnotations.count {
                GrammarAnnotationHelper.applyVerbAspects(verbAspectAnnotations[i], to: attrStr)
            }
            if !nounCaseAnnotations.isEmpty && i < nounCaseAnnotations.count {
                GrammarAnnotationHelper.applyNounCases(nounCaseAnnotations[i], to: attrStr)
            }
            buttons[i].setAttributedTitle(attrStr, for: .normal)
        }
    }
}

extension ThreeButtonSelectionStack {
    
    // MARK: - Utils
    
    func selectButton(of index: Int) {
        selectedButtonIndex = index
        activateButtonsIn(buttonIndices: [selectedButtonIndex], alsoInactivateOthers: true)
    }
    
    // For changing styles between inactive & active.
    
    private func changeStyle(for buttonIndices: [Int], textAttributes: [NSAttributedString.Key : Any], backgroundColor: UIColor) {
        for buttonIndex in buttonIndices {
            let button = buttons[buttonIndex]
            let attrStr = NSMutableAttributedString(string: button.currentAttributedTitle!.string, attributes: textAttributes)
            if buttonIndex < storedVerbAspectAnnotations.count {
                GrammarAnnotationHelper.applyVerbAspects(storedVerbAspectAnnotations[buttonIndex], to: attrStr)
            }
            if buttonIndex < storedNounCaseAnnotations.count {
                GrammarAnnotationHelper.applyNounCases(storedNounCaseAnnotations[buttonIndex], to: attrStr)
            }
            button.setAttributedTitle(attrStr, for: .normal)
            button.backgroundColor = backgroundColor
        }
    }
    
    private func activateButtonsIn(buttonIndices: [Int], alsoInactivateOthers: Bool = true) {
        changeStyle(
            for: buttonIndices,
            textAttributes: Attributes.activeSelectionButtonTextAttributes,
            backgroundColor: Colors.activateSelectionButtonBackgroundColor
        )
        
        if alsoInactivateOthers {
            let otherIndices: [Int] = Array(Set(0..<buttons.count).subtracting(buttonIndices))
            deactivateButtonsIn(
                buttonIndices: otherIndices,
                alsoActivateOthers: false
            )
        }
    }
    
    private func deactivateButtonsIn(buttonIndices: [Int], alsoActivateOthers: Bool = true) {
        changeStyle(
            for: buttonIndices,
            textAttributes: Attributes.inactiveSelectionButtonTextAttributes,
            backgroundColor: Colors.inactivateSelectionButtonBackgroundColor
        )
        
        if alsoActivateOthers {
            let otherIndices: [Int] = Array(Set(0..<buttons.count).subtracting(buttonIndices))
            deactivateButtonsIn(
                buttonIndices: otherIndices,
                alsoActivateOthers: false
            )
        }
    }
}

@objc protocol ThreeItemSelectionStackDelegate {
    
    func buttonSelected(sender: UIButton)
    
}
