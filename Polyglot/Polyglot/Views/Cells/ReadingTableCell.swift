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
                )  // Avoid empty lines.
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
        
        addSubview(titleLabel)
        addSubview(bodyLabel)
    }
    
    private func updateLayouts() {
        let padding = titleLabel.font.pointSize
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(padding)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        
        bodyLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(padding / 2)
            make.leading.equalTo(titleLabel.snp.leading)
            make.trailing.equalTo(titleLabel.snp.trailing)
            make.bottom.equalToSuperview().inset(padding)
        }
    }
    
    func updateValues(article: Article) {
        self.article = article
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
