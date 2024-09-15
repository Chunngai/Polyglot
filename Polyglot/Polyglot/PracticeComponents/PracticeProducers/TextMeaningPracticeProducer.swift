//
//  TextMeaningPracticeProducer.swift
//  Polyglot
//
//  Created by Ho on 2/17/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation

class TextMeaningPracticeProducer: BasePracticeProducer {
    
    override var currentPractice: BasePractice {
        get {
            if self.practiceList.isEmpty {
                self.practiceList.append(contentsOf: self.make())
            }
            
            return self.practiceList[self.currentPracticeIndex]
        }
        set {
            self.practiceList[self.currentPracticeIndex] = newValue
        }
    }
    
    var groupedArticles: [GroupedArticles]!
    
    var machineTranslator: MachineTranslator = MachineTranslator(
        srcLang: LangCode.currentLanguage,
        trgLang: LangCode.currentLanguage.configs.languageForTranslation
    )
    var contentCreator: ContentCreator = ContentCreator()
    
    private var randomPracticeIndex: Int {
        return (0..<self.practiceList.count).randomElement()!
    }
    private var nextPracticeIndex: Int?  // For immediate reinforcement.
    
    override init(words: [Word], articles: [Article]) {
        super.init(words: words, articles: articles)
        
        self.groupedArticles = articles.groups
    }
    
    override func next() {
        if self.practiceList.isEmpty {
            self.practiceList.append(contentsOf: self.make())
        }
        
        if let nextPracticeIndex = nextPracticeIndex {
            self.currentPracticeIndex = nextPracticeIndex
            self.nextPracticeIndex = nil
        } else {
            self.currentPracticeIndex = randomPracticeIndex
        }
        
        if self.practiceList.count <= batchSize {
            DispatchQueue.global(qos: .userInitiated).async {
                self.practiceList.append(contentsOf: self.make())
            }
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.updateMeaningsAndExistingPhrasesAndAccentLocs()
        }
    }
}

extension TextMeaningPracticeProducer {
    
    func load(_ cachedPractices: [TextMeaningPractice]) {
        if !cachedPractices.isEmpty {
            self.practiceList.append(contentsOf: cachedPractices)
            self.updateMeaningsAndExistingPhrasesAndAccentLocs()
        } else {
            self.practiceList.append(contentsOf: make())
        }
        self.currentPracticeIndex = randomPracticeIndex
    }
    
    @objc
    func cache() {
        fatalError("cache() has not been implemented.")
    }
    
}

extension TextMeaningPracticeProducer {
    
    func updatePracticeRepetitions() {
        if let currentPractice = self.practiceList[self.currentPracticeIndex] as? TextMeaningPractice {
            currentPractice.currentRepetition += 1
            if currentPractice.currentRepetition < currentPractice.totalRepetitions {
                self.practiceList[self.currentPracticeIndex] = currentPractice
            } else {
                self.practiceList.remove(at: self.currentPracticeIndex)
            }
        }
    }
    
    func reinforce() {
        guard let currentPractice = currentPractice as? TextMeaningPractice else {
            return
        }
        currentPractice.totalRepetitions += LangCode.currentLanguage.configs.practiceRepetition
        self.practiceList[self.currentPracticeIndex] = currentPractice
    
        // Immediate reinforcement.
        self.nextPracticeIndex = self.currentPracticeIndex
        
    }
    
}

extension TextMeaningPracticeProducer {
    
    func findExistingPhraseRangesAndMeanings(for text: String, from wordsToSearch: [Word]) -> (
        ranges: [NSRange],
        meanings: [String]
    ) {
        var existingPhraseRanges: [NSRange] = []
        var existingPhraseMeanings: [String] = []
        let text = text.normalized(
            caseInsensitive: true,
            // Both consider je and jo.
            diacriticInsensitive: LangCode.currentLanguage == .ru
        )
        let textTokens = text.tokenized(with: LangCode.currentLanguage.wordTokenizer)
        for word in wordsToSearch {
            let wordText = word.text.normalized(
                caseInsensitive: true,
                diacriticInsensitive: LangCode.currentLanguage == .ru
            )
            if !text.contains(wordText) {
                continue
            }
            // Word boundary check.
            // E.g., wit in with.
            let wordTextTokens = wordText.tokenized(with: LangCode.currentLanguage.wordTokenizer)
            if !textTokens.contains(wordTextTokens) {
                continue
            }
            
            let range = (text as NSString).range(of: wordText)
            existingPhraseRanges.append(range)
            existingPhraseMeanings.append(word.meaning)
        }
        
        return (
            ranges: existingPhraseRanges,
            meanings: existingPhraseMeanings
        )
    }
    
    func maybeTranslate(text: String, meaning: String? = nil, callBack: @escaping (
        String,  // Translated text (meaning).
        Bool,  // isTranslated.
        MachineTranslatorType,  // Translator type.
        String  // Translation query.
    ) -> Void ) {
        
        if let meaning = meaning {
            if LangCode.init(detectedFrom: meaning) == LangCode.currentLanguage.configs.languageForTranslation {
                callBack(
                    meaning,
                    false,
                    MachineTranslatorType.none,
                    text
                )
            } else {
                machineTranslator.translate(query: text) { translations, translatorType in
                    if let translation = translations.first {
                        callBack(
                            "\(translation) (\(meaning))",
                            true,
                            translatorType,
                            text
                        )
                    } else {
                        callBack(
                            meaning,
                            false,
                            MachineTranslatorType.none,
                            text
                        )
                    }
                }
            }
        } else {
            machineTranslator.translate(query: text) { translations, translatorType in
                guard let translation = translations.first else {
                    return
                }
                callBack(
                    translation,
                    true,
                    translatorType,
                    text
                )
            }
        }
    }
    
    func generateTextMeaning(
        randomWord: Word?,
        granularity: TextGranularity,
        machineTranslator: MachineTranslator,
        contentCreator: ContentCreator,
        callBack: @escaping (
            String,  // text
            String,  // meaning
            TextSource,
            Bool,  // isTextMachineTranslated
            MachineTranslatorType  // machineTranslatorType
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
                
                if granularity == .sentence || granularity == .subsentence {
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
            let randomGroup = self.groupedArticles.randomElement()!
            let randomArticle = randomGroup.articles.randomElement()!
            let randomParagraph = randomArticle.paras.randomElement()!
            
            let paragraphText = randomParagraph.text
            let paragraphMeaning = randomParagraph.meaning
            articleId = randomArticle.id
            paragraphId = randomParagraph.id
            
            if granularity == .sentence || granularity == .subsentence {
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
        
        if let text = text {
            let textSource = TextSource.article(
                articleId: articleId!,
                paragraphId: paragraphId!,
                sentenceId: sentenceIndex
            )
            maybeTranslate(
                text: text,
                meaning: meaning  // May be nil.
            ) { updatedMeaning, isTranslated, translatorType, _ in
                callBack(
                    text,
                    updatedMeaning,
                    textSource,
                    isTranslated,
                    translatorType
                )
            }
        } else {
            guard let randomWord = randomWord else {
                return
            }
            if LangCode.currentLanguage.configs.canGenerateTextsWithLLMsForPractices {
                contentCreator.createContent(
                    for: [randomWord.text],
                    inLang: LangCode.currentLanguage,
                    inGranularity: granularity
                ) { content in
                    if let content = content {
                        self.maybeTranslate(text: content) { contentMeaning, isTranslated, translatorType, _ in
                            callBack(
                                content,
                                contentMeaning,
                                TextSource.chatGpt,
                                isTranslated,
                                translatorType
                            )
                        }
                    } else {
                        self.maybeTranslate(
                            text: randomWord.text,
                            meaning: randomWord.meaning
                        ) { updatedMeaning, isTranslated, translatorType, _ in
                            callBack(
                                randomWord.text,
                                updatedMeaning,
                                TextSource.none,
                                isTranslated,
                                translatorType
                            )
                        }
                    }
                }
            } else {
                self.maybeTranslate(
                    text: randomWord.text,
                    meaning: randomWord.meaning
                ) { updatedMeaning, isTranslated, translatorType, _ in
                    callBack(
                        randomWord.text,
                        updatedMeaning,
                        TextSource.none,
                        isTranslated,
                        translatorType
                    )
                }
            }
        }

    }

    func calculateAccentLocsForText(in practice: TextMeaningPractice) {
        
        if !LangCode.currentLanguage.shouldAddAccentMarksToTextInPractices {
            return
        }
        
        analyzeAccents(for: practice.text) { tokens, fixedText, analysisQuery in
            guard !tokens.isEmpty else {
                return
            }
            for practice in self.practiceList {
                guard let practice = practice as? TextMeaningPractice else {
                    continue
                }
                if practice.text == analysisQuery {
                    if let fixedText = fixedText {
                        practice.text = fixedText
                    }
                    practice.textAccentLocs = calculateAccentLocs(
                        for: practice.text,
                        with: tokens
                    )
                    break
                }
            }
        }
    }
 
    func updateMeaningsAndExistingPhrasesAndAccentLocs() {
        
        for practice in self.practiceList {
            guard let practice = practice as? TextMeaningPractice else {
                continue
            }
            
            if practice.meaning.isEmpty {
                self.maybeTranslate(text: practice.text) { translation, isMachineTranslated, translatorType, translationQuery in
                    practice.meaning = translation
                    practice.isTextMachineTranslated = isMachineTranslated
                    practice.machineTranslatorType = translatorType
                }
            }
            
            // In case that some words have been deleted.
            (
                practice.existingPhraseRanges,
                practice.existingPhraseMeanings
            ) = self.findExistingPhraseRangesAndMeanings(
                for: practice.text,
                from: self.words
            )
            
            if practice.textAccentLocs.isEmpty {
                self.calculateAccentLocsForText(in: practice)
            }
        }
        
    }
    
}
