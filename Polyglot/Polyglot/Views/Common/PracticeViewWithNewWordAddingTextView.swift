//
//  PracticeViewWithNewWordAddingTextView.swift
//  Polyglot
//
//  Created by Ho on 2/7/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class PracticeViewWithNewWordAddingTextView: UIView, PracticeViewDelegate {
    
    // MARK: - Views
    
    var mainView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.lightGrayBackgroundColor
        view.layer.masksToBounds = true
        view.layer.cornerRadius = Sizes.defaultCornerRadius
        view.layer.borderWidth = Sizes.defaultBorderWidth
        view.layer.borderColor = Colors.borderColor.cgColor
        return view
    }()
    
    var textView: NewWordAddingTextView!
    
    // MARK: - Init
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        
        textView = NewWordAddingTextView(
            textLang: LangCode.currentLanguage,
            meaningLang: LangCode.pairedLanguage
        )  // TODO: - is it proper to directly pass langs here?
        textView.attributedText = NSMutableAttributedString(
            string: " ",
            attributes: Attributes.leftAlignedLongTextAttributes
        )
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func updateSetups() {
        
    }
    
    func updateViews() {
        addSubview(mainView)
        mainView.addSubview(textView)
    }
    
    func updateLayouts() {
        mainView.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        }
        textView.snp.makeConstraints { (make) in
            let inset = (Attributes.leftAlignedLongTextAttributes[NSAttributedString.Key.font] as! UIFont).pointSize
            make.top.bottom.leading.trailing.equalToSuperview().inset(inset)
        }
    }
}
