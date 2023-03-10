//
//  RowStackItem.swift
//  Polyglot
//
//  Created by Sola on 2023/2/15.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class RowStackItem: UIView {

    var bottomLine: Separator = Separator(color: RowStackItem.bottomLineColor)
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
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
        backgroundColor = nil
        
        addSubview(bottomLine)
    }
    
    private func updateLayouts() {
        bottomLine.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalTo(RowStackItem.bottomLineHeight)
            make.bottom.equalToSuperview()
        }
    }
}

extension RowStackItem {
    
    // MARK: - Constants
    
    static let bottomLineColor: UIColor = Colors.lightGrayBackgroundColor
    static let bottomLineHeight: CGFloat = 2
    
}
