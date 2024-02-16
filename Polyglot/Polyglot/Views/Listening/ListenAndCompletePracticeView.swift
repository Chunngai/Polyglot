//
//  ListenAndCompletePracticeView.swift
//  Polyglot
//
//  Created by Ho on 2/7/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class ListenAndCompletePracticeView: TextMeaningPracticeView {
        
    // MARK: - Init
    
    override init(
        frame: CGRect = .zero,
        text: String,
        meaning: String,
        textLang: LangCode,
        meaningLang: LangCode,
        textSource: TextSource,
        isTextMachineTranslated: Bool,
        existingPhraseRanges: [NSRange],
        existingPhraseMeanings: [String]
    ) {
        super.init(
            frame: frame,
            text: text,
            meaning: meaning,
            textLang: textLang,
            meaningLang: meaningLang,
            textSource: textSource,
            isTextMachineTranslated: isTextMachineTranslated,
            existingPhraseRanges: existingPhraseRanges,
            existingPhraseMeanings: existingPhraseMeanings
        )
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}

extension ListenAndCompletePracticeView: ListeningPracticeViewDelegate {
    
    func submit() -> Any {
        return []
    }
    
    func updateViewsAfterSubmission() {
        
    }
}
