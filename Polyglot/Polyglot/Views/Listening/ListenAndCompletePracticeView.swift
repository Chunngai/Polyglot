//
//  ListenAndCompletePracticeView.swift
//  Polyglot
//
//  Created by Ho on 2/7/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class ListenAndCompletePracticeView: PracticeViewWithNewWordAddingTextView {
    
    var practice: ListeningPracticeProducer.Item!
    
    // MARK: - Init
    
    init(frame: CGRect = .zero, practice: ListeningPracticeProducer.Item) {
        super.init(frame: frame)
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func updateSetups() {
        super.updateSetups()
    }
    
    override func updateViews() {
        super.updateViews()
        
        textView.text = practice.text
    }
}

extension ListenAndCompletePracticeView: ListeningPracticeViewDelegate {
    
    func submit() -> Any {
        return []
    }
    
    func updateViewsAfterSubmission() {
        
    }
}
