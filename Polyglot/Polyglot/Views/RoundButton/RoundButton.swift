//
//  RoundButton.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class RoundButton: UIButton {
    
    var radius: CGFloat = RoundButton.defaultRadius
        
    // MARK: - Init
    
    init(frame: CGRect = .zero, radius: CGFloat) {
        super.init(frame: frame)
        
        self.radius = radius
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
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
        // https://stackoverflow.com/questions/26050655/how-to-create-a-circular-button-in-swift
        layer.cornerRadius = 0.5 * radius
        clipsToBounds = true
    }
    
    private func updateLayouts() {
        
    }
    
}

extension RoundButton {
    
    // MARK: - Constants
    
    private static let defaultRadius: CGFloat = 65
}
