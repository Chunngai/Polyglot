//
//  RussianAccentAnalyzer.swift
//  Polyglot
//
//  Created by Ho on 10/29/23.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class RussianAccentAnalyzer: AccentAnalyzerProtocol {
    
    // MARK: - Core Data stack
    // https://forums.developer.apple.com/forums/thread/654932
    
    var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "RussianAccentRetrievalModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        return container
    }()
    
    // MARK: - Core Data Saving support
    // https://forums.developer.apple.com/forums/thread/654932
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // private var context: NSManagedObjectContext {
    //     return persistentContainer.viewContext
    // }
    
    // MARK: - Verb aspects

    private var verbAspects: [String: String] = {
        guard let url = Bundle.main.url(forResource: "russian_verb_aspects", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return dict
    }()

    // MARK: - AccentAnalyzerProtocol

    // Singleton object.
    static var shared: AccentAnalyzerProtocol = RussianAccentAnalyzer()
    
    private func fixJeJo(_ text: String, context: NSManagedObjectContext) -> String {

        let wordTokens = text.tokenized(with: LangCode.ru.wordTokenizer)
        let jeTokens = wordTokens.filter { $0.contains("е") || $0.contains("Е") }
        guard !jeTokens.isEmpty else { return text }

        let request = Je2JoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "je_text IN %@", jeTokens.map { $0.lowercased() })
        let results: [Je2JoEntity]
        do {
            results = try context.fetch(request)
        } catch {
            print(error.localizedDescription)
            return text
        }

        var je2joMap: [String: Int] = [:]
        for entity in results {
            if let jeText = entity.je_text {
                je2joMap[jeText] = Int(entity.jo_pos)
            }
        }

        var fixedText = text
        for token in wordTokens {
            guard let joPos = je2joMap[token.lowercased()] else { continue }
            var tokenChars = [Character](token)
            tokenChars[joPos] = tokenChars[joPos].isLowercase ? "ё" : "Ё"
            fixedText = fixedText.replacingOccurrences(of: token, with: String(tokenChars))
        }
        return fixedText

    }

    func getTokens(_ text: String, context: NSManagedObjectContext) -> [Token] {

        let queries = text.lowercased().tokensWithPunctMarks

        let request = RussianAccentEntity.fetchRequest()
        request.predicate = NSPredicate(format: "bare_form IN %@", queries)
        let results: [RussianAccentEntity]
        do {
            results = try context.fetch(request)
        } catch {
            print(error.localizedDescription)
            results = []
        }

        var accentMap: [String: (accentPos: Int16, baseForm: String?)] = [:]
        for entity in results {
            if let bareForm = entity.bare_form {
                accentMap[bareForm] = (entity.accent_pos, entity.base_form)
            }
        }

        var tokens: [Token] = []
        for query in queries {
            var baseForm: String? = nil
            var accentLoc: Int? = nil
            if let entry = accentMap[query] {
                baseForm = entry.baseForm
                if entry.accentPos != -1 {
                    accentLoc = Int(entry.accentPos - 1)
                }
            }
            let aspect = verbAspects[baseForm ?? query]
            tokens.append(Token(
                text: query,
                baseForm: baseForm,
                pronunciation: query,
                accentLoc: accentLoc,
                aspect: aspect
            ))
        }
        return tokens

    }
    
    func analyze(for text: String, completion: @escaping (
        [Token],
        String?  // Fixed text.
    ) -> Void) {
        
        // DispatchQueue.global(qos: .userInitiated).async {
        
        print("RussianAccentAnalyzer: analyzing \"\(text)\".")
        
        let context = persistentContainer.newBackgroundContext()
        context.perform {
            
            let fixedText = self.fixJeJo(
                text,
                context: context
            )
            let tokens = self.getTokens(
                fixedText,
                context: context
            )
            completion(
                tokens,
                (
                    fixedText == text
                    ? nil
                    : fixedText
                )
            )
            
        }
        
    }
    
}

extension RussianAccentAnalyzer {
    
    class D: Codable {
        
        var accent_pos: Int?
        var base: String
        
        init(accent_pos: Int? = nil, base: String) {
            self.accent_pos = accent_pos
            self.base = base
        }
    }
    
    func addRussianAccentEntitiesToCoreDataModel() {
        
        var bare2d: [
            String: [D]
        ] = [:]
        do {
            guard let fileURL = Bundle.main.url(
                forResource:"russian_word_forms",
                withExtension: "json"
            ) else {
                return
            }
            let data = try Data(contentsOf: fileURL)
            bare2d = try JSONDecoder().decode(
                [String: [D]].self,
                from: data
            )
            
            print(bare2d.count)
            //            print(bare2d["и"])
            //            print(bare2d["другой"])
            
        } catch {
            print(error.localizedDescription)
        }
        
        let context = persistentContainer.viewContext
        
        // Clear all data.
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = RussianAccentEntity.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeCount
        do {
            let count = try context.execute(batchDeleteRequest) as! NSBatchDeleteResult
            print("Deleted \(count.result as! Int) records.")
            try context.save()
        } catch {
            print("Error when deleting data: \(error)")
        }
        
        var entityCount: Int = 0
        for (bare_form, d) in bare2d {
            
            let entity = RussianAccentEntity(context: context)
            if d.count == 1 {  // One bare form -> one accent pos + base form.
                
                let d = d[0]
                
                entity.bare_form = bare_form
                if let accent_pos = d.accent_pos {
                    entity.accent_pos = Int16(accent_pos)
                } else {  // No accent pos. E.g., в.
                    entity.accent_pos = -1
                }
                if d.base != "=" {
                    entity.base_form = d.base
                } else {  // The base form is identical to the bare form.
                    entity.base_form = bare_form
                }
                
            } else {
                let accentPosSet = Set(d.compactMap { d in
                    d.accent_pos
                })
                if accentPosSet.count == 1 {  // One bare form -> multiple accent pos + base form. But the accent pos's are the same.
                    
                    entity.bare_form = bare_form
                    if let accent_pos = accentPosSet.first {
                        entity.accent_pos = Int16(accent_pos)
                    } else {
                        entity.accent_pos = -1
                    }
                    entity.base_form = nil
                    
                } else {
                    // Do nothing.
                }
            }
            
            entityCount += 1
            if entityCount % 5000 == 0 {
                print(entityCount)
                do {
                    try context.save()
                } catch {
                    print(error.localizedDescription)
                }
            }
            
        }
    }
    
    class D1: Codable {
        
        var je_text: String
        var jo_pos: Int?
        
        init(je_text: String, jo_pos: Int?) {
            self.je_text = je_text
            self.jo_pos = jo_pos
        }
    }
    
    func addJe2JoEntitiesToCoreDataModel() {
        
        var l: [D1] = []
        do {
            guard let fileURL = Bundle.main.url(
                forResource:"formatted_je2jo",
                withExtension: "json"
            ) else {
                return
            }
            let data = try Data(contentsOf: fileURL)
            l = try JSONDecoder().decode(
                [D1].self,
                from: data
            )
            
            print(l.count)
            
        } catch {
            print(error.localizedDescription)
        }
        
        let context = persistentContainer.viewContext
        
        // Clear all data.
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Je2JoEntity.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeCount
        do {
            let count = try context.execute(batchDeleteRequest) as! NSBatchDeleteResult
            print("Deleted \(count.result as! Int) records.")
            try context.save()
        } catch {
            print("Error when deleting data: \(error)")
        }
        
        var entityCount: Int = 0
        for d in l {
            
            let entity = Je2JoEntity(context: context)
            entity.je_text = d.je_text
            entity.jo_pos = Int16(d.jo_pos!)
            
            entityCount += 1
            if entityCount % 5000 == 0 {
                print(entityCount)
                do {
                    try context.save()
                } catch {
                    print(error.localizedDescription)
                }
            }
            
        }
    }
    
}
