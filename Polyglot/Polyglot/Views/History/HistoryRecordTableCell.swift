////
////  HistoryRecordTableCell.swift
////  Polyglot
////
////  Created by Sola on 2022/12/29.
////  Copyright © 2022 Sola. All rights reserved.
////
//
//import UIKit
//
//class HistoryRecordTableCell: UITableViewCell {
//    
//    // MARK: - Views
//    
//    private var practiceTypeLabel: UILabel = {
//        let label = UILabel()
//        label.backgroundColor = Colors.defaultBackgroundColor
//        label.textColor = Colors.defaultTextColor
////        label.lineBreakMode = .byTruncatingTail
//        label.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
//        return label
//    }()
//    
//    private var practiceContentLabel: UILabel = {
//        let label = UILabel()
//        label.backgroundColor = Colors.defaultBackgroundColor
//        label.textColor = Colors.weakTextColor
//        label.lineBreakMode = .byTruncatingTail
//        label.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
//        label.textAlignment = .left
//        label.numberOfLines = 2  // TODO: - Should update?
//        return label
//    }()
//    
//    private var correctnessView: UIView = {
//        let view = UIView()
//        view.layer.masksToBounds = true
//        view.layer.cornerRadius = Sizes.smallCornerRadius
//        return view
//    }()
//    
//    // MARK: - Init
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//    }
//    
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        
//        updateSetups()
//        updateViews()
//    }
//    
//    private func updateSetups() {
//        
//    }
//    
//    private func updateViews() {
//        selectionStyle = .none
//        
//        addSubview(practiceTypeLabel)
//        addSubview(practiceContentLabel)
//        addSubview(correctnessView)
//    }
//    
//    private func updateLayouts() {
//        let padding = practiceTypeLabel.font.pointSize
//        
//        practiceTypeLabel.snp.makeConstraints { (make) in
////            make.top.equalToSuperview().inset(padding)
//            make.leading.equalToSuperview().inset(padding)
//            make.centerY.equalToSuperview()
//            // Needed to specify the width explicitly.
//            // Otherwise the width is ambiguous,
//            // and the location of the content label cannot be determined.
////            make.width.equalTo(practiceTypeLabel.intrinsicContentSize.width + 5)
//        }
//        
//        correctnessView.snp.makeConstraints { (make) in
//            make.trailing.equalToSuperview().inset(padding)
//            make.width.equalTo(30)
//            make.height.equalTo(20)
//            make.centerY.equalToSuperview()
//        }
//        
//        practiceContentLabel.snp.makeConstraints { (make) in
//            make.top.equalTo(practiceTypeLabel.snp.top)
//            make.leading.equalTo(practiceTypeLabel.snp.trailing).offset(padding)
//            make.trailing.equalTo(correctnessView.snp.leading).offset(-padding)
//            make.centerY.equalToSuperview()
//        }
//    }
//    
//    func updateValues(practiceType: String, practiceContent: String, correctness: WordPractice.Correctness?) {
//        practiceTypeLabel.text = practiceType
//        practiceContentLabel.text = practiceContent
//        
//        if let correctness = correctness {
//            if correctness == .correct {
//                correctnessView.backgroundColor = Colors.lightCorrectColor
//            } else if correctness == .incorrect {
//                correctnessView.backgroundColor = Colors.lightInorrectColor
//            } else if correctness == .partiallyCorrect {
//                // TODO: - update here.
//            }
//        } else {
//            correctnessView.backgroundColor = superview?.backgroundColor
//        }
//        
//        // Have to update the layouts here.
//        // If the layouts are set in the init method,
//        // the practiceTypeLabel.intrinsicContentSize.width is not known yet.
//        updateLayouts()
//    }
//}
