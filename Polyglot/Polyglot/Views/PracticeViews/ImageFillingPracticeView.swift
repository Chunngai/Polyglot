//
//  ImageFillingPracticeView.swift
//  Polyglot

import UIKit
import NaturalLanguage

class ImageFillingPracticeView: WordPracticeView {

    var answer: String { textField.text!.strip() }

    var delegate: WordsPracticeViewController!

    private var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = Sizes.smallCornerRadius
        iv.clipsToBounds = true
        return iv
    }()

    var textField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont.systemFont(ofSize: Sizes.wordPracticeFontSize)
        tf.textColor = Colors.normalTextColor
        tf.textAlignment = .center
        tf.adjustsFontSizeToFitWidth = true
        tf.minimumFontSize = Sizes.smallFontSize
        return tf
    }()

    private var bottomLine: Separator = Separator()

    private var referenceLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.weakTextColor
        label.font = UIFont.systemFont(ofSize: Sizes.wordPracticeFontSize)
        label.isHidden = true
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))

        addSubview(imageView)
        addSubview(textField)
        addSubview(bottomLine)
        addSubview(referenceLabel)

        bottomLine.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(1)
            make.centerY.equalToSuperview()
        }
        textField.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.bottom.equalTo(bottomLine.snp.top)
        }
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalTo(textField.snp.top).offset(-20)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        referenceLabel.snp.makeConstraints { make in
            make.top.equalTo(bottomLine.snp.bottom).offset(5)
            make.left.equalTo(bottomLine.snp.left)
            make.width.equalTo(bottomLine.snp.width)
        }
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    func updateValues(imageUrl: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let image = UIImage(contentsOfFile: imageUrl) else { return }
            DispatchQueue.main.async { self.imageView.image = image }
        }
    }

    override func submit() -> String {
        textField.text = textField.text?.normalizeQuotes()
        textField.resignFirstResponder()
        textField.isEnabled = false
        return answer
    }

    override func updateViewsAfterSubmission(for correctness: WordPractice.Correctness, key: String, tokenizer: NLTokenizer) {
        let attributedAnswer = NSMutableAttributedString(string: answer)
        let keyComponents = key.normalized(caseInsensitive: true, diacriticInsensitive: true).tokenized(with: tokenizer)
        let answerComponents = answer.normalized(caseInsensitive: true, diacriticInsensitive: true).tokenized(with: tokenizer)
        for keyComponent in keyComponents {
            if answerComponents.contains(keyComponent) {
                attributedAnswer.setTextColor(for: keyComponent, with: Colors.correctColor, ignoreCasing: true, ignoreAccents: true)
            }
        }
        textField.attributedText = attributedAnswer
        if correctness != .correct {
            referenceLabel.isHidden = false
            referenceLabel.text = "\(Strings.referenceLabelPrefix)\(key)"
        }
    }

    @objc private func textFieldEditingChanged() {
        if !(textField.text?.strip().isEmpty ?? true) {
            delegate.activateDoneButton()
        } else {
            delegate.deactivateDoneButton()
        }
    }

    @objc private func tapped() { textField.resignFirstResponder() }
}

extension ImageFillingPracticeView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
}
