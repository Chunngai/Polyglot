//
//  WordsEditViewController.swift
//  Polyglot
//
//  Created by Sola on 2023/1/2.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

class WordsEditViewController: UIViewController {

    // MARK: - Controllers
    
    var delegate: WordsEditViewControllerDelegate!
    
    // MARK: - Views
    
    lazy var textView: AutoResizingTextViewWithPrompt = {
        let textView = AutoResizingTextViewWithPrompt()
        textView.backgroundColor = Colors.defaultBackgroundColor
        return textView
    }()
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateSetups()
        updateViews()
        updateLayouts()
    }

    private func updateSetups() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: Icons.cancelIcon,
            style: .plain,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: Icons.doneIcon,
            style: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
        
        textView.keyboardDismissMode = .onDrag
    }
    
    private func updateViews() {
        view.backgroundColor = Colors.defaultBackgroundColor
        view.addSubview(textView)
        
        textView.prompt = Strings.wordEditTextViewPrompt
        textView.promptAttributes = Attributes.promptTextColorAttribute
        textView.textAttributes = Attributes.defaultLongTextAttributes
    }
    
    private func updateLayouts() {
        textView.snp.makeConstraints { (make) in
            make.top.bottom.height.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.95)
            make.centerX.equalToSuperview()
        }
    }
    
    func updateValues() {
        
    }
}

extension WordsEditViewController {

    // MARK: - Selectors

    @objc private func cancelButtonTapped() {
        
        if !textView.content.isEmpty {
            presentExitWithoutSavingAlert(viewController: self) { (isOk) in
                if isOk {
                    self.navigationController?.dismiss(animated: true, completion: nil)
                } else {
                    return
                }
            }
        } else {
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }

    @objc private func doneButtonTapped() {
        
        // TODO: - Simplify.
        
        if textView.content.isEmpty {
            return
        }
        
        var words: [Word] = []
        
        let sections: [String] = textView.content.strip().split(with: Article.paraSeparator)
        for section in sections {
            let lines: [String] = section.split(with: "\n")
            
            // TODO: format error handling.
            // TODO: - Take care of the splitting results.
            
            // Date and optionally group note.
            let firstLine = lines[0].replacingOccurrences(of: "- [ ]", with: "").strip()  // Replace the TODO bullet, if any.
            let firstLineSplits = firstLine.split(with: "-")
            
            let dateString = firstLineSplits[0].strip()
            let dateStringSplits = dateString.split(separator: "/")
            let year: Int = Int(String(dateStringSplits[0]))!
            let month: Int = Int(String(dateStringSplits[1]))!
            let day: Int = Int(String(dateStringSplits[2]))!
            let date = Date.fromYearMonthDay(year: year, month: month, day: day)
            
            let groupNote: String!
            if firstLineSplits.count == 2 {
                groupNote = firstLineSplits[1].strip()
            } else {
                groupNote = nil
            }
            
            for i in 1..<lines.count {
                let line = lines[i].split(separator: ".", maxSplits: 1)[1]  // Remove the numbring.
                let lineSplits = line.split(separator: Strings.wordMeaningSeparator)
                let word = String(lineSplits[0]).strip()
                let meaning = String(lineSplits[1]).strip()
                
                words.append(Word(
                    cDate: date,
                    text: word,
                    meaning: meaning,
                    note: groupNote
                ))
            }
        }
        
        delegate.add(words: words)
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

protocol WordsEditViewControllerDelegate {
    
    func add(words: [Word])
    
}
