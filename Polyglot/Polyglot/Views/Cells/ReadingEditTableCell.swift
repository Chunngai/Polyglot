//
//  ReadingEditTableCell.swift
//  Polyglot
//
//  Created by Sola on 2022/12/21.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class ReadingEditTableCellTextView: AutoResizingTextViewWithPrompt, TextAnimationDelegate {
    
    var isColorAnimating: Bool = false
    
    var colorAnimationOriginalColor: UIColor = Colors.normalTextColor
    var colorAnimationIntermediateColor: UIColor = Colors.inactiveTextColor
    
}

class ReadingEditTableCell: UITableViewCell {
        
    // MARK: - Controllers
    
    var delegate: ReadingEditViewController! {
        didSet {
            textView.tableViewForHeightAdjustment = delegate.tableView
        }
    }
    
    // MARK: - Views
    
    var textView: ReadingEditTableCellTextView = {
        let textView = ReadingEditTableCellTextView()
        return textView
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
        
//        addSubview(textView)  // Wrong. Results in not being able to edit the cell.
        contentView.addSubview(textView)
    }
    
    private func updateLayouts() {
        textView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.bottom.equalToSuperview()
        }
    }
    
    func updateValues(
        prompt: String,
        text: String?,
        promptAttributes: [NSAttributedString.Key : Any],
        textAttributes: [NSAttributedString.Key : Any],
        textViewTag: Int
    ) {
        
        textView.prompt = prompt
        textView.text = text
        textView.promptAttributes = promptAttributes
        textView.textAttributes = textAttributes
        textView.tag = textViewTag
    }
    
}
