//
//  ReadingEditTableCell.swift
//  Polyglot
//
//  Created by Sola on 2022/12/21.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class ReadingEditTableCell: UITableViewCell {
        
    // MARK: - Controllers
    
    var delegate: ReadingEditViewController! {
        didSet {
            textView.tableView = delegate.tableView
            textView.promptAttributes = Attributes.promptTextColorAttribute
        }
    }
    
    // MARK: - Views
    
    var textView: AutoResizingTextViewWithPrompt = {
        let textView = AutoResizingTextViewWithPrompt()
        textView.isScrollEnabled = false
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
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.90)
            make.top.bottom.equalToSuperview().inset(5)
        }
    }
    
    func updateValues(prompt: String, text: String?, attributes: [NSAttributedString.Key : Any], textViewTag: Int) {
        
        textView.prompt = prompt
        textView.text = text
        textView.textAttributes = attributes
        textView.tag = textViewTag
    }
    
}
