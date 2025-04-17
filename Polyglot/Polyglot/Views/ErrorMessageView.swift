//
//  ErrorMessageView.swift
//  Polyglot
//
//  Created by Ho on 4/17/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import UIKit
import SnapKit

class ErrorMessageView: UIView {
    
    var closeAction: (() -> Void)?
    
    // MARK: - Views
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.lightTextColor
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        return label
    }()
    private let messageLabelBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.lightErrorColor
        view.layer.borderColor = Colors.darkErrorColor.cgColor
        view.layer.borderWidth = 1.0
        view.layer.cornerRadius = Sizes.smallCornerRadius
        view.clipsToBounds = true
        return view
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton()
        button.setTitle(
            "×",
            for: .normal
        )
        button.setTitleColor(
            Colors.lightTextColor,
            for: .normal
        )
        button.titleLabel?.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
        button.backgroundColor = Colors.darkErrorColor.withAlphaComponent(0.7)
        button.layer.cornerRadius = ErrorMessageView.closeButtonRadius // 圆形半径（宽度的一半）
        button.clipsToBounds = true
        return button
    }()
    
    // MARK: - Init
    
    init(message: String) {
        super.init(frame: .zero)
        
        messageLabel.text = message
        
        updateSetups()
        updateViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateSetups() {
        closeButton.addTarget(
            self,
            action: #selector(closeButtonTapped),
            for: .touchUpInside
        )
    }
    
    private func updateViews() {
        
        addSubview(closeButton)
        addSubview(messageLabelBackgroundView)
        bringSubviewToFront(closeButton)
        
        messageLabelBackgroundView.addSubview(messageLabel)
                
        messageLabelBackgroundView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        messageLabel.snp.makeConstraints { make in
            let padding = Self.closeButtonRadius
            make.top.equalToSuperview().offset(padding * 2)
            make.leading.equalToSuperview().offset(padding)
            make.trailing.equalToSuperview().offset(-padding)
            make.bottom.equalToSuperview().offset(-padding)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.trailing.equalToSuperview()
            make.width.height.equalTo(Self.closeButtonRadius * 2)
        }
    }
}

extension ErrorMessageView {
    
    @objc private func closeButtonTapped() {
        closeAction?()
    }
}

extension ErrorMessageView {
    
    static func show(in view: UIView, message: String) -> ErrorMessageView {
        
        let errorView = ErrorMessageView(message: message)
        view.addSubview(errorView)
        
        errorView.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.85)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(100)
        }
        
        errorView.closeAction = {
            errorView.removeFromSuperview()
        }
        
        return errorView
    }
    
}

extension ErrorMessageView {
    
    // MARK: - Constants
    
    static let closeButtonRadius: CGFloat = Sizes.smallCornerRadius
    
}
