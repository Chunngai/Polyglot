//
//  ReadingTableCell.swift
//  Polyglot
//
//  Created by Sola on 2022/12/21.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class ReadingTableCell: UITableViewCell {

    // MARK: - Models
    
    var article: Article! {
        didSet {
            titleLabel.attributedText = {

                let attrText = NSMutableAttributedString(string: "")

                if article.isYoutubeVideo {
                    attrText.append(NSAttributedString.imageAttributedString(
                        icon: Icons.youtubeIcon,
                        font: (Self.titleLabelAttributes[.font] as! UIFont)
                    ))
                    attrText.append(NSAttributedString(string: "  "))
                }

                attrText.append(NSAttributedString(string: article.title))

                attrText.addAttributes(
                    Self.titleLabelAttributes,
                    range: NSRange(
                        location: 0,
                        length: attrText.length
                    )
                )

                return attrText

            }()
            bodyLabel.text = article.body
                .replacingOccurrences(
                    of: "\n\n",
                    with: "\n"
                )
        }
    }

    var onProgressTapped: (() -> Void)?

    var progressText: String? {
        didSet {
            progressLabel.text = progressText
            let hasProgress = progressText != nil
            progressLabel.isHidden = !hasProgress
            let padding = titleLabel.font.pointSize
            titleLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().inset(padding)
                make.leading.equalToSuperview().inset(padding)
                if hasProgress {
                    make.trailing.equalTo(progressLabel.snp.leading).offset(-8)
                } else {
                    make.trailing.equalToSuperview().inset(padding)
                }
            }
        }
    }
    
    // MARK: - Views
    
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = Colors.defaultBackgroundColor
        label.textColor = Colors.normalTextColor
        label.lineBreakMode = .byTruncatingTail
        label.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        return label
    }()

    private var bodyLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = Colors.defaultBackgroundColor
        label.textColor = Colors.weakTextColor
        label.numberOfLines = ReadingTableCell.bodyLabelNumberOfLines
        label.lineBreakMode = .byTruncatingTail
        label.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        return label
    }()

    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        label.textAlignment = .right
        label.isHidden = true
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(progressLabelTapped)))
        return label
    }()
    
    // MARK: - Init
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    private func updateSetups() {

    }

    private func updateViews() {
        selectionStyle = .none

        contentView.addSubview(progressLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)
    }

    private func updateLayouts() {
        let padding = titleLabel.font.pointSize

        progressLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(padding)
            make.trailing.equalToSuperview().inset(padding)
            make.width.equalTo(70)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(padding)
            make.leading.equalToSuperview().inset(padding)
            make.trailing.equalToSuperview().inset(padding)
        }

        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(padding / 2)
            make.leading.equalTo(titleLabel.snp.leading)
            make.trailing.equalToSuperview().inset(padding)
            make.bottom.equalToSuperview().inset(padding)
        }
    }

    @objc private func progressLabelTapped() {
        onProgressTapped?()
    }

    func updateValues(article: Article, progressText: String? = nil) {
        self.article = article
        self.progressText = progressText
    }
}

extension ReadingTableCell {
    
    // MARK: - Constants
    
    private static let bodyLabelNumberOfLines: Int = 2
    
    private static let titleLabelAttributes: [NSAttributedString.Key : Any] = [
        .backgroundColor : Colors.defaultBackgroundColor,
        .foregroundColor : Colors.normalTextColor,
        .font : UIFont.systemFont(ofSize: Sizes.smallFontSize)
    ]
    
}
