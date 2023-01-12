//
//  Strings.swift
//  Polyglot
//
//  Created by Sola on 2022/12/20.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation
import UIKit

struct Strings {
    
    // MARK: - Language Strings
    
    static let _enStrings: [String : String] = [
        LangCodes.en : "English",
        LangCodes.ja : "英語",
        LangCodes.es : "inglés"
    ]
    static var enString: String {
        return Strings._enStrings[Variables.lang]!
    }
    
    static let _jaStrings: [String : String] = [
        LangCodes.en : "Japanese",
        LangCodes.ja : "日本語",
        LangCodes.es : "japonés"
    ]
    static var jaString: String {
        return Strings._jaStrings[Variables.lang]!
    }
    
    static let _esStrings: [String : String] = [
        LangCodes.en : "Spanish",
        LangCodes.ja : "スペイン語",
        LangCodes.es : "español"
    ]
    static var esString: String {
        return Strings._esStrings[Variables.lang]!
    }
}

extension Strings {
    
    // MARK: - Main Prompts
    
    static let _mainPrimaryPrompts: [String : String] = [
        LangCodes.en : "Hello!",
        LangCodes.ja : "こんにちは！",
        LangCodes.es : "Hola!"
    ]
    static var mainPrimaryPrompt: String {
        return Strings._mainPrimaryPrompts[Variables.lang]!
    }
    
    static let _mainSecondaryPrompts: [String : String] = [
        
        LangCodes.en : "Choose a language to practice",
        LangCodes.ja : " 練習したい言語を選んでください",  // TODO: - The leading space is for aligning with the primary prompt.
        LangCodes.es : "Elija un idioma para practicar"
    ]
    static var mainSecondaryPrompt: String {
        return Strings._mainSecondaryPrompts[Variables.lang]!
    }
    
    // MARK: - Menu Prompts
    
    private static let _menuPrimaryPrompts: [String : String] = [
        LangCodes.en : "English",
        LangCodes.ja : "日本語",
        LangCodes.es : "español"
    ]
    static var menuPrimaryPrompt: String {
        return Strings._menuPrimaryPrompts[Variables.lang]!
    }
    
    private static let _menuSecondaryPrompts: [String : String] = [
        
        LangCodes.en : "What are you going to practice?",
        LangCodes.ja : "  何を練習しますか？",  // TODO: - The leading space is for aligning with the primary prompt.
        LangCodes.es : "¿Qué va a practicar?"
    ]
    static var menuSecondaryPrompt: String {
        return Strings._menuSecondaryPrompts[Variables.lang]!
    }
    
    // MARK: - Menu Items
    
    private static let _words: [String : String] = [
        LangCodes.en : "Words",
        LangCodes.ja : "単語",
        LangCodes.es : "Palabras"
    ]
    static var words: String {
        return Strings._words[Variables.lang]!
    }
    
    private static let _reading: [String : String] = [
        LangCodes.en : "Reading",
        LangCodes.ja : "読解",
        LangCodes.es : "Leer"
    ]
    static var reading: String {
        return Strings._reading[Variables.lang]!
    }
    
    private static let _interpretation: [String : String] = [
        LangCodes.en : "Interpretation",
        LangCodes.ja : "通訳",
        LangCodes.es : "Interpretación"
    ]
    static var interpretation: String {
        return Strings._interpretation[Variables.lang]!
    }
}

extension Strings {
    
    // MARK: - Alert Buttons
    
    private static let _ok: [String : String] = [
        LangCodes.en : "Ok",
        LangCodes.ja : "はい",
        LangCodes.es : "Sí"
    ]
    static var ok: String {
        return Strings._ok[Variables.lang]!
    }
    
    private static let _done: [String : String] = [
        LangCodes.en : "Done",
        LangCodes.ja : "完了",
        LangCodes.es : "Hecho"
    ]
    static var done: String {
        return Strings._done[Variables.lang]!
    }
    
    private static let _cancel: [String : String] = [
        LangCodes.en : "Cancel",
        LangCodes.ja : "キャンセル",
        LangCodes.es : "Cancelar"
    ]
    static var cancel: String {
        return Strings._cancel[Variables.lang]!
    }
    
    // MARK: - Alert Prompts
    
    private static let _exitWithoutSavingAlertTitles: [String : String] = [
        LangCodes.en : "Leave without Saving",
        LangCodes.ja : "保存せずに終了",
        LangCodes.es : "Salir sin Guardar"
    ]
    static var exitWithoutSavingAlertTitle: String {
        return Strings._exitWithoutSavingAlertTitles[Variables.lang]!
    }
    
    private static let _exitWithoutSavingAlertBodies: [String : String] = [
        LangCodes.en : "Edits have been made. Leave without saving them?",
        LangCodes.ja : "編集が行われました。 保存せずに終了しますか?",
        LangCodes.es : "Se han hecho modificaciones. ¿Salir sin guardarlas?"
    ]
    static var exitWithoutSavingAlertBody: String {
        return Strings._exitWithoutSavingAlertBodies[Variables.lang]!
    }
}

extension Strings {
    
    // MARK: - Word Adding
    
    private static let _addingNewWordAlertTitles: [String : String] = [
        LangCodes.en : "Add a New Word",
        LangCodes.ja : "新単語を追加",
        LangCodes.es : "Agregar una Nueva Palabra"
    ]
    static var addingNewWordAlertTitle: String {
        return Strings._addingNewWordAlertTitles[Variables.lang]!
    }
    
    private static let _addingNewWordAlertTextFieldPlaceholderForTexts: [String : String] = [
        LangCodes.en : "Word",
        LangCodes.ja : "単語",
        LangCodes.es : "Palabra"
    ]
    static var addingNewWordAlertTextFieldPlaceholderForText: String {
        return Strings._addingNewWordAlertTextFieldPlaceholderForTexts[Variables.lang]!
    }
    
    private static let _addingNewWordAlertTextFieldPlaceHolderForMeanings: [String : String] = [
        LangCodes.en : "Meaning",
        LangCodes.ja : "意味",
        LangCodes.es : "Significado"
    ]
    static var addingNewWordAlertTextFieldPlaceHolderForMeaning: String {
        return Strings._addingNewWordAlertTextFieldPlaceHolderForMeanings[Variables.lang]!
    }
    
    private static let _addingNewWordAlertTextFieldPlaceHolderForNotes: [String : String] = [
        LangCodes.en : "Notes",
        LangCodes.ja : "ノート",
        LangCodes.es : "Notas"
    ]
    static var addingNewWordAlertTextFieldPlaceHolderForNote: String {
        return Strings._addingNewWordAlertTextFieldPlaceHolderForNotes[Variables.lang]!
    }
    
    // MARK: - Batch Adding
    
    private static let _wordEditTextViewPrompts: [String : String] = [
        LangCodes.en : "Format：\nDate - Notes\n1. Word １\n2. Word 2\n\nDate - Notes\n1. Word １\n2. Word 2\n\n",
        LangCodes.ja : "フォーマット：\n日付 - ノート\n1. 単語１\n2. 単語2\n\n日付 - ノート\n1. 単語１\n2. 単語2\n\n",
        LangCodes.es : "Formato：\nFecha - ノート\n1. Palabra １\n2. Palabra 2\n\nFecha - ノート\n1. Palabra １\n2. Palabra 2\n\n"
    ]
    static var wordEditTextViewPrompt: String {
        return Strings._wordEditTextViewPrompts[Variables.lang]!
    }

    private static let _wordMeaningSeparators: [String : Substring.Element] = [
        LangCodes.en : ":",
        LangCodes.ja : " ",
        LangCodes.es : ":"
    ]
    static var wordMeaningSeparator: Substring.Element {
        return Strings._wordMeaningSeparators[Variables.lang]!
    }
        
    // MARK: - Bottom View / Text View
    
    private static let _newWordMenuItemStrings: [String : String] = [
        LangCodes.en : "New Word",
        LangCodes.ja : "新単語",
        LangCodes.es : "Palabra Nueva"
    ]
    static var newWordMenuItemString: String {
        return Strings._newWordMenuItemStrings[Variables.lang]!
    }
    
    private static let _newWordBottomViewMeaningPrompts: [String : String] = [
        LangCodes.en : "Also select/type the corresponding meaning",
        LangCodes.ja : "相応する意味も選択/入力してください",
        LangCodes.es : "Seleccione/ingrese también el significado correspondiente"
    ]
    static var newWordBottomViewMeaningPrompt: String {
        return Strings._newWordBottomViewMeaningPrompts[Variables.lang]!
    }
}

extension Strings {
    
    // MARK: - Article Adding
    
    private static let _articleTitlePrompts: [String : String] = [
        LangCodes.en : "Title: ",
        LangCodes.ja : "タイトル：",
        LangCodes.es : "Título: "
    ]
    static var articleTitlePrompt: String {
        return Strings._articleTitlePrompts[Variables.lang]!
    }
    
    private static let _articleTopicPrompts: [String : String] = [
        LangCodes.en : "Topic: ",
        LangCodes.ja : "トピック：",
        LangCodes.es : "Tema: "
    ]
    static var articleTopicPrompt: String {
        return Strings._articleTopicPrompts[Variables.lang]!
    }
    
    private static let _articleBodyPrompts: [String : String] = [
        LangCodes.en : "Body: ",
        LangCodes.ja : "本文：\n",
        LangCodes.es : "Cuerpo: "
    ]
    static var articleBodyPrompt: String {
        return Strings._articleBodyPrompts[Variables.lang]!
    }
    
    private static let _articleSourcePrompts: [String : String] = [
        LangCodes.en : "Source: ",
        LangCodes.ja : "ソース：",
        LangCodes.es : "Fuente: "
    ]
    static var articleSourcePrompt: String {
        return Strings._articleSourcePrompts[Variables.lang]!
    }
}

extension Strings {
    
    // MARK: - Practicing
    
    static let maskToken: String = "[MASK]"
    
    private static let _meaningSelectionAndFillingPracticePrompt: [String : String] = [
        LangCodes.en : "What's the meaning of\n\(Strings.maskToken)?",
        LangCodes.ja : "\(Strings.maskToken)\nは何と意味しますか",
        LangCodes.es : "¿Cuál es el significado de\n\(Strings.maskToken)?"
    ]
    static var meaningSelectionAndFillingPracticePrompt: String {
        return Strings._meaningSelectionAndFillingPracticePrompt[Variables.lang]!
    }
        
    private static let _meaningFillingPracticeReferenceLabelPrefices: [String : String] = [
        LangCodes.en : "Reference: ",
        LangCodes.ja : "参考：",
        LangCodes.es : "Referencia: "
    ]
    static var meaningFillingPracticeReferenceLabelPrefix: String {
        return Strings._meaningFillingPracticeReferenceLabelPrefices[Variables.lang]!
    }
    
    private static let _contextSelectionPracticePrompts: [String : String] = [
        LangCodes.en : "Select a proper word",
        LangCodes.ja : "適切な単語を選んでください",
        LangCodes.es : "Seleccione una palabra adecuada"
    ]
    static var contextSelectionPracticePrompt: String {
        return Strings._contextSelectionPracticePrompts[Variables.lang]!
    }
    
    private static let _translationPracticePrompts: [String : String] = [
        LangCodes.en : "Interpret the paragraph",
        LangCodes.ja : "この段落を\n通訳してください",
        LangCodes.es : "Interprete el párrafo"
    ]
    static var translationPracticePrompt: String {
        return Strings._translationPracticePrompts[Variables.lang]!
    }
    
    // MARK: - Timing
        
    private static let _timeUpAlertTitles: [String : String] = [
        LangCodes.en : "Time Up",
        LangCodes.ja : "タイムアップ",
        LangCodes.es : "Se Acabó el Tiempo"
    ]
    static var timeUpAlertTitle: String {
        return Strings._timeUpAlertTitles[Variables.lang]!
    }
    
    private static let _timeUpAlertBodies: [String : String] = [
        LangCodes.en : "You have practiced for \(Strings.maskToken) minutes. Continue practicing?",
        LangCodes.ja : "もう\(Strings.maskToken)分間練習しました。練習を続けますか？",
        LangCodes.es : "¿Ha practicado por \(Strings.maskToken) minutos. Siga practicando?"
    ]
    static var timeUpAlertBody: String {
        return Strings._timeUpAlertBodies[Variables.lang]!
    }
    
    private static let _maxTimeUpAlertBodies: [String : String] = [
        LangCodes.en : "You have practiced for \(Strings.maskToken) minutes. Take a break",
        LangCodes.ja : "もう\(Strings.maskToken)分練習しました。少し休んでください",
        LangCodes.es : "Ya ha practicado por \(Strings.maskToken) minutos. Tome un descanso."
    ]
    static var maxTimeUpAlertBody: String {
        return Strings._maxTimeUpAlertBodies[Variables.lang]!
    }
}

extension Strings {
    
//    static let meaningSelectionPractice: String = "単語 翻訳 (選択)"
//    static let meaningFillingPractice: String = "単語 翻訳 (入力)"
//    static let contextSelectionPractice: String = "単語 コンテスト"
//    static let readingPractice: String = "読解"
//    static let translationPractice: String = "通訳"
}

struct Identifiers {
    
//    static let historyTableCellIdentifier: String = "historyTableCellIdentifier"
    
    static let tableHeaderViewIdentifier: String = "tableHeaderViewIdentifier"
    
    static let wordsTableCellIdentifier: String = "wordsTableCellIdentifier"
    
    static let readingTableCellIdentifier: String = "readingTableCellIdentifier"
    static let readingEditTableCellIdentifier: String = "readingEditTableCellIdentifier"
    
}
