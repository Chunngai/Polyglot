//
//  HistoryExtensions.swift
//  Polyglot
//
//  Created by Sola on 2022/12/29.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation

extension HistoryRecord {
    
    var groupIdentifier: String {
        return creationDate.repr()
    }
    
    var practiceType: String {
        if let wordPractice = practice as? WordPractice {
            switch wordPractice.type {
            case .meaningSelection:
                return Strings.meaningSelectionPractice
            case .meaningFilling:
                return Strings.meaningFillingPractice
            case .contextSelection:
                return Strings.contextSelectionPractice
            }
        } else if practice is ReadingPractice {
            return Strings.readingPractice
        } else if practice is TranslationPractice {
            return Strings.translationPractice
        } else {
            return ""
        }
    }
    
    // TODO: - update here.
    var practiceContent: String {
        
        if let wordPractice = practice as? WordPractice {
            
            // TODO: - Update "samples".
            // Obtain the word to practice.
            guard let wordToPractice = Word.load().getWord(from: wordPractice.wordId) else {  // TODO: - load()
                print(wordPractice.wordId)
                return ""
            }
            
            let wordToPracticeString: String!
            if wordPractice.direction == 0 {
                wordToPracticeString = wordToPractice.text
            } else {
                wordToPracticeString = wordToPractice.meaning
            }
            
            switch wordPractice.type {
            case .meaningSelection:
                
                var content: String = "\(wordToPracticeString!) -\n"
                
                // Obtain selection words.
                var selectionWords: [Word?] = []
                for wordId in wordPractice.selectionWordsIds! {
                    selectionWords.append(Word.load().getWord(from: wordId))  // TODO: - load()
                }
            
                for selectionWord in selectionWords {
                    if selectionWord == nil {
                        content += ""
                    }
                    
                    if wordPractice.direction == 0 {
                        content += "\(selectionWord!.meaning)/"
                    } else {
                        content += "\(selectionWord!.text)/"
                    }
                    
                    if wordPractice.correctness == .incorrect {
                        if selectionWord!.id == wordPractice.wordId {
                            content += "✓"
                        }
                        if selectionWord!.id == wordPractice.selectedWordId {
                            content += "✕"
                        }
                    }
                }
                content = String(content.prefix(content.count - 1))  // Remove the last "/".
                
                return content
            case .meaningFilling:
                            
                let keyString: String!
                if wordPractice.direction == 0 {
                    keyString = wordToPractice.meaning
                } else {
                    keyString = wordToPractice.text
                }
                
                if wordPractice.correctness == .correct {
                    return "\(wordToPracticeString!) -\n\(keyString!)"
                } else if wordPractice.correctness == .incorrect {
                    return "\(wordToPracticeString!) -\n\(keyString!)✓ \(wordPractice.typedAnswer!)✕"
                } else if wordPractice.correctness == .partiallyCorrect {
                    return "\(wordToPracticeString!) -\n\(keyString!)✓ \(wordPractice.typedAnswer!)✕"  // TODO: - Update here.
                } else {
                    return "???"
                }
                
                
            case .contextSelection:
                
                // TODO: - Update here.
                
                return ""
            }
        } else if let readingPractice = practice as? ReadingPractice {
            let articleId = readingPractice.articleAndParaIds[0]
            let paraId = readingPractice.articleAndParaIds[1]
            
            // TODO: - Update "samples".
            guard let article = Article.load().getArticle(from: articleId) else {  // TODO: - load()
                return ""
            }
            let para = article.body.split(with: Strings.paraSeparator)[paraId]
            
            return para
        } else if let translationPractice = practice as? TranslationPractice {
            let articleId = translationPractice.articleAndParaIds[0]
            let paraId = translationPractice.articleAndParaIds[1]
            
            // TODO: - Update "samples".
            guard let article = Article.load().getArticle(from: articleId) else {  // TODO: - load()
                return ""
            }
            let para = article.body.split(with: Strings.paraSeparator)[paraId]
            
            let textAndMeaning = para.split(with: Strings.textMeaningSeparator)
            let text = textAndMeaning[0]
            let meaning = textAndMeaning[1]
            if translationPractice.direction == 0 {
                return text
            } else {
                return meaning
            }
        } else {
            return ""
        }
    }
    
    var correctness: WordPractice.Correctness? {
        if let wordPractice = practice as? WordPractice {
            return wordPractice.correctness
        } else {
            return nil
        }
    }
}
