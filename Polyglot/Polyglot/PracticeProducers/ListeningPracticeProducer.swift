//
//  ListeningPracticeProducer.swift
//  Polyglot
//
//  Created by Ho on 2/6/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation

class ListeningPracticeProducer: PracticeProducerDelegate {
    
    typealias U = ListeningPracticeProducer.Item
    
    var words: [Word]
    var articles: [Article]
    var batchSize: Int
    
    var practiceList: [ListeningPracticeProducer.Item] = []
    var currentPracticeIndex: Int = 0 {
        didSet {
            if currentPracticeIndex >= practiceList.count {
                practiceList.append(contentsOf: make())
            }
        }
    }
    var currentPractice: ListeningPracticeProducer.Item {
        get {
            return practiceList[currentPracticeIndex]
        }
        set {
            practiceList[currentPracticeIndex] = newValue
        }
    }
    
    init(words: [Word], articles: [Article]) {
        self.words = words
        self.articles = articles
        self.batchSize = self.articles.count >= ListeningPracticeProducer.defaultBatchSize ?
            ListeningPracticeProducer.defaultBatchSize :
            self.articles.count
        
        self.practiceList.append(contentsOf: make())
    }
    
    func make() -> [ListeningPracticeProducer.Item] {
        
        // 0.6 prob: listen and repeat (sentence);
        // 0.2 prob: listen and complete (sentence);
        // 0.1 prob: listen and repeat (paragraph);
        // 0.1 prob: listen and complete (paragraph).
        
        var practiceList: [ListeningPracticeProducer.Item] = []
        while true {
            
//            let p = Double.random(in: 0..<1)
//            if p >= 0 && p < 0.6 {
//                if let listenAndRepeatPractice = makePractice(
//                    of: .listenAndRepeat,
//                    for: self.words.randomElement()!,
//                    callBackWhenTextGeneratedWithContentCreator: { listenAndRepeatPractice in
//                        self.practiceList.append(listenAndRepeatPractice)
//                    }
//                ) {
//                    practiceList.append(listenAndRepeatPractice)
//                }
//            } else if p >= 0.6 && p < 0.8 {
//                if let listenAndCompletePractice = makePractice(
//                    of: .listenAndComplete,
//                    for: self.words.randomElement()!,
//                    callBackWhenTextGeneratedWithContentCreator: { listenAndCompletePractice in
//                        self.practiceList.append(listenAndCompletePractice)
//                    }
//                ) {
//                    practiceList.append(listenAndCompletePractice)
//                }
//            } else if p >= 0.8 && p < 0.9 {
//                if let listenAndRepeatPractice = makePractice(
//                    of: .listenAndRepeat,
//                    callBackWhenTextGeneratedWithContentCreator: { listenAndRepeatPractice in
//                        self.practiceList.append(listenAndRepeatPractice)
//                    }
//                ) {
//                    practiceList.append(listenAndRepeatPractice)
//                }
//            } else if p >= 0.9 && p < 1.0 {
//                if let listenAndCompletePractice = makePractice(
//                    of: .listenAndComplete,
//                    callBackWhenTextGeneratedWithContentCreator: { listenAndCompletePractice in
//                        self.practiceList.append(listenAndCompletePractice)
//                    }
//                ) {
//                    practiceList.append(listenAndCompletePractice)
//                }
//            }
            
//            if let listenAndRepeatPractice = makePractice(
//                of: .listenAndRepeat,
//                for: self.words.randomElement()!,
//                callBackWhenTextGeneratedWithContentCreator: { listenAndRepeatPractice in
//                    self.practiceList.append(listenAndRepeatPractice)
//                }
//            ) {
//                practiceList.append(listenAndRepeatPractice)
//            }
            
            let p = Double.random(in: 0...1)
            if p >= 0 && p < 0.8 {
                if let listenAndRepeatPractice = makePractice(
                    of: .listenAndRepeat,
                    for: self.words.randomElement()!,
                    callBackWhenTextGeneratedWithContentCreator: { listenAndRepeatPractice in
                        self.practiceList.append(listenAndRepeatPractice)
                    }
                ) {
                    practiceList.append(listenAndRepeatPractice)
                }
            } else if p >= 0.8 && p <= 1.0 {
                if let listenAndRepeatPractice = makePractice(
                    of: .listenAndRepeat,
                    callBackWhenTextGeneratedWithContentCreator: { listenAndRepeatPractice in
                        self.practiceList.append(listenAndRepeatPractice)
                    }
                ) {
                    practiceList.append(listenAndRepeatPractice)
                }
            }
            
            if practiceList.count >= ListeningPracticeProducer.defaultBatchSize {
                break
            }
        }
        practiceList.shuffle()

        return practiceList
    }
}

extension ListeningPracticeProducer {
    
    private func makePrompt(for practiceType: ListeningPracticeProducer.Item.PracticeType) -> String {
        switch practiceType {
        case .listenAndRepeat:
            return Strings.listeningAndRepeatPracticePrompt
        case .listenAndComplete:
            return Strings.listenAndCompletePracticePrompt
        }
        
    }
    
    private func generateRanges(for text: String) -> [NSRange] {
                
        var clozeRanges: [NSRange] = []

        // For Japanese and some languages, tokenization is crucial.
        var tokens = text.tokenized(with: LangCode.currentLanguage.wordTokenizer)
        
        var tokenBuffer: String = ""
        var location: Int = 0
        var length: Int = 0
        for (i, character) in text.enumerated() {
            
            if tokenBuffer == tokens[0] {
                clozeRanges.append(NSRange(
                    location: location,
                    length: length
                ))
                tokens.remove(at: 0)
                tokenBuffer = ""
                
//                print(
//                    location,
//                    length,
//                    (text as NSString).substring(with: NSRange(
//                        location: location,
//                        length: length
//                    ))
//                )
            }
            
            if tokens.isEmpty {
                break
            }
            
            if character == tokens[0].first! && tokenBuffer.isEmpty {
                location = i
                length = 1
                tokenBuffer = String(character)
                continue
            }
            
            if tokens[0].starts(with: tokenBuffer + String(character)) {
                tokenBuffer += String(character)
                length += 1
                continue
            }
            
            tokenBuffer = ""
        }

        if !tokenBuffer.isEmpty {
            clozeRanges.append(NSRange(
                location: location,
                length: length
            ))
        }
        
        return clozeRanges
    }
    
    private func makePractice(
        of type: ListeningPracticeProducer.Item.PracticeType,
        for randomWord: Word? = nil,
        callBackWhenTextGeneratedWithContentCreator: @escaping (ListeningPracticeProducer.Item) -> Void
    ) -> ListeningPracticeProducer.Item? {
        
        func makePractice(text: String, meaning: String? = nil, articleId: String? = nil) -> ListeningPracticeProducer.Item {
                        
            var clozeRanges: [NSRange] = generateRanges(for: text)
            if type == .listenAndComplete && clozeRanges.count >= ListeningPracticeProducer.maxClozeNumForListenAndComplete {
                clozeRanges = clozeRanges.randomElements(of: ListeningPracticeProducer.maxClozeNumForListenAndComplete)
            }
            
            return ListeningPracticeProducer.Item(
                type: type,
                prompt: makePrompt(for: type),
                text: text,
                meaning: meaning,
                textLang: LangCode.currentLanguage,
                meaningLang: LangCode.pairedLanguage,
                articleId: articleId,
                clozeRanges: clozeRanges
            )
        }
        
        if let randomWord = randomWord {
            let paraCandidates = self.articles.paraCandidates(for: randomWord.text)
            if paraCandidates.count != 0,
               let paraCandidate = paraCandidates.randomElement(),
               let targetSentence = paraCandidate.text.tokenized(with: LangCode.currentLanguage.sentenceTokenizer).first(where: { sentence in
                   sentence.lowercased().contains(randomWord.text.lowercased())  // Case-insensitive.
               }) {
                return makePractice(
                    text: targetSentence,
                    articleId: paraCandidate.articleId
                )
            } else {
                ContentCreator(lang: LangCode.currentLanguage).createContent(for: [randomWord.text]) { content in
                    guard let content = content else {
                        return
                    }
                    callBackWhenTextGeneratedWithContentCreator(makePractice(
                        text: content
                    ))
                }
                return nil
            }
        } else {
            // Randomly choose a paragraph.
            let randomArticle = self.articles.randomElement()!
            let randomParagraph = randomArticle.paras.randomElement()!
            return makePractice(
                text: randomParagraph.text,
                meaning: randomParagraph.meaning,
                articleId: randomArticle.id
            )
        }
    }
}

extension ListeningPracticeProducer {
    
    func checkCorrectness(of submission: Any) {
        if currentPractice.type == .listenAndRepeat {
            guard let matchedClozeRanges = submission as? [NSRange] else {
                return
            }
            if Double(matchedClozeRanges.count) / Double(currentPractice.clozeRanges.count) <= ListeningPracticeProducer.listenAndRepeatRedoThredshold {
                practiceList.append(Item(from: currentPractice))
            }
        }
    }
    
}

extension ListeningPracticeProducer {
    
    struct Item: PracticeItemDelegate {
        
        enum PracticeType {
            case listenAndRepeat
            case listenAndComplete
        }
        
        var id: UUID
        var type: PracticeType
        var prompt: String
        var text: String
        var meaning: String? = nil
        var textLang: LangCode
        var meaningLang: LangCode
        var articleId: String? = nil  // nil: chatgpt
        var clozeRanges: [NSRange]
        
        init(type: PracticeType, prompt: String, text: String, meaning: String? = nil, textLang: LangCode, meaningLang: LangCode, articleId: String? = nil, clozeRanges: [NSRange]) {
            self.id = UUID()
            self.type = type
            self.prompt = prompt
            self.text = text
            self.meaning = meaning
            self.textLang = textLang
            self.meaningLang = meaningLang
            self.articleId = articleId
            self.clozeRanges = clozeRanges
        }
        
        init(from another: Item) {
            self.init(
                type: another.type,
                prompt: another.prompt,
                text: another.text,
                textLang: another.textLang,
                meaningLang: another.meaningLang,
                clozeRanges: another.clozeRanges
            )
        }
        
    }
    
}

extension ListeningPracticeProducer {
    
    // MARK: - Constants
    
    static let maxClozeNumForListenAndComplete: Int = 10
    static let listenAndRepeatRedoThredshold: Double = 0.6
    
}
