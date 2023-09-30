//
//  LangCell.swift
//  Polyglot
//
//  Created by Ho on 9/30/23.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class LangCellContentConfiguration: UIContentConfiguration {
    
    var langImage: UIImage?
   
    func makeContentView() -> UIView & UIContentView {
        return LangCellContentView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> Self {
        // Same for all states.
        return self
    }
}

class LangCellContentView: UIView, UIContentView {
    
    let langImageView = UIImageView()
    
    private var currentConfiguration: LangCellContentConfiguration!
    var configuration: UIContentConfiguration {
        get {
            return currentConfiguration
        }
        set {
            guard let newConfiguration = newValue as? LangCellContentConfiguration else {
                return
            }
            apply(configuration: newConfiguration)
        }
    }
    
    init(configuration: LangCellContentConfiguration) {
        super.init(frame: .zero)
        
        updateViews()
        updateLayouts()
        
        apply(configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateViews() {
        addSubview(langImageView)
    }
    
    private func updateLayouts() {
        langImageView.snp.makeConstraints { make in
            make.width.height.equalToSuperview().multipliedBy(0.5)
            make.centerX.centerY.equalToSuperview()
        }
    }
    
    private func apply(configuration: LangCellContentConfiguration) {

        currentConfiguration = configuration
        
        langImageView.image = configuration.langImage
    }
}

class LangCell: UICollectionViewCell {
        
    // https://swiftsenpai.com/development/uicollectionview-list-custom-cell/
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        let newConfiguration = LangCellContentConfiguration().updated(for: state)
        newConfiguration.langImage = (contentConfiguration as? LangCellContentConfiguration)?.langImage
        
        contentConfiguration = newConfiguration
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
}

