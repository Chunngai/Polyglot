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
    
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - AccentAnalyzerProtocol
    
    // Singleton object.
    static var shared: AccentAnalyzerProtocol = RussianAccentAnalyzer()
    
    func analyze(for word: Word, completion: @escaping ([Token]) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            var tokens: [Token] = []
            
            print("Analyzing russian word: \(word.text).")
            for query in word.text.lowercased().tokensWithPunctMarks {
                
                let request = RussianAccentEntity.fetchRequest()
                let predicate = NSPredicate(
                    format: "bare_form = %@",
                    query
                )
                request.predicate = predicate
                
                do {
                    let r = try self.context.fetch(request)
                    
                    var baseForm: String? = nil
                    var accentLoc: Int? = nil
                    if !r.isEmpty {
                        if let base_form = r[0].base_form {
                            baseForm = base_form
                        }
                        if r[0].accent_pos != -1 {  // Has accent pos when != -1.
                            accentLoc = Int(r[0].accent_pos - 1)
                        }
                    }
                    
                    let token = Token(
                        text: query,
                        baseForm: baseForm,
                        pronunciation: query,
                        accentLoc: accentLoc
                    )
                    tokens.append(token)
                    
                } catch let error {
                    print(error.localizedDescription)
                }
            }
            
            completion(tokens)
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
    
    func addEntitiesToCoreDataModel() {
        
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
}
