//
//  BackgroundView.swift
//  Polyglot
//
//  Created by Sola on 2022/12/29.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class BackgroundView: UIView {
    
    private var backgroundViewTop: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.weakLightBlue
        return view
    }()
    private var backgroundViewBottom: UIImageView = UIImageView(image: UIImage(imageLiteralResourceName: Assets.background))
    
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
        
        addSubview(backgroundViewTop)
        addSubview(backgroundViewBottom)
    }
    
    private func updateLayouts() {
        backgroundViewBottom.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(1.1)
        }
        
        backgroundViewTop.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.bottom.equalTo(backgroundViewBottom.snp.top).offset(2)  // Otherwise there is a white line in between.
        }
    }
    
}
