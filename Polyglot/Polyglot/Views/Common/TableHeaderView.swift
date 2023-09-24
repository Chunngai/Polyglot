//
//  TableHeaderView.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class TableHeaderView: UITableViewHeaderFooterView {
    
    // MARK: - Views
    
    private var mainView: UIView = {
        // [TableView] Setting the background color on UITableViewHeaderFooterView has been deprecated. Please set a custom UIView with your desired background color to the backgroundView property instead.
        
        let view = UIView()
        view.backgroundColor = Colors.lightGrayBackgroundColor
        return view
    }()
    
    private var label: UILabel = {
        let label = UILabel()
        label.backgroundColor = Colors.lightGrayBackgroundColor
        label.textColor = Colors.weakTextColor
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        return label
    }()
    
    // MARK: - Init
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func updateSetups() {
        
    }
    
    private func updateViews() {
        addSubview(mainView)
        mainView.addSubview(label)
    }
    
    private func updateLayouts() {
        let padding = label.font.pointSize
        
        mainView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        label.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(padding / 2)
            make.leading.equalToSuperview().inset(padding * 2)
            make.trailing.equalToSuperview().inset(padding)
        }
    }
    
    func updateValues(text: String) {
        label.text = text.uppercased()
    }
}
