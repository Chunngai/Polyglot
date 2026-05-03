//
//  ImageSelectionPracticeView.swift
//  Polyglot

import UIKit
import NaturalLanguage

class ImageSelectionPracticeView: WordPracticeView {

    var delegate: WordsPracticeViewController!

    private var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = Sizes.smallCornerRadius
        iv.clipsToBounds = true
        return iv
    }()

    private var selectionStack: ThreeButtonSelectionStack = ThreeButtonSelectionStack()

    override init(frame: CGRect) {
        super.init(frame: frame)

        selectionStack.delegate = self
        addSubview(imageView)
        addSubview(selectionStack)

        selectionStack.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalTo(selectionStack.snp.top).offset(-20)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    func updateValues(selectionTexts: [String], imageUrl: String) {
        selectionStack.set(texts: selectionTexts)
        DispatchQueue.global(qos: .userInitiated).async {
            guard let image = UIImage(contentsOfFile: imageUrl) else { return }
            DispatchQueue.main.async { self.imageView.image = image }
        }
    }

    override func submit() -> String {
        selectionStack.isSelectionEnabled = false
        return selectionStack.selectedButton!.titleLabel!.text!
    }

    override func updateViewsAfterSubmission(for correctness: WordPractice.Correctness, key: String, tokenizer: NLTokenizer) {
        if correctness == .correct {
            selectionStack.selectedButton!.backgroundColor = Colors.correctColor
        } else {
            selectionStack.selectedButton!.backgroundColor = Colors.incorrectColor
            for button in selectionStack.buttons {
                if button.titleLabel!.text == key {
                    button.backgroundColor = Colors.correctColor
                    break
                }
            }
        }
    }
}

extension ImageSelectionPracticeView: ThreeItemSelectionStackDelegate {
    func buttonSelected(sender: UIButton) {
        selectionStack.selectButton(of: sender.tag)
        delegate.activateDoneButton()
    }
}
