//
//  ContextSelectionPracticeView.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class ContextSelectionPracticeView: UIView {

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
        
    }
    
    private func updateLayouts() {
        
    }
    
}

extension ContextSelectionPracticeView: PracticeDelegate {
    
    // MARK: - Practice Delegate
    
    func check() -> Any {
        return ""
    }
}
