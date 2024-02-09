//
//  ClozeViewController.swift
//  Polyglot
//
//  Created by Ho on 2/5/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class ClozeView: UIView, UITextFieldDelegate {
    
    let clozePattern = "___"
    lazy var text: String = "This is an example sentence with a \(clozePattern) and another \(clozePattern)."
    
    var textView: UITextView!
    var clozeFields: [UITextField] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        textView = UITextView(frame: .zero)
        textView.text = text
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.isEditable = false
        textView.isScrollEnabled = true  // TODO: true?
//        textView.backgroundColor = .brown
        addSubview(textView)
        textView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(100)
            make.height.equalToSuperview().inset(100)
            make.leading.trailing.equalToSuperview().inset(30)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Find cloze locations and create text fields
        createClozeFields()
    }

    private func createClozeFields() {
        let attributedString = NSMutableAttributedString(
            string: textView.text,
            attributes: [
                NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18)
            ]
        )
        var range = (textView.text as NSString).range(of: clozePattern)
        while range.location != NSNotFound {
//            attributedString.addAttribute(
//                NSAttributedString.Key.backgroundColor,
//                value: UIColor.orange,
//                range: range
//            )

            if let start = textView.position(from: textView.beginningOfDocument, offset: range.location),
               let end = textView.position(from: start, offset: range.length),
               let textRange = textView.textRange(from: start, to: end) {
                
                let rect = textView.firstRect(for: textRange)
                print("[first rect]", rect)
                let frame = rect.offsetBy(
                    dx: textView.frame.origin.x,
                    dy: textView.frame.origin.y
                )
                print("[frame]", frame)
                
                let clozeField = UITextField(frame: frame)
                clozeField.delegate = self
//                clozeField.backgroundColor = UIColor.green
                clozeField.textAlignment = .left
                clozeField.textColor = .black
//                clozeField.defaultTextAttributes = [
//                    NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18),
//                    NSAttributedString.Key.paragraphStyle : {
//                        let paraStyle = NSMutableParagraphStyle()
//                        paraStyle.lineBreakMode = .byClipping
//                        return paraStyle
//                    }()
//                ]
                addSubview(clozeField)
                clozeFields.append(clozeField)
            }

            let startOffset = range.location + range.length
            let startRange = NSMakeRange(startOffset, textView.text.count - startOffset)
            range = (textView.text as NSString).range(of: clozePattern, options: [], range: startRange)
        }

        textView.attributedText = attributedString
    }
}

class ClozeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let clozeView = ClozeView(frame: self.view.bounds)
        self.view.addSubview(clozeView)
    }
}

