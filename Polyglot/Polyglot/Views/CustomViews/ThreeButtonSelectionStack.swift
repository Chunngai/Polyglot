//
//  ThreeButtonSelectionStack.swift
//  Polyglot
//
//  Created by Sola on 2022/12/20.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class ThreeButtonSelectionStack: UIStackView {
    
    private var selectionIndex: Int!
    var buttonTags: [Int]!
    
    // MARK: - Controllers
    
    var delegate: ThreeItemSelectionStackDelegate!
    
    // MARK: - Views
    
    var buttons: [UIButton] = {
        var buttons: [UIButton] = []
        for _ in 0..<3 {
            let button = UIButton()
            button.titleLabel?.textColor = Colors.weakTextColor
            button.backgroundColor = Colors.weakLightBlue
            button.layer.masksToBounds = false
            button.layer.cornerRadius = Sizes.defaultCornerRadius
                        
            buttons.append(button)
        }
        return buttons
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        buttonTags = []
        for i in 0..<buttons.count {
            let button = buttons[i]
            
            button.tag = i
            buttonTags.append(i)
            
            // https://stackoverflow.com/questions/37870701/how-to-use-one-ibaction-for-multiple-buttons-in-swift
            button.addTarget(delegate, action: #selector(delegate.buttonSelected(sender:)), for: .touchUpInside)
            
            addArrangedSubview(button)
        }
        
        updateViews()
        updateLayouts()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    func updateValues(buttonTexts: [String], textAttributes: [NSAttributedString.Key : Any] = Attributes.inactiveSelectionButtonTextAttributes) {
        for i in 0..<buttons.count {
            let attributedText = NSAttributedString(
                string: buttonTexts[i],
                attributes: textAttributes
            )
            buttons[i].setAttributedTitle(attributedText, for: .normal)
        }
    }
}

extension ThreeButtonSelectionStack {
    
    // MARK: - Utils
    
    var selectedButton: UIButton? {
        guard let selectionIndex = selectionIndex else {
            return nil
        }
        return buttons[selectionIndex]
    }
    
    func selectButton(of index: Int) {
        selectionIndex = index
        activateButtonsIn(buttonIndices: [selectionIndex], alsoInactivateOthers: true)
    }
    
    // For changing styles between inactive & active.
    
    private func changeStyle(for buttonIndices: [Int], textAttributes: [NSAttributedString.Key : Any], backgroundColor: UIColor) {
        for buttonIndex in buttonIndices {
            let button = buttons[buttonIndex]
            button.setAttributedTitle(
                NSAttributedString(string: button.currentAttributedTitle!.string, attributes: textAttributes),
                for: .normal
            )
            button.backgroundColor = backgroundColor
        }
    }
    
    private func activateButtonsIn(buttonIndices: [Int], alsoInactivateOthers: Bool = true) {
        changeStyle(for: buttonIndices, textAttributes: Attributes.activeSelectionButtonTextAttributes, backgroundColor: Colors.activateSelectionButtonBackgroundColor)
        
        if alsoInactivateOthers {
            let otherIndices: [Int] = Array(Set(0..<buttons.count).subtracting(buttonIndices))
            inactivateButtonsIn(
                buttonIndices: otherIndices,
                alsoActivateOthers: false
            )
        }
    }
    
    private func inactivateButtonsIn(buttonIndices: [Int], alsoActivateOthers: Bool = true) {
        changeStyle(for: buttonIndices, textAttributes: Attributes.inactiveSelectionButtonTextAttributes, backgroundColor: Colors.inactivateSelectionButtonBackgroundColor)
        
        if alsoActivateOthers {
            let otherIndices: [Int] = Array(Set(0..<buttons.count).subtracting(buttonIndices))
            inactivateButtonsIn(
                buttonIndices: otherIndices,
                alsoActivateOthers: false
            )
        }
    }
}

@objc protocol ThreeItemSelectionStackDelegate {
    
    func buttonSelected(sender: UIButton)
    
}
