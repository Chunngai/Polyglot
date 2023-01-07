//
//  RoundShadowView.swift
//  Polyglot
//
//  Created by Sola on 2022/12/25.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class RoundShadowView: UIView {
    
    // MARK: - Views
    
    lazy var button: RoundButton = RoundButton()
    
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
        layer.shadowColor = RoundShadowView.shadowColor
        layer.shadowOpacity = RoundShadowView.shadowOpacity
        layer.shadowRadius = RoundShadowView.shadowRadius
        layer.shadowOffset = RoundShadowView.shadowOffset
        
        addSubview(button)
    }
    
    private func updateLayouts() {
        button.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.equalTo(button.radius)  // TODO: - Move to RoundButton
            make.height.equalTo(button.radius)  // TODO: - Move to RoundButton
        }
    }

}

extension RoundShadowView {
    
    private static let shadowColor: CGColor = UIColor.gray.cgColor
    private static let shadowOpacity: Float = 0.3
    private static let shadowRadius: CGFloat = 2
    private static let shadowOffset: CGSize = CGSize(width: 3, height: 3)
}
