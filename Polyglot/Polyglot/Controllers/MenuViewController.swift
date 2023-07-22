//
//  MenuViewController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/20.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {

    private var lang: String!
    
    // MARK: - Views
    
    private lazy var mainView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var promptView: UIView = {
        let view = UIView()
        return view
    }()
    private lazy var primaryPromptLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: Strings.menuPrimaryPrompt,
            attributes: Attributes.primaryPromptAttributes
        )
        return label
    }()
    private lazy var langImageView: UIImageView = UIImageView()
    
    private lazy var menuButtonStackView: ThreeButtonSelectionStack = {
        let stackView = ThreeButtonSelectionStack()
        stackView.set(texts: [
            Strings.words,
            Strings.reading,
            Strings.interpretation
        ])
        return stackView
    }()
    
    // MARK: - Init
    
    // https://stackoverflow.com/questions/30679129/how-to-write-init-methods-of-a-uiviewcontroller-in-swift
    
    convenience init(lang: String) {
        self.init(nibName:nil, bundle:nil)
        
        // Should be set before the following code
        // because Images.langImage depends on lang.
        Variables.lang = lang
        
        self.lang = lang
        self.langImageView.image = Images.langImage
        
        // TODO: - Move elsewhere.
        DispatchQueue.global(qos: .userInitiated).async {
            generateWordcardNotifications(
                for: Variables.lang,
                words: Word.load(),
                articles: Article.load()
            )
        }
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
//        if Variables.lang == LangCode.ru {
//            addRussianWords(fp: "Unit 1.info.fixed.json")
//        }
        
//        if Variables.lang == LangCode.ru {
//            addAccents()
//        }
        
//        if Variables.lang == LangCode.de {
//            addGermanWords(fp: "de.words.duome.u1.json")
//        }
        
//        if Variables.lang == LangCode.de {
//            addSentences(dp: "duome_de_sentences")
//        }
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    private func updateSetups() {
        menuButtonStackView.delegate = self
    }
    
    private func updateViews() {
        
        view.backgroundColor = Colors.defaultBackgroundColor
        view.addSubview(mainView)
        
        mainView.addSubview(promptView)
        mainView.addSubview(menuButtonStackView)

        promptView.addSubview(primaryPromptLabel)
        promptView.addSubview(langImageView)
    }
    
    // TODO: - Update the insets and offsets here.
    // TODO: - Use relative insets and offsets instead.
    private func updateLayouts() {
        
        mainView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.top.equalToSuperview().inset(300)
            make.bottom.equalToSuperview()
        }
        
        promptView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.4)
        }
        primaryPromptLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
        }
        langImageView.snp.makeConstraints { (make) in
            make.top.equalTo(primaryPromptLabel.snp.top)
            make.left.equalTo(primaryPromptLabel.snp.right).offset(20)
        }
        
        menuButtonStackView.snp.makeConstraints { (make) in
            make.top.equalTo(promptView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
        }
    }
}

extension MenuViewController: ThreeItemSelectionStackDelegate {
    
    @objc func buttonSelected(sender: UIButton) {
        
        switch sender.tag {
        case 0: navigationController?.pushViewController(
            WordsViewController(),
            animated: true
        )
        case 1: navigationController?.pushViewController(
            ReadingViewController(),
            animated: true
        )
        case 2:
            // TODO: - Error when articles.count == 0.
            let translationPracticeViewController = TranslationPracticeViewController()
            translationPracticeViewController.updateValues(articles: Article.load())
            
            let navController = NavController(rootViewController: translationPracticeViewController)
            navigationController?.present(navController, animated: true, completion: nil)
        default: return
        }
    }
    
}

extension MenuViewController {
    
    // TODO: - Move elsewhere.
    static func removeAccentMark(string: String) -> String {
        return string
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
    }
    
    private func addRussianWords(fp: String) {
        
        do {
            do {
                let path = NSString.path(withComponents: [Bundle.main.resourcePath!, fp])
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let jsonData = try JSONDecoder().decode([String:[[String:String]]].self, from: data)
                
                var existingWords = Word.load()
                for row in jsonData["data"]! {
                    let labels = row["labels"]!
                    if labels.contains("[error]") {
                        print("[error label] Skipping to add: \(row).")
                        continue
                    }
                    if labels.contains("a-invld?") {
                        print("[a-invld? label] Skipping to add: \(row).")
                        continue
                    }
                    
                    var baseForm = row["base_form"]!
                    // Remove accent marks.
                    baseForm = MenuViewController.removeAccentMark(string: baseForm)
                    
                    var text = row["text"]!
                    let accentLoc: Int? = Array(text).firstIndex(of: "[")
                    // Remove accent marks.
                    text = MenuViewController.removeAccentMark(string: text)
                    
                    let textSplits = text.split(with: " ")
                    var tokens: [Token] = []
                    if textSplits.count == 1 {
                        tokens = [Token(
                            text: text,
                            baseForm: baseForm,
                            pronunciation: text,
                            accentLoc: accentLoc
                            )]
                    } else {
                        print("[multiple text splits] Skipping to add: \(row).")
                        continue
                    }
                    
                    let posInfo = row["pos_info"]!
                    let meaning = row["meaning"]!
                    let note = "Duolingo - \(row["lesson"]!)"
                    
                    var posInfoAndMeaning = meaning
                    if !posInfo.isEmpty {
                        posInfoAndMeaning = "(\(posInfo)) \(posInfoAndMeaning)"
                    }
                    
                    if let indexOfExistingWord = existingWords.add(newWord: Word(
                        text: text,
                        tokens: tokens,
                        meaning: posInfoAndMeaning,
                        note: note
                    )) {
                        existingWords[indexOfExistingWord].update(
                            newText: text,
                            newTokens: tokens,
                            newMeaning: posInfoAndMeaning,
                            newNote: note
                        )
                    }
                }
                
                //                    for existingWord in existingWords {
                //                        print(existingWord.text, existingWord.meaning)
                //                    }
                
                Word.save(&existingWords)
            } catch let error as CocoaError {
                print(error)
                throw error
            } catch let error as DecodingError {
                print(error)
                throw error
            }
        } catch {
            
        }
    }

    private func addSentences(dp: String) {
        let fm = FileManager.default
        var path = Bundle.main.resourcePath!
        path = NSString.path(withComponents: [path, dp])
        do {
            var newArticles: [Article] = []
            
            // https://stackoverflow.com/questions/37239064/listing-files-in-a-specific-folder
            let files = try fm.contentsOfDirectory(atPath: path)
            for file in files {
                let filePath = NSString.path(withComponents: [path, file])
                let fileText = try! String(contentsOfFile: filePath)
                
                let article: Article = {
                    let title = file.replacingOccurrences(of: ".txt", with: "")
                    let topic = "Duolingo Sentences"
                    let text = fileText
                    let source = "Duome"
                    
                    return Article(title: title, topic: topic, body: text, source: source)
                }()
                newArticles.append(article)
            }
            
            var articles = Article.load()
            for newArticle in newArticles {
                articles.add(newArticle: newArticle)
            }
            Article.save(&articles)
        } catch {
            
        }
    }
    
    private func addGermanWords(fp: String) {
        
        do {
            do {
                let path = NSString.path(withComponents: [Bundle.main.resourcePath!, fp])
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let jsonData = try JSONDecoder().decode([String:[[String:String]]].self, from: data)
                
                var existingWords = Word.load()
                for row in jsonData["data"]! {
                    let text = row["text"]!
                    let posInfo = row["info"]!
                        .replacingOccurrences(of: "Masculine Noun", with: "der")
                        .replacingOccurrences(of: "Feminine Noun", with: "die")
                        .replacingOccurrences(of: "Neuter Noun", with: "das")
                    let meaning = row["meanings"]!
                    let note = "Duolingo - \(row["lesson"]!)"
                    
                    var posInfoAndMeaning = meaning
                    if !posInfo.isEmpty {
                        posInfoAndMeaning = "(\(posInfo)) \(posInfoAndMeaning)"
                    }
                    
                    if let indexOfExistingWord = existingWords.add(newWord: Word(
                        text: text,
                        tokens: nil,
                        meaning: posInfoAndMeaning,
                        note: note
                    )) {
                        existingWords[indexOfExistingWord].update(
                            newText: text,
                            newTokens: nil,
                            newMeaning: posInfoAndMeaning,
                            newNote: note
                        )
                    }
                }
                
                //                    for existingWord in existingWords {
                //                        print(existingWord.text, existingWord.meaning)
                //                    }
                
                Word.save(&existingWords)
            } catch let error as CocoaError {
                print(error)
                throw error
            } catch let error as DecodingError {
                print(error)
                throw error
            }
        } catch {
            
        }
    }
}
