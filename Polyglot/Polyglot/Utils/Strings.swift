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
        LangCode.en : "English",
        LangCode.ja : "英語",
        LangCode.es : "inglés",
        LangCode.ru : "английский"
    ]
    static var enString: String {
        return Strings._enStrings[Variables.lang]!
    }
    
    static let _jaStrings: [String : String] = [
        LangCode.en : "Japanese",
        LangCode.ja : "日本語",
        LangCode.es : "japonés",
        LangCode.ru : "японский"
    ]
    static var jaString: String {
        return Strings._jaStrings[Variables.lang]!
    }
    
    static let _esStrings: [String : String] = [
        LangCode.en : "Spanish",
        LangCode.ja : "スペイン語",
        LangCode.es : "español",
        LangCode.ru : "испанский"
    ]
    static var esString: String {
        return Strings._esStrings[Variables.lang]!
    }
    
    static let _ruStrings: [String : String] = [
        LangCode.en : "Russian",
        LangCode.ja : "ロシア語",
        LangCode.es : "ruso",
        LangCode.ru : "русский"
    ]
    static var ruString: String {
        return Strings._ruStrings[Variables.lang]!
    }
    
    static func langStrings(for langCode: String) -> [String: String] {
        switch langCode {
        case LangCode.en: return Strings._enStrings
        case LangCode.ja: return Strings._jaStrings
        case LangCode.es: return Strings._esStrings
        case LangCode.ru: return Strings._ruStrings
        default: return [:]
        }
    }
}

extension Strings {
    
    // MARK: - Main Prompts
    
    static let _mainPrimaryPrompts: [String : String] = [
        LangCode.en : "Hello!",
        LangCode.ja : "こんにちは！",
        LangCode.es : "Hola!",
        LangCode.ru : "Привет!"
    ]
    static var mainPrimaryPrompt: String {
        return Strings._mainPrimaryPrompts[Variables.lang]!
    }
    
    static let _mainSecondaryPrompts: [String : String] = [
        
//        LangCode.en : "Choose a language to practice",
//        LangCode.ja : " 練習したい言語を選んでください",  // TODO: - The leading space is for aligning with the primary prompt.
//        LangCode.es : "Elija un idioma para practicar",
//        LangCode.ru : "Выберите язык для практики"
        LangCode.en : " ",
        LangCode.ja : " ",
        LangCode.es : " ",
        LangCode.ru : " "
    ]
    static var mainSecondaryPrompt: String {
        return Strings._mainSecondaryPrompts[Variables.lang]!
    }
    
    // MARK: - Menu Prompts
    
    private static let _menuPrimaryPrompts: [String : String] = [
        LangCode.en : "English",
        LangCode.ja : "日本語",
        LangCode.es : "Español",
        LangCode.ru : "Русский"
    ]
    static var menuPrimaryPrompt: String {
        return Strings._menuPrimaryPrompts[Variables.lang]!
    }
    
    private static let _menuSecondaryPrompts: [String : String] = [
        
//        LangCode.en : "What are you going to practice?",
//        LangCode.ja : "  何を練習しますか？",  // TODO: - The leading space is for aligning with the primary prompt.
//        LangCode.es : "¿Qué va a practicar?",
//        LangCode.ru : "Что вы собираетесь практиковать?"
        LangCode.en : " ",
        LangCode.ja : " ",
        LangCode.es : " ",
        LangCode.ru : " "
    ]
    static var menuSecondaryPrompt: String {
        return Strings._menuSecondaryPrompts[Variables.lang]!
    }
    
    // MARK: - Menu Items
    
    private static let _words: [String : String] = [
        LangCode.en : "Words",
        LangCode.ja : "単語",
        LangCode.es : "Palabras",
        LangCode.ru : "Слова"
    ]
    static var words: String {
        return Strings._words[Variables.lang]!
    }
    
    private static let _reading: [String : String] = [
        LangCode.en : "Reading",
        LangCode.ja : "読解",
        LangCode.es : "Leer",
        LangCode.ru : "Чтение"
    ]
    static var reading: String {
        return Strings._reading[Variables.lang]!
    }
    
    private static let _interpretation: [String : String] = [
        LangCode.en : "Interpretation",
        LangCode.ja : "通訳",
        LangCode.es : "Interpretación",
        LangCode.ru : "Интерпретация"
    ]
    static var interpretation: String {
        return Strings._interpretation[Variables.lang]!
    }
}

extension Strings {
    
    // MARK: - Alert Buttons
    
    private static let _ok: [String : String] = [
        LangCode.en : "Ok",
        LangCode.ja : "はい",
        LangCode.es : "Sí",
        LangCode.ru : "Да"
    ]
    static var ok: String {
        return Strings._ok[Variables.lang]!
    }
    
    private static let _done: [String : String] = [
        LangCode.en : "Done",
        LangCode.ja : "完了",
        LangCode.es : "Hecho",
        LangCode.ru : "Сделанный"
    ]
    static var done: String {
        return Strings._done[Variables.lang]!
    }
    
    private static let _cancel: [String : String] = [
        LangCode.en : "Cancel",
        LangCode.ja : "キャンセル",
        LangCode.es : "Cancelar",
        LangCode.ru : "Отмена"
    ]
    static var cancel: String {
        return Strings._cancel[Variables.lang]!
    }
    
    // MARK: - Alert Prompts
    
    private static let _exitWithoutSavingAlertTitles: [String : String] = [
        LangCode.en : "Leave without Saving",
        LangCode.ja : "保存せずに終了",
        LangCode.es : "Salir sin Guardar",
        LangCode.ru : "Выйти без сохранения"
    ]
    static var exitWithoutSavingAlertTitle: String {
        return Strings._exitWithoutSavingAlertTitles[Variables.lang]!
    }
    
    private static let _exitWithoutSavingAlertBodies: [String : String] = [
        LangCode.en : "Edits have been made. Leave without saving them?",
        LangCode.ja : "編集が行われました。 保存せずに終了しますか?",
        LangCode.es : "Se han hecho modificaciones. ¿Sale sin guardarlas?",
        LangCode.ru : "Внесены модификации. Выход без сохранения?"
    ]
    static var exitWithoutSavingAlertBody: String {
        return Strings._exitWithoutSavingAlertBodies[Variables.lang]!
    }
}

extension Strings {
    
    // MARK: - Word Adding
    
    private static let _addingNewWordAlertTitles: [String : String] = [
        LangCode.en : "Add a New Word",
        LangCode.ja : "新単語を追加",
        LangCode.es : "Agregar una Nueva Palabra",
        LangCode.ru : "Добавить новое слово"
    ]
    static var addingNewWordAlertTitle: String {
        return Strings._addingNewWordAlertTitles[Variables.lang]!
    }
    
    private static let _addingNewWordAlertTextFieldPlaceholderForTexts: [String : String] = [
        LangCode.en : "Word",
        LangCode.ja : "単語",
        LangCode.es : "Palabra",
        LangCode.ru : "Слово"
    ]
    static var addingNewWordAlertTextFieldPlaceholderForText: String {
        return Strings._addingNewWordAlertTextFieldPlaceholderForTexts[Variables.lang]!
    }
    
    private static let _addingNewWordAlertTextFieldPlaceHolderForMeanings: [String : String] = [
        LangCode.en : "Meaning",
        LangCode.ja : "意味",
        LangCode.es : "Significado",
        LangCode.ru : "Значение"
    ]
    static var addingNewWordAlertTextFieldPlaceHolderForMeaning: String {
        return Strings._addingNewWordAlertTextFieldPlaceHolderForMeanings[Variables.lang]!
    }
    
    private static let _addingNewWordAlertTextFieldPlaceHolderForNotes: [String : String] = [
        LangCode.en : "Notes",
        LangCode.ja : "ノート",
        LangCode.es : "Notas",
        LangCode.ru : "Ноты"
    ]
    static var addingNewWordAlertTextFieldPlaceHolderForNote: String {
        return Strings._addingNewWordAlertTextFieldPlaceHolderForNotes[Variables.lang]!
    }
    
    // MARK: - Batch Adding
    
    private static let _wordEditTextViewPrompts: [String : String] = [
        LangCode.en : "Format：\nDate - Notes\n1. Word １\n2. Word 2\n\nDate - Notes\n1. Word １\n2. Word 2\n\n",
        LangCode.ja : "フォーマット：\n日付 - ノート\n1. 単語１\n2. 単語2\n\n日付 - ノート\n1. 単語１\n2. 単語2\n\n",
        LangCode.es : "Formato：\nFecha - ノート\n1. Palabra １\n2. Palabra 2\n\nFecha - ノート\n1. Palabra １\n2. Palabra 2\n\n",
        LangCode.ru : "Формат：\nДата - ノート\n1. Слово １\n2. Слово 2\n\nДата - ノート\n1. Слово １\n2. Слово 2\n\n"
    ]
    static var wordEditTextViewPrompt: String {
        return Strings._wordEditTextViewPrompts[Variables.lang]!
    }

    private static let _wordMeaningSeparators: [String : Substring.Element] = [
        LangCode.en : ":",
        LangCode.ja : " ",
        LangCode.es : ":",
        LangCode.ru : ":"
    ]
    static var wordMeaningSeparator: Substring.Element {
        return Strings._wordMeaningSeparators[Variables.lang]!
    }
        
    // MARK: - Bottom View / Text View
    
    private static let _newWordMenuItemStrings: [String : String] = [
        LangCode.en : "New Word",
        LangCode.ja : "新単語",
        LangCode.es : "Palabra Nueva",
        LangCode.ru : "Новое слово"
    ]
    static var newWordMenuItemString: String {
        return Strings._newWordMenuItemStrings[Variables.lang]!
    }
    
    private static let _newWordBottomViewMeaningPrompts: [String : String] = [
        LangCode.en : "Also select/type the corresponding meaning",
        LangCode.ja : "相応する意味も選択/入力してください",
        LangCode.es : "Seleccione/ingrese también el significado correspondiente",
        LangCode.ru : "Также выберите/введите соответствующее значение"
    ]
    static var newWordBottomViewMeaningPrompt: String {
        return Strings._newWordBottomViewMeaningPrompts[Variables.lang]!
    }
}

extension Strings {
    
    // MARK: - Article Adding
    
    private static let _articleTitlePrompts: [String : String] = [
        LangCode.en : "Title: ",
        LangCode.ja : "タイトル：",
        LangCode.es : "Título: ",
        LangCode.ru : "Заголовок: "
    ]
    static var articleTitlePrompt: String {
        return Strings._articleTitlePrompts[Variables.lang]!
    }
    
    private static let _articleTopicPrompts: [String : String] = [
        LangCode.en : "Topic: ",
        LangCode.ja : "トピック：",
        LangCode.es : "Tema: ",
        LangCode.ru : "Тема: "
    ]
    static var articleTopicPrompt: String {
        return Strings._articleTopicPrompts[Variables.lang]!
    }
    
    private static let _articleBodyPrompts: [String : String] = [
        LangCode.en : "Body: \n",
        LangCode.ja : "本文：\n",
        LangCode.es : "Cuerpo: \n",
        LangCode.ru : "Тело: \n"
    ]
    static var articleBodyPrompt: String {
        return Strings._articleBodyPrompts[Variables.lang]!
    }
    
    private static let _articleSourcePrompts: [String : String] = [
        LangCode.en : "Source: ",
        LangCode.ja : "ソース：",
        LangCode.es : "Fuente: ",
        LangCode.ru : "Источник: "
    ]
    static var articleSourcePrompt: String {
        return Strings._articleSourcePrompts[Variables.lang]!
    }
    
    static let windowsNewLineSymbol: String = "\r\n"
    static let macNewLineSymbol: String = "\n\r"
}

extension Strings {
    
    // MARK: - Practicing
    
    static let maskToken: String = "[MASK]"
    static let underlineToken: String = String.init(repeating: "\u{FF3F}", count: 6)
    static var tokenSeparator: String = "·"
    
    private static let _meaningSelectionAndFillingPracticePrompt: [String : String] = [
        LangCode.en : "The meaning of\n\(Strings.maskToken)?",
        LangCode.ja : "\(Strings.maskToken)\nの意味は？",
        LangCode.es : "¿El significado de\n\(Strings.maskToken)?",
        LangCode.ru : "Что означает\n\(Strings.maskToken)?"
    ]
    static var meaningSelectionAndFillingPracticePrompt: String {
        return Strings._meaningSelectionAndFillingPracticePrompt[Variables.lang]!
    }
        
    private static let _meaningFillingPracticeReferenceLabelPrefices: [String : String] = [
        LangCode.en : "Reference: ",
        LangCode.ja : "参考：",
        LangCode.es : "Referencia: ",
        LangCode.ru : "Ссылка: "
    ]
    static var meaningFillingPracticeReferenceLabelPrefix: String {
        return Strings._meaningFillingPracticeReferenceLabelPrefices[Variables.lang]!
    }
    
    private static let _contextSelectionPracticePrompts: [String : String] = [
        LangCode.en : "Select a proper word.",
        LangCode.ja : "適切な単語を選んでください。",
        LangCode.es : "Seleccione una palabra adecuada.",
        LangCode.ru : "Выберите подходящее слово."
    ]
    static var contextSelectionPracticePrompt: String {
        return Strings._contextSelectionPracticePrompts[Variables.lang]!
    }
    
    private static let _accentSelectionPracticePrompts: [String : String] = [
        LangCode.en : "The accents for\n\(Strings.maskToken)?",
        LangCode.ja : "\(Strings.maskToken)\nのアクセントは？",
        LangCode.es : "¿Los acentos para\n\(Strings.maskToken)?",
        LangCode.ru : "Какие акценты для\n\(Strings.maskToken)?"
    ]
    static var accentSelectionPracticePrompt: String {
        return Strings._accentSelectionPracticePrompts[Variables.lang]!
    }
    
    private static let _translationPracticePrompts: [String : String] = [
        LangCode.en : "Interpret the paragraph.",
        LangCode.ja : "この段落を通訳してください。",
        LangCode.es : "Interprete el párrafo.",
        LangCode.ru : "интерпретировать пункт."
    ]
    static var translationPracticePrompt: String {
        return Strings._translationPracticePrompts[Variables.lang]!
    }
    
    private static let _textsForPausedPractice: [String : String] = [
        LangCode.en : "Practice paused.",
        LangCode.ja : "練習を一時停止しました。",
        LangCode.es : "Práctica en pausa.",
        LangCode.ru : "Практика приостановлена."
    ]
    static var textForPausedPractice: String {
        return Strings._textsForPausedPractice[Variables.lang]!
    }
    
    // MARK: - Timing
        
    private static let _timeUpAlertTitles: [String : String] = [
        LangCode.en : "Time Up",
        LangCode.ja : "タイムアップ",
        LangCode.es : "Se Acabó el Tiempo",
        LangCode.ru : "Время вышло"
    ]
    static var timeUpAlertTitle: String {
        return Strings._timeUpAlertTitles[Variables.lang]!
    }
    
    private static let _timeUpAlertBodies: [String : String] = [
        LangCode.en : "You have practiced for \(Strings.maskToken) minutes. Continue practicing?",
        LangCode.ja : "もう\(Strings.maskToken)分間練習しました。練習を続けますか？",
        LangCode.es : "¿Ha practicado por \(Strings.maskToken) minutos. Siga practicando?",
        LangCode.ru : "Вы тренировались в течение \(Strings.maskToken) минут(ы/a). Продолжай практиковаться?"
    ]
    static var timeUpAlertBody: String {
        return Strings._timeUpAlertBodies[Variables.lang]!
    }
    
    private static let _maxTimeUpAlertBodies: [String : String] = [
        LangCode.en : "You have practiced for \(Strings.maskToken) minutes. Take a break.",
        LangCode.ja : "もう\(Strings.maskToken)分練習しました。少し休んでください。",
        LangCode.es : "Ya ha practicado por \(Strings.maskToken) minutos. Tome un descanso.",
        LangCode.ru : "Вы уже тренировались \(Strings.maskToken) минут. Сделайте перерыв."
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
    
    // MARK: - UICollectionViewCell Identifiers
    
    static let langCellIdentifier: String = "languageCell"
    
    // MARK: - UITableViewCell Identifiers
    
    static let wordsTableCellIdentifier: String = "wordsTableCellIdentifier"
    static let readingTableCellIdentifier: String = "readingTableCellIdentifier"
    
    // MARK: - UITableViewHeaderFooterView Identifiers
    
    static let tableHeaderViewIdentifier: String = "tableHeaderViewIdentifier"
    static let readingEditTableCellIdentifier: String = "readingEditTableCellIdentifier"
    
}
