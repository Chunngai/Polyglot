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
        return creationDate.dateRepresentation()
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
            guard let wordToPractice = Word.getWord(from: wordPractice.wordId) else {
                print(wordPractice.wordId)
                return ""
            }
            
            let wordToPracticeString: String!
            if wordPractice.direction == 0 {
                wordToPracticeString = wordToPractice.word
            } else {
                wordToPracticeString = wordToPractice.meaning
            }
            
            switch wordPractice.type {
            case .meaningSelection:
                
                var content: String = "\(wordToPracticeString!) -\n"
                
                // Obtain selection words.
                var selectionWords: [Word?] = []
                for wordId in wordPractice.selectionWordsIds! {
                    selectionWords.append(Word.getWord(from: wordId))
                }
            
                for selectionWord in selectionWords {
                    if selectionWord == nil {
                        content += ""
                    }
                    
                    if wordPractice.direction == 0 {
                        content += "\(selectionWord!.meaning)/"
                    } else {
                        content += "\(selectionWord!.word)/"
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
                    keyString = wordToPractice.word
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
            guard let article = Article.getArticle(from: articleId) else {
                return ""
            }
            let para = article.body.split(with: Strings.paraSeparator)[paraId]
            
            return para
        } else if let translationPractice = practice as? TranslationPractice {
            let articleId = translationPractice.articleAndParaIds[0]
            let paraId = translationPractice.articleAndParaIds[1]
            
            // TODO: - Update "samples".
            guard let article = Article.getArticle(from: articleId) else {
                return ""
            }
            let para = article.body.split(with: Strings.paraSeparator)[paraId]
            
            let textAndMeaning = para.split(with: Strings.textAndMeaningSeparator)
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
