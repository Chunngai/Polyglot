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
    
    var translator: GoogleTranslator = GoogleTranslator(
        srcLang: LangCode.currentLanguage,
        trgLang: LangCode.pairedLanguage
    )
    var contentGenerator: ContentCreator = ContentCreator(lang: LangCode.currentLanguage)
    
    init(words: [Word], articles: [Article]) {
        self.words = words
        self.articles = articles
        self.batchSize = self.articles.count >= ListeningPracticeProducer.defaultBatchSize ?
            ListeningPracticeProducer.defaultBatchSize :
            self.articles.count
        
        let cachedListeningPractices = ListeningPracticeProducer.loadCachedPractices(for: LangCode.currentLanguage)
        if !cachedListeningPractices.isEmpty {
            self.practiceList.append(contentsOf: cachedListeningPractices)
        } else {
            self.practiceList.append(contentsOf: make())
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Create new cached practices for the use of next time.
            var listeningPracticesToCache = self.make()
            
            // Save the newly created ones.
            ListeningPracticeProducer.save(
                &listeningPracticesToCache,
                for: LangCode.currentLanguage
            )
        }
    }
    
    func make() -> [ListeningPracticeProducer.Item] {
        
        var practiceList: [ListeningPracticeProducer.Item] = []
        while true {
            
            let p = Double.random(in: 0...1)
            if p >= 0 && p < 0.45 {  // 45%.
                if let listenAndRepeatPractice = makePractice(
                    ofType: .listenAndRepeat,
                    for: self.words.randomElement()!,
                    inGranularity: TextGranularity.sentence,
                    callBack: { listenAndRepeatPractice in
                        practiceList.append(listenAndRepeatPractice)
                    }
                ) {
                    practiceList.append(listenAndRepeatPractice)
                }
            } else if p >= 0.45 && p < 0.9 {  // 45%
                if let listenAndRepeatPractice = makePractice(
                    ofType: .listenAndRepeat,
                    inGranularity: TextGranularity.sentence,
                    callBack: { listenAndRepeatPractice in
                        practiceList.append(listenAndRepeatPractice)
                    }
                ) {
                    practiceList.append(listenAndRepeatPractice)
                }
            } else if p >= 0.9 && p <= 1.0 {  // 10%
                if let listenAndRepeatPractice = makePractice(
                    ofType: .listenAndRepeat,
                    inGranularity: TextGranularity.paragraph,
                    callBack: { listenAndRepeatPractice in
                        practiceList.append(listenAndRepeatPractice)
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
        guard !tokens.isEmpty else {
            return []
        }
        
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
        ofType type: ListeningPracticeProducer.Item.PracticeType,
        for randomWord: Word? = nil,
        inGranularity granularity: TextGranularity,
        callBack: @escaping (ListeningPracticeProducer.Item) -> Void
    ) -> ListeningPracticeProducer.Item? {
        
        func makePractice(text: String, meaning: String, textSource: Item.TextSource, isTextMachineTranslated: Bool) -> ListeningPracticeProducer.Item? {
                        
            var clozeRanges: [NSRange] = generateRanges(for: text)
            if clozeRanges.isEmpty {
                return nil
            }
            if type == .listenAndComplete && clozeRanges.count >= ListeningPracticeProducer.maxClozeNumForListenAndComplete {
                clozeRanges = clozeRanges.randomElements(of: ListeningPracticeProducer.maxClozeNumForListenAndComplete)
            }
            
            var existingPhraseRanges: [NSRange] = []
            var existingPhraseMeanings: [String] = []
            let textUniqueTokens = Set(text.tokenized(with: LangCode.currentLanguage.wordTokenizer))
            for word in self.words {
                let wordUniqueTokens = Set(word.text.tokenized(with: LangCode.currentLanguage.wordTokenizer))
                if !textUniqueTokens.intersection(wordUniqueTokens).isEmpty  // Avoid cases like "wit" in "with".
                    && text.contains(word.text) {
                    let range = (text as NSString).range(of: word.text)
                    existingPhraseRanges.append(range)
                    existingPhraseMeanings.append(word.meaning)
                }
            }
            
            return ListeningPracticeProducer.Item(
                type: type,
                prompt: makePrompt(for: type),
                text: text,
                meaning: meaning,
                textLang: LangCode.currentLanguage,
                meaningLang: LangCode.pairedLanguage,
                textSource: textSource,
                isTextMachineTranslated: isTextMachineTranslated,
                clozeRanges: clozeRanges,
                existingPhraseRanges: existingPhraseRanges,
                existingPhraseMeanings: existingPhraseMeanings
            )
        }
        
        var text: String?
        var meaning: String?
        var articleId: String?
        var paragraphId: String?
        var sentenceIndex: Int?
        
        if let randomWord = randomWord {
            let paraCandidates = self.articles.paraCandidates(for: randomWord.text)
            if paraCandidates.count != 0, let paraCandidate = paraCandidates.randomElement() {
                let paragraphText = paraCandidate.text
                let paragraphMeaning = paraCandidate.meaning
                articleId = paraCandidate.articleId
                paragraphId = paraCandidate.paraId
                
                if granularity == .sentence {
                    let sentences = paragraphText.tokenized(with: LangCode.currentLanguage.sentenceTokenizer)
                    if sentences.count == 1 {
                        text = paragraphText
                        meaning = paragraphMeaning
                    } else {
                        let matchedSentenceIndex = sentences.firstIndex { sentence in
                            sentence.lowercased().contains(randomWord.text.lowercased())
                        }
                        sentenceIndex = matchedSentenceIndex
                        text = sentences[matchedSentenceIndex!]
                    }
                } else {
                    text = paragraphText
                    meaning = paragraphMeaning
                }
            }
        } else {
            let randomArticle = self.articles.randomElement()!
            let randomParagraph = randomArticle.paras.randomElement()!
            
            let paragraphText = randomParagraph.text
            let paragraphMeaning = randomParagraph.meaning
            articleId = randomArticle.id
            paragraphId = randomParagraph.id
            
            if granularity == .sentence {
                let sentences = paragraphText.tokenized(with: LangCode.currentLanguage.sentenceTokenizer)
                if sentences.count == 1 {
                    text = paragraphText
                    meaning = paragraphMeaning
                } else {
                    sentenceIndex = Int.random(in: 0..<sentences.count)
                    text = sentences[sentenceIndex!]
                }
            } else {
                text = paragraphText
                meaning = paragraphMeaning
            }
        }
        
        if let text = text, let meaning = meaning {
            return makePractice(
                text: text,
                meaning: meaning,
                textSource: Item.TextSource.article(
                    articleId: articleId!,
                    paragraphId: paragraphId!,
                    sentenceId: sentenceIndex
                ),
                isTextMachineTranslated: false
            )
        } else if let text = text, meaning == nil {
            translator.translate(query: text) { translations in
                guard let meaning = translations.first else {
                    return
                }
                guard let practice = makePractice(
                    text: text,
                    meaning: meaning,
                    textSource: Item.TextSource.article(
                        articleId: articleId!,
                        paragraphId: paragraphId!,
                        sentenceId: sentenceIndex
                    ),
                    isTextMachineTranslated: true
                ) else {
                    return
                }
                callBack(practice)
            }
        } else if text == nil && meaning == nil {
            guard let randomWord = randomWord else {
                return nil
            }
            contentGenerator.createContent(
                for: [randomWord.text],
                in: granularity
            ) { content in
                guard let content = content else {
                    return
                }
                self.translator.translate(
                    query: content
                ) { translations in
                    guard let meaning = translations.first else {
                        return
                    }
                    guard let practice = makePractice(
                        text: content,
                        meaning: meaning,
                        textSource: Item.TextSource.chatGpt,
                        isTextMachineTranslated: true
                    ) else {
                        return
                    }
                    callBack(practice)
                }
            }
        }
        
        // Should not reach here.
        return nil
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
    
    struct Item: PracticeItemDelegate, Codable {
        
        enum PracticeType: String, Codable {
            case listenAndRepeat
            case listenAndComplete
        }
        
        enum TextSource: Codable {
            case article(
                articleId: String,
                paragraphId: String,
                sentenceId: Int?
            )
            case chatGpt
        }
        
        var id: UUID
        var type: PracticeType
        var prompt: String
        var text: String
        var meaning: String
        var textLang: LangCode
        var meaningLang: LangCode
        var textSource: TextSource
        var isTextMachineTranslated: Bool
        var clozeRanges: [NSRange]
        var existingPhraseRanges: [NSRange]
        var existingPhraseMeanings: [String]
        
        init(type: PracticeType, prompt: String, text: String, meaning: String, textLang: LangCode, meaningLang: LangCode, textSource: TextSource, isTextMachineTranslated: Bool, clozeRanges: [NSRange], existingPhraseRanges: [NSRange], existingPhraseMeanings: [String]) {
            self.id = UUID()
            self.type = type
            self.prompt = prompt
            self.text = text
            self.meaning = meaning
            self.textLang = textLang
            self.meaningLang = meaningLang
            self.textSource = textSource
            self.isTextMachineTranslated = isTextMachineTranslated
            self.clozeRanges = clozeRanges
            self.existingPhraseRanges = existingPhraseRanges
            self.existingPhraseMeanings = existingPhraseMeanings
        }
        
        init(from another: Item) {
            self.init(
                type: another.type,
                prompt: another.prompt,
                text: another.text,
                meaning: another.meaning,
                textLang: another.textLang,
                meaningLang: another.meaningLang,
                textSource: another.textSource,
                isTextMachineTranslated: another.isTextMachineTranslated,
                clozeRanges: another.clozeRanges,
                existingPhraseRanges: another.existingPhraseRanges,
                existingPhraseMeanings: another.existingPhraseMeanings
            )
        }
        
    }
}

extension ListeningPracticeProducer.Item.TextSource {
    
    private enum CodingKeys: String, CodingKey {
        case type
        case articleId
        case paragraphId
        case sentenceId
    }
    
    // Custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .article(let articleId, let paragraphId, let sentenceId):
            try container.encode("article", forKey: .type)
            try container.encode(articleId, forKey: .articleId)
            try container.encode(paragraphId, forKey: .paragraphId)
            try container.encode(sentenceId, forKey: .sentenceId)
        case .chatGpt:
            try container.encode("chatGpt", forKey: .type)
        }
    }
    
    // Custom decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "article":
            let articleId = try container.decode(String.self, forKey: .articleId)
            let paragraphId = try container.decode(String.self, forKey: .paragraphId)
            let sentenceId = try container.decode(Int?.self, forKey: .sentenceId)
            self = .article(
                articleId: articleId,
                paragraphId: paragraphId,
                sentenceId: sentenceId
            )
        case "chatGpt":
            self = .chatGpt
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type")
        }
    }
    
}

extension ListeningPracticeProducer.Item {
    
    private struct CodableRange: Codable {
        var location: Int
        var length: Int
        
        init(from range: NSRange) {
            self.location = range.location
            self.length = range.length
        }
        
        var nsRange: NSRange {
            return NSRange(location: self.location, length: self.length)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, type, prompt, text, meaning, textLang, meaningLang, textSource, isTextMachineTranslated, clozeRanges, existingPhraseRanges, existingPhraseMeanings
    }
    
    // Custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(prompt, forKey: .prompt)
        try container.encode(text, forKey: .text)
        try container.encode(meaning, forKey: .meaning)
        try container.encode(textLang, forKey: .textLang)
        try container.encode(meaningLang, forKey: .meaningLang)
        try container.encode(textSource, forKey: .textSource)
        try container.encode(isTextMachineTranslated, forKey: .isTextMachineTranslated)
        let codableClozeRanges = clozeRanges.map(CodableRange.init(from:))
        try container.encode(codableClozeRanges, forKey: .clozeRanges)
        let codableExistingPhraseRanges = existingPhraseRanges.map(CodableRange.init(from:))
        try container.encode(codableExistingPhraseRanges, forKey: .existingPhraseRanges)
        try container.encode(existingPhraseMeanings, forKey: .existingPhraseMeanings)
    }
    
    // Custom decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(PracticeType.self, forKey: .type)
        prompt = try container.decode(String.self, forKey: .prompt)
        text = try container.decode(String.self, forKey: .text)
        meaning = try container.decode(String.self, forKey: .meaning)
        textLang = try container.decode(LangCode.self, forKey: .textLang)
        meaningLang = try container.decode(LangCode.self, forKey: .meaningLang)
        textSource = try container.decode(TextSource.self, forKey: .textSource)
        isTextMachineTranslated = try container.decode(Bool.self, forKey: .isTextMachineTranslated)
        let codableClozeRanges = try container.decode([CodableRange].self, forKey: .clozeRanges)
        clozeRanges = codableClozeRanges.map { $0.nsRange }
        let codableExistingPhraseRanges = try container.decode([CodableRange].self, forKey: .existingPhraseRanges)
        existingPhraseRanges = codableExistingPhraseRanges.map { $0.nsRange }
        existingPhraseMeanings = try container.decode([String].self, forKey: .existingPhraseMeanings)
    }
    
}

extension ListeningPracticeProducer {
    
    // MARK: - IO
    
    static func fileName(for lang: String) -> String {
        return "cachedListeningPractices.\(lang).json"
    }
    
    static func loadCachedPractices(for lang: LangCode) -> [Item] {
        do {
            let practices = try readDataFromJson(
                fileName: ListeningPracticeProducer.fileName(for: lang.rawValue),
                type: [ListeningPracticeProducer.Item].self
            ) as? [ListeningPracticeProducer.Item] ?? []
            return practices
        } catch {
            return []
        }
    }
    
    static func save(_ practicesToCache: inout [ListeningPracticeProducer.Item], for lang: LangCode) {
        do {
            try writeDataToJson(
                fileName: ListeningPracticeProducer.fileName(for: lang.rawValue),
                data: practicesToCache
            )
        } catch {
            print(error.localizedDescription)
        }
    }
    
}

extension ListeningPracticeProducer {
    
    // MARK: - Constants
    
    static let maxClozeNumForListenAndComplete: Int = 10
    static let listenAndRepeatRedoThredshold: Double = 0.6
    
}
