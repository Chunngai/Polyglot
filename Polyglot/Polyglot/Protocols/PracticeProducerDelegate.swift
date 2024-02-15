//
//  PracticeProducerDelegate.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

protocol PracticeDelegate {
        
}

protocol PracticeProducerDelegate {
    
    // https://stackoverflow.com/questions/31765806/can-my-class-override-protocol-property-type-in-swift
    
    associatedtype U: PracticeDelegate
    
    var words: [Word] { get set }
    var articles: [Article] { get set }
    
    var practiceList: [U] { get set }
    var currentPracticeIndex: Int { get set }
    var currentPractice: U { get set }
    
    var batchSize: Int { get }

    func make() -> [U]
    mutating func next()
    
}

extension PracticeProducerDelegate {
    
    var currentPractice: U {
        get {
            return practiceList[currentPracticeIndex]
        }
        set {
            practiceList[currentPracticeIndex] = newValue
        }
    }
    
    var batchSize: Int {
        6
    }
    
    mutating func next() {
        currentPracticeIndex += 1
        if currentPracticeIndex >= practiceList.count {
            practiceList.append(contentsOf: make())
        }
    }
    
}

extension PracticeProducerDelegate {
    
    // MARK: - Constants
    
    static var practiceMakingTimeThredshold: TimeInterval {
        5
    }

}

enum TextGranularity: String {
    case sentence
    case paragraph
}

enum TextSource: Codable, Equatable {
    case article(
        articleId: String,
        paragraphId: String,
        sentenceId: Int?
    )
    case chatGpt
}

extension TextSource {
    
    private enum CodingKeys: String, CodingKey {
        case type
        case articleId
        case paragraphId
        case sentenceId
    }
    
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

extension PracticeProducerDelegate {
    
    func findExistingPhraseRangesAndMeanings(for text: String) -> (ranges: [NSRange], meanings: [String]) {
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
        
        return (
            ranges: existingPhraseRanges,
            meanings: existingPhraseMeanings
        )
    }
    
    func generateTextMeaning(
        randomWord: Word?,
        granularity: TextGranularity,
        translator: GoogleTranslator,
        contentCreator: ContentCreator,
        callBack: @escaping (
            String,  // text
            String,  // meaning
            TextSource,
            Bool  // isTextMachineTranslated
        ) -> Void
    ) {
        
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
            callBack(
                text,
                meaning,
                TextSource.article(
                    articleId: articleId!,
                    paragraphId: paragraphId!,
                    sentenceId: sentenceIndex
                ),
                false
            )
        } else if let text = text, meaning == nil {
            translator.translate(query: text) { translations in
                guard let meaning = translations.first else {
                    return
                }
                callBack(
                    text,
                    meaning,
                    TextSource.article(
                        articleId: articleId!,
                        paragraphId: paragraphId!,
                        sentenceId: sentenceIndex
                    ),
                    true
                )
            }
        } else if text == nil && meaning == nil {
            guard let randomWord = randomWord else {
                return
            }
            contentCreator.createContent(
                for: [randomWord.text],
                in: granularity
            ) { content in
                guard let content = content else {
                    return
                }
                translator.translate(
                    query: content
                ) { translations in
                    guard let meaning = translations.first else {
                        return
                    }
                    callBack(
                        content,
                        meaning,
                        TextSource.chatGpt,
                        true
                    )
                }
            }
        }
    }
    
    
}
