//
//  CardCell.swift
//  Polyglot
//
//  Created by Ho on 9/30/23.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class CardCellContentConfiguration: UIContentConfiguration {
    
    var header: String?
    
    var title: String?
    var content: String?
   
    func makeContentView() -> UIView & UIContentView {
        return CardCellContentView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> Self {
        // Same for all states.
        return self
    }
}

class CardCellContentView: UIView, UIContentView {
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    let contentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private var currentConfiguration: CardCellContentConfiguration!
    var configuration: UIContentConfiguration {
        get {
            return currentConfiguration
        }
        set {
            guard let newConfiguration = newValue as? CardCellContentConfiguration else {
                return
            }
            apply(configuration: newConfiguration)
        }
    }
    
    init(configuration: CardCellContentConfiguration) {
        super.init(frame: .zero)
                
        apply(configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateViews() {
        if headerLabel.text != nil {
            addSubview(headerLabel)
        }
        if titleLabel.text != nil {
            addSubview(titleLabel)
            addSubview(contentLabel)
        }
    }
    
    private func updateLayouts() {
        if headerLabel.text != nil {
            headerLabel.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(20)
                make.bottom.equalToSuperview().inset(10)
            }
        }
        
        if titleLabel.text != nil {
            titleLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(15)
                make.leading.trailing.equalToSuperview().inset(20)
            }
            contentLabel.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(10)
                make.leading.trailing.equalToSuperview().inset(20)
                make.bottom.equalToSuperview().inset(15)
            }
        }
    }
    
    private func apply(configuration: CardCellContentConfiguration) {

        currentConfiguration = configuration
        
        headerLabel.text = configuration.header
        headerLabel.textColor = Colors.weakTextColor
        headerLabel.font = UIFont.systemFont(
            ofSize: headerLabel.font.pointSize,
            weight: .bold
        )
        
        titleLabel.text = configuration.title
        titleLabel.textColor = Colors.normalTextColor
        titleLabel.font = UIFont.systemFont(
            ofSize: titleLabel.font.pointSize,
            weight: .bold
        )
        
        contentLabel.text = configuration.content
        contentLabel.textColor = Colors.normalTextColor
        
        updateViews()
        updateLayouts()
    }
}

class CardCell: UICollectionViewListCell {
        
    // https://swiftsenpai.com/development/uicollectionview-list-custom-cell/
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        contentConfiguration = contentConfiguration?.updated(for: state)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
}

