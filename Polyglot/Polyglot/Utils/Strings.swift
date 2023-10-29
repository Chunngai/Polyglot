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
        LangCode.ru : "английский",
        LangCode.ko : "영어",
        LangCode.de : "Englisch",
    ]
    static var enString: String {
        return Strings._enStrings[Variables.lang]!
    }
    
    static let _jaStrings: [String : String] = [
        LangCode.en : "Japanese",
        LangCode.ja : "日本語",
        LangCode.es : "japonés",
        LangCode.ru : "японский",
        LangCode.ko : "일본어",
        LangCode.de : "Japanisch",
    ]
    static var jaString: String {
        return Strings._jaStrings[Variables.lang]!
    }
    
    static let _esStrings: [String : String] = [
        LangCode.en : "Spanish",
        LangCode.ja : "スペイン語",
        LangCode.es : "español",
        LangCode.ru : "испанский",
        LangCode.ko : "스페인어",
        LangCode.de : "Spanisch",
    ]
    static var esString: String {
        return Strings._esStrings[Variables.lang]!
    }
    
    static let _ruStrings: [String : String] = [
        LangCode.en : "Russian",
        LangCode.ja : "ロシア語",
        LangCode.es : "ruso",
        LangCode.ru : "русский",
        LangCode.ko : "러시아어",
        LangCode.de : "Russisch",
    ]
    static var ruString: String {
        return Strings._ruStrings[Variables.lang]!
    }
    
    static let _koStrings: [String : String] = [
        LangCode.en : "Korean",
        LangCode.ja : "韓国語",
        LangCode.es : "coreano",
        LangCode.ru : "корейский",
        LangCode.ko : "한국어",
        LangCode.de : "Koreanisch",
    ]
    static var koString: String {
        return Strings._koStrings[Variables.lang]!
    }
    
    static let _deStrings: [String : String] = [
        LangCode.en : "German",
        LangCode.ja : "ドイツ語",
        LangCode.es : "alemán",
        LangCode.ru : "немецкий",
        LangCode.ko : "독일어",
        LangCode.de : "Deutsch",
    ]
    static var deString: String {
        return Strings._deStrings[Variables.lang]!
    }
    
    static func langStrings(for langCode: String) -> [String: String] {
        switch langCode {
        case LangCode.en: return Strings._enStrings
        case LangCode.ja: return Strings._jaStrings
        case LangCode.es: return Strings._esStrings
        case LangCode.ru: return Strings._ruStrings
        case LangCode.ko: return Strings._koStrings
        case LangCode.de: return Strings._deStrings
        default: return [:]
        }
    }
}

extension Strings {
    
    // MARK: - Home Texts
    
    static let _homeTitles: [String : String] = [
        LangCode.en : "Home",
        LangCode.ja : "ホーム",
        LangCode.es : "Inicio",
        LangCode.ru : "Главная",
        LangCode.ko : "홈",
        LangCode.de : "Startseite",
    ]
    static var homeTitle: String {
        return Strings._homeTitles[Variables.lang]!
    }
    
//    static let _mainPrimaryPrompts: [String : String] = [
//        LangCode.en : "Hello!",
//        LangCode.ja : "こんにちは！",
//        LangCode.es : "Hola!",
//        LangCode.ru : "Привет!",
//        LangCode.ko : "안녕하세요",
//        LangCode.de : "Hallo!",
//    ]
//    static var mainPrimaryPrompt: String {
//        return Strings._mainPrimaryPrompts[Variables.lang]!
//    }
            
//    private static let _menuPrimaryPrompts: [String : String] = [
//        LangCode.en : "English",
//        LangCode.ja : "日本語",
//        LangCode.es : "Español",
//        LangCode.ru : "Русский",
//        LangCode.ko : "한국어",
//        LangCode.de : "Deutsch",
//    ]
//    static var menuPrimaryPrompt: String {
//        return Strings._menuPrimaryPrompts[Variables.lang]!
//    }
        
//    static let _wordListNavItemTitles: [String : String] = [
//        LangCode.en : "Words and Phrases",
//        LangCode.ja : "単語とフレーズ",
//        LangCode.es : "Palabras y Frases",
//        LangCode.ru : "Слова и Фразы",
//        LangCode.ko : "단어와 문구",
//        LangCode.de : "Wörter und Sätze",
//    ]
//    static var wordListNavItemTitle: String {
//        return Strings._wordListNavItemTitles[Variables.lang]!
//    }
    
    static let _phrases: [String : String] = [
        LangCode.en : "Phrases",
        LangCode.ja : "フレーズ",
        LangCode.es : "Frases",
        LangCode.ru : "Фразы",
        LangCode.ko : "문구",
        LangCode.de : "Sätze",
    ]
    static var phrases: String {
        return Strings._phrases[Variables.lang]!
    }
    
    static let _articles: [String : String] = [
        LangCode.en : "Articles",
        LangCode.ja : "文章",
        LangCode.es : "Artículos",
        LangCode.ru : "Статьи",
        LangCode.ko : "문장",
        LangCode.de : "Artikel",
    ]
    static var articles: String {
        return Strings._articles[Variables.lang]!
    }
    
    static let _newArticle: [String : String] = [
        LangCode.en : "New Article",
        LangCode.ja : "新しい文章",
        LangCode.es : "Articulo Nuevo",
        LangCode.ru : "Новая Статья",
        LangCode.ko : "새 문장",
        LangCode.de : "Neuer Artikel",
    ]
    static var newArticle: String {
        return Strings._articles[Variables.lang]!
    }
    
    static let _phraseReview: [String : String] = [
        LangCode.en : "Phrase Review",
        LangCode.ja : "フレーズレビュー",
        LangCode.es : "Revisión de frases",
        LangCode.ru : "Обзор фраз",
        LangCode.ko : "구문 복습",
        LangCode.de : "Phrasenüberprüfung",
    ]
    static var phraseReview: String {
        return Strings._phraseReview[Variables.lang]!
    }
    
    static let _reading: [String : String] = [
        LangCode.en : "Reading",
        LangCode.ja : "読解",
        LangCode.es : "Leer",
        LangCode.ru : "Чтение",
        LangCode.ko : "독해",
        LangCode.de : "Lektüre",
    ]
    static var reading: String {
        return Strings._reading[Variables.lang]!
    }
    
    static let _interpretation: [String : String] = [
        LangCode.en : "Interpretation",
        LangCode.ja : "通訳",
        LangCode.es : "Interpretación",
        LangCode.ru : "Интерпретация",
        LangCode.ko : "통역",
        LangCode.de : "Deutung",
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
        LangCode.ru : "Да",
        LangCode.ko : "예",
        LangCode.de : "Ja",
    ]
    static var ok: String {
        return Strings._ok[Variables.lang]!
    }
    
    private static let _done: [String : String] = [
        LangCode.en : "Done",
        LangCode.ja : "完了",
        LangCode.es : "Hecho",
        LangCode.ru : "Сделанный",
        LangCode.ko : "완료",
        LangCode.de : "Erledigt",
    ]
    static var done: String {
        return Strings._done[Variables.lang]!
    }
    
    private static let _cancel: [String : String] = [
        LangCode.en : "Cancel",
        LangCode.ja : "キャンセル",
        LangCode.es : "Cancelar",
        LangCode.ru : "Отмена",
        LangCode.ko : "취소",
        LangCode.de : "Stornieren",
    ]
    static var cancel: String {
        return Strings._cancel[Variables.lang]!
    }
    
    // MARK: - Alert Prompts
    
    private static let _exitWithoutSavingAlertTitles: [String : String] = [
        LangCode.en : "Leave without Saving",
        LangCode.ja : "保存せずに終了",
        LangCode.es : "Salir sin Guardar",
        LangCode.ru : "Выйти без сохранения",
        LangCode.ko : "저장하지 않고 종료",
        LangCode.de : "Beenden ohne Speichern",
    ]
    static var exitWithoutSavingAlertTitle: String {
        return Strings._exitWithoutSavingAlertTitles[Variables.lang]!
    }
    
    private static let _exitWithoutSavingAlertBodies: [String : String] = [
        LangCode.en : "Edits have been made. Leave without saving them?",
        LangCode.ja : "編集が行われました。 保存せずに終了しますか?",
        LangCode.es : "Se han hecho modificaciones. ¿Sale sin guardarlas?",
        LangCode.ru : "Внесены модификации. Выход без сохранения?",
        LangCode.ko : "편집이 이루어졌습니다. 저장하지 않고 종료 하시겠습니까?",
        LangCode.de : "Es wurde eine Bearbeitung vorgenommen. Beenden ohne Speichern?",
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
        LangCode.ru : "Добавить новое слово",
        LangCode.ko : "새 단어 추가",
        LangCode.de : "Neues Wort hinzufügen",
    ]
    static var addingNewWordAlertTitle: String {
        return Strings._addingNewWordAlertTitles[Variables.lang]!
    }
    
    private static let _addingNewWordAlertTextFieldPlaceholderForTexts: [String : String] = [
        LangCode.en : "Word",
        LangCode.ja : "単語",
        LangCode.es : "Palabra",
        LangCode.ru : "Слово",
        LangCode.ko : "단어",
        LangCode.de : "Wort",
    ]
    static var addingNewWordAlertTextFieldPlaceholderForText: String {
        return Strings._addingNewWordAlertTextFieldPlaceholderForTexts[Variables.lang]!
    }
    
    private static let _addingNewWordAlertTextFieldPlaceHolderForMeanings: [String : String] = [
        LangCode.en : "Meaning",
        LangCode.ja : "意味",
        LangCode.es : "Significado",
        LangCode.ru : "Значение",
        LangCode.ko : "의미",
        LangCode.de : "Bedeutung",
    ]
    static var addingNewWordAlertTextFieldPlaceHolderForMeaning: String {
        return Strings._addingNewWordAlertTextFieldPlaceHolderForMeanings[Variables.lang]!
    }
    
    private static let _addingNewWordAlertTextFieldPlaceHolderForNotes: [String : String] = [
        LangCode.en : "Notes",
        LangCode.ja : "ノート",
        LangCode.es : "Notas",
        LangCode.ru : "Ноты",
        LangCode.ko : "노트",
        LangCode.de : "Notizen",
    ]
    static var addingNewWordAlertTextFieldPlaceHolderForNote: String {
        return Strings._addingNewWordAlertTextFieldPlaceHolderForNotes[Variables.lang]!
    }
    
    // MARK: - Batch Adding
    
//    private static let _wordEditTextViewPrompts: [String : String] = [
//        LangCode.en : "Format：\nDate - Notes\n1. Word １\n2. Word 2\n\nDate - Notes\n1. Word １\n2. Word 2\n\n",
//        LangCode.ja : "フォーマット：\n日付 - ノート\n1. 単語１\n2. 単語2\n\n日付 - ノート\n1. 単語１\n2. 単語2\n\n",
//        LangCode.es : "Formato：\nFecha - ノート\n1. Palabra １\n2. Palabra 2\n\nFecha - ノート\n1. Palabra １\n2. Palabra 2\n\n",
//        LangCode.ru : "Формат：\nДата - ノート\n1. Слово １\n2. Слово 2\n\nДата - ノート\n1. Слово １\n2. Слово 2\n\n",
//        LangCode.ko : "형식: \n날짜 - 노트\n1. 단어 1\n2. 단어 2\n\n날짜 - 노트\n1. 단어 1\n2. 단어 2\n\n",
//    ]
//    static var wordEditTextViewPrompt: String {
//        return Strings._wordEditTextViewPrompts[Variables.lang]!
//    }
//
//    private static let _wordMeaningSeparators: [String : Substring.Element] = [
//        LangCode.en : ":",
//        LangCode.ja : " ",
//        LangCode.es : ":",
//        LangCode.ru : ":",
//        LangCode.ko : ":",
//    ]
//    static var wordMeaningSeparator: Substring.Element {
//        return Strings._wordMeaningSeparators[Variables.lang]!
//    }
//
    // MARK: - Bottom View / Text View
    
    private static let _newWordMenuItemStrings: [String : String] = [
        LangCode.en : "New Word",
        LangCode.ja : "新単語",
        LangCode.es : "Palabra Nueva",
        LangCode.ru : "Новое слово",
        LangCode.ko : "새 단어",
        LangCode.de : "Neues Wort",
    ]
    static var newWordMenuItemString: String {
        return Strings._newWordMenuItemStrings[Variables.lang]!
    }
    
    private static let _newWordBottomViewMeaningPrompts: [String : String] = [
        LangCode.en : "Also select/type the corresponding meaning",
        LangCode.ja : "相応する意味も選択/入力してください",
        LangCode.es : "Seleccione/ingrese también el significado correspondiente",
        LangCode.ru : "Также выберите/введите соответствующее значение",
        LangCode.ko : "해당하는 의미도 선택/입력해 주세요",
        LangCode.de : "Bitte wählen Sie auch die entsprechende Bedeutung aus/geben Sie sie ein",
    ]
    static var newWordBottomViewMeaningPrompt: String {
        return Strings._newWordBottomViewMeaningPrompts[Variables.lang]!
    }
}

extension Strings {
    
    // MARK: - Word Adding
    
    private static let _wordListPrompts: [String : String] = [
        LangCode.en : "Word List",
        LangCode.ja : "ワードリスト：",
        LangCode.es : "Lista de palabras",
        LangCode.ru : "Список слов",
        LangCode.ko : "워드 리스트",
        LangCode.de : "Wortliste",
    ]
    static var wordListPrompt: String {
        return Strings._wordListPrompts[Variables.lang]!
    }
    
    private static let _machineTranslationPrompts: [String : String] = [
        LangCode.en : "Machine translation",
        LangCode.ja : "機械翻訳",
        LangCode.es : "Traducción automática",
        LangCode.ru : "Машинный перевод",
        LangCode.ko : "기계 번역",
        LangCode.de : "Maschinenübersetzung",
    ]
    static var machineTranslationPrompt: String {
        return Strings._machineTranslationPrompts[Variables.lang]!
    }
    
    // MARK: - Article Adding
    
    private static let _articleTitlePrompts: [String : String] = [
        LangCode.en : "Title: ",
        LangCode.ja : "タイトル：",
        LangCode.es : "Título: ",
        LangCode.ru : "Заголовок: ",
        LangCode.ko : "제목: ",
        LangCode.de : "Titel: ",
    ]
    static var articleTitlePrompt: String {
        return Strings._articleTitlePrompts[Variables.lang]!
    }
    
    private static let _articleTopicPrompts: [String : String] = [
        LangCode.en : "Topic: ",
        LangCode.ja : "トピック：",
        LangCode.es : "Tema: ",
        LangCode.ru : "Тема: ",
        LangCode.ko : "주제: ",
        LangCode.de : "Thema: ",
    ]
    static var articleTopicPrompt: String {
        return Strings._articleTopicPrompts[Variables.lang]!
    }
    
    private static let _articleBodyPrompts: [String : String] = [
        LangCode.en : "Body: \n",
        LangCode.ja : "本文：\n",
        LangCode.es : "Cuerpo: \n",
        LangCode.ru : "Тело: \n",
        LangCode.ko : "본문: \n",
        LangCode.de : "Textkörper: \n",
    ]
    static var articleBodyPrompt: String {
        return Strings._articleBodyPrompts[Variables.lang]!
    }
    
    private static let _articleSourcePrompts: [String : String] = [
        LangCode.en : "Source: ",
        LangCode.ja : "ソース：",
        LangCode.es : "Fuente: ",
        LangCode.ru : "Источник: ",
        LangCode.ko : "출처: ",
        LangCode.de : "Quelle: ",
    ]
    static var articleSourcePrompt: String {
        return Strings._articleSourcePrompts[Variables.lang]!
    }
    
    private static let _articleEditingTitles: [String : String] = [
        LangCode.en : "Article Editing",
        LangCode.ja : "文章編集",
        LangCode.es : "Edición de Artículos",
        LangCode.ru : "Редактирование Статьи",
        LangCode.ko : "문장 편집",
        LangCode.de : "Artikelbearbeitung",
    ]
    static var articleEditingTitle: String {
        return Strings._articleEditingTitles[Variables.lang]!
    }
    
    static let windowsNewLineSymbol: String = "\r\n"
    static let macNewLineSymbol: String = "\n\r"
}

extension Strings {
    
    // MARK: - Practicing
    
    static let maskToken: String = "[MASK]"
    static let underscoreToken: String = String.init(repeating: "\u{FF3F}", count: 6)
    
    private static let _meaningSelectionAndFillingPracticePrompt: [String : String] = [
        LangCode.en : "The meaning of\n\(Strings.maskToken)?",
        LangCode.ja : "\(Strings.maskToken)\nの意味は？",
        LangCode.es : "¿El significado de\n\(Strings.maskToken)?",
        LangCode.ru : "Что означает\n\(Strings.maskToken)?",
        LangCode.ko : "\(Strings.maskToken)\n의 의미는?",
        LangCode.de : "Die Bedeutung von\n\(Strings.maskToken)?",
    ]
    static var meaningSelectionAndFillingPracticePrompt: String {
        return Strings._meaningSelectionAndFillingPracticePrompt[Variables.lang]!
    }
        
    private static let _referenceLabelPrefices: [String : String] = [
        LangCode.en : "Reference: ",
        LangCode.ja : "参考：",
        LangCode.es : "Referencia: ",
        LangCode.ru : "Ссылка: ",
        LangCode.ko : "참고: ",
        LangCode.de : "Referenz: ",
    ]
    static var referenceLabelPrefix: String {
        return Strings._referenceLabelPrefices[Variables.lang]!
    }
    
    private static let _contextSelectionPracticePrompts: [String : String] = [
        LangCode.en : "Select a proper word.",
        LangCode.ja : "適切な単語を選んでください。",
        LangCode.es : "Seleccione una palabra adecuada.",
        LangCode.ru : "Выберите подходящее слово.",
        LangCode.ko : "적절한 단어를 선택하십시오.",
        LangCode.de : "Wählen Sie ein passendes Wort aus.",
    ]
    static var contextSelectionPracticePrompt: String {
        return Strings._contextSelectionPracticePrompts[Variables.lang]!
    }
    
    private static let _accentSelectionPracticePrompts: [String : String] = [
        LangCode.en : "The accents for\n\(Strings.maskToken)?",
        LangCode.ja : "\(Strings.maskToken)\nのアクセントは？",
        LangCode.es : "¿Los acentos para\n\(Strings.maskToken)?",
        LangCode.ru : "Какие акценты для\n\(Strings.maskToken)?",
        LangCode.ko : "\(Strings.maskToken)\n의 악센트는?",
        LangCode.de : "Die Akzente für\n\(Strings.maskToken)?",
    ]
    static var accentSelectionPracticePrompt: String {
        return Strings._accentSelectionPracticePrompts[Variables.lang]!
    }
    
    private static let _reorderingPracticePrompts: [String : String] = [
        LangCode.en : "Reorder the words.",
        LangCode.ja : "単語を並べ替えてください。",
        LangCode.es : "Reordene las palabras.",
        LangCode.ru : "Измените порядок слов.",
        LangCode.ko : "단어를 재정렬하십시오.",
        LangCode.de : "Ordnen Sie die Wörter neu.",
    ]
    static var reorderingPracticePrompt: String {
        return Strings._reorderingPracticePrompts[Variables.lang]!
    }
    
    private static let _translationPracticePrompts: [String : String] = [
        LangCode.en : "Interpret the paragraph.",
        LangCode.ja : "この段落を通訳してください。",
        LangCode.es : "Interprete el párrafo.",
        LangCode.ru : "интерпретировать пункт.",
        LangCode.ko : "이 단락을 통역하십시오.",
        LangCode.de : "Interpretieren Sie den Absatz.",
    ]
    static var translationPracticePrompt: String {
        return Strings._translationPracticePrompts[Variables.lang]!
    }
    
    private static let _translationTokens: [String : String] = [
        LangCode.en : "Translation",
        LangCode.ja : "訳文",
        LangCode.es : "Traducción",
        LangCode.ru : "Перевод",
        LangCode.ko : "번역",
        LangCode.de : "Übersetzung",
    ]
    static var translationToken: String {
        return Strings._translationTokens[Variables.lang]!
    }
    
    private static let _machineTranslationTokens: [String : String] = [
        LangCode.en : "Machine translation",
        LangCode.ja : "機械翻訳",
        LangCode.es : "Traducción automática",
        LangCode.ru : "Машинный перевод",
        LangCode.ko : "기계 번역",
        LangCode.de : "Maschinenübersetzung",
    ]
    static var machineTranslationToken: String {
        return Strings._machineTranslationTokens[Variables.lang]!
    }
    
    private static let _machineTranslationErrorTokens: [String : String] = [
        LangCode.en : "Machine translation error",
        LangCode.ja : "機械翻訳エラー",
        LangCode.es : "Error de traducción automática",
        LangCode.ru : "Ошибка машинного перевода",
        LangCode.ko : "기계 번역 오류",
        LangCode.de : "Fehler bei der maschinellen Übersetzung",
    ]
    static var machineTranslationErrorToken: String {
        return Strings._machineTranslationErrorTokens[Variables.lang]!
    }
        
    private static let _textsForPausedPractice: [String : String] = [
        LangCode.en : "Practice paused.",
        LangCode.ja : "練習を一時停止しました。",
        LangCode.es : "Práctica en pausa.",
        LangCode.ru : "Практика приостановлена.",
        LangCode.ko : "연습을 일시중지했습니다.",
        LangCode.de : "Das Training wurde unterbrochen.",
    ]
    static var textForPausedPractice: String {
        return Strings._textsForPausedPractice[Variables.lang]!
    }
    
    // MARK: - Timing
        
    private static let _timeUpAlertTitles: [String : String] = [
        LangCode.en : "Time Up",
        LangCode.ja : "タイムアップ",
        LangCode.es : "Se Acabó el Tiempo",
        LangCode.ru : "Время вышло",
        LangCode.ko : "타임업",
        LangCode.de : "Zeit vorbei",
    ]
    static var timeUpAlertTitle: String {
        return Strings._timeUpAlertTitles[Variables.lang]!
    }
    
    private static let _timeUpAlertBodies: [String : String] = [
        LangCode.en : "You have practiced for \(Strings.maskToken) minutes. Continue practicing?",
        LangCode.ja : "もう\(Strings.maskToken)分練習しました。練習を続けますか？",
        LangCode.es : "¿Ha practicado por \(Strings.maskToken) minutos. Siga practicando?",
        LangCode.ru : "Вы тренировались в течение \(Strings.maskToken) минут(ы/a). Продолжай практиковаться?",
        LangCode.ko : "이제 \(Strings.maskToken)분간 연습했습니다. 연습을 계속하시겠습니까?",
        LangCode.de : "Sie haben \(Strings.maskToken) Minuten lang geübt. Weiter üben?",
    ]
    static var timeUpAlertBody: String {
        return Strings._timeUpAlertBodies[Variables.lang]!
    }
    
    private static let _maxTimeUpAlertBodies: [String : String] = [
        LangCode.en : "You have practiced for \(Strings.maskToken) minutes. Take a break.",
        LangCode.ja : "もう\(Strings.maskToken)分練習しました。少し休んでください。",
        LangCode.es : "Ya ha practicado por \(Strings.maskToken) minutos. Tome un descanso.",
        LangCode.ru : "Вы уже тренировались \(Strings.maskToken) минут. Сделайте перерыв.",
        LangCode.ko : "이제 \(Strings.maskToken)분간 연습했습니다. 조금 쉬십시오.",
        LangCode.de : "Sie haben \(Strings.maskToken) Minuten lang geübt. Machen Sie eine Pause.",
    ]
    static var maxTimeUpAlertBody: String {
        return Strings._maxTimeUpAlertBodies[Variables.lang]!
    }
}

extension Strings {
    static let _wordSeparators: [String : String] = [
        LangCode.en: " ",
        LangCode.ja: "",
        LangCode.es: " ",
        LangCode.ru: " ",
        LangCode.ko: " ",
        LangCode.de: " ",
    ]
    static var wordSeparator: String{
        return Strings._wordSeparators[Variables.lang]!
    }
    
    private static let _subsentenceSeparators: [String : String] = [
        LangCode.en: ",",
        LangCode.ja: "、",
        LangCode.es: ",",
        LangCode.ru: ",",
        LangCode.ko: ",",
        LangCode.de: ",",
    ]
    static var subsentenceSeparator: String{
        return Strings._subsentenceSeparators[Variables.lang]!
    }
}

struct Identifiers {
    
//    static let historyTableCellIdentifier: String = "historyTableCellIdentifier"
    
    // MARK: - UICollectionViewCell Identifiers
    
    static let langCellIdentifier: String = "languageCell"
    static let wordBankItemCellIdentifier: String = "wordBankItem"
    
    // MARK: - UITableViewCell Identifiers
    
    static let wordsTableCellIdentifier: String = "wordsTableCellIdentifier"
    static let readingTableCellIdentifier: String = "readingTableCellIdentifier"
    
    // MARK: - UITableViewHeaderFooterView Identifiers
    
    static let tableHeaderViewIdentifier: String = "tableHeaderViewIdentifier"
    static let readingEditTableCellIdentifier: String = "readingEditTableCellIdentifier"
    
}

struct Tokens {
    
    // https://japanese.awaisora.com/josi-itirannhyou/
    // TODO: - Update.
    private static let _japaneseParticles: String = "が・の・を・に・へ・と・から・より・で・"
        + "の・に・と・や・し・やら・か・なり・だの・とか・も・"
        + "ばかり・まで・だけ・さえ・ほど・くらい・ぐらい・など・なんか・なんて・なり・やら・か・ぞ・し・ばし・がてら・なぞ・なんぞ・ずつ・のみ・きり・や・だに・すら・"
        + "は・も・こそ・しか・でも・ほか・だって・"
        + "ば と ても でも けれど けれども が のに ので から し て で なり ながら たり だり つつ ところで まま ものの や とも ども に を・".replacingOccurrences(of: " ", with: "・")
        + "か・かい・な・とも・の・ぞ・ぜ・や・よ・ね・さ・のに・やら・が・ものか・もんか・わ・かしら・って・ってば・"
        + "さ・よ・ね・ねえ・な・なあ・を・や・ろ・い・ら・し・"
        + "の から ぞ ほど ばかり だけ が".replacingOccurrences(of: " ", with: "・")
    static let japaneseParticles: [String] = [String](Set(Tokens._japaneseParticles.split(with: "・")))
    
    // TODO: - it's only a temporary solution.
    
    static let _englishWordsToFilterInContentCardGeneration = [
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
    ]
    
    static let _spanishWordsToFilterInContentCardGeneration = [
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
        "á", "é", "í", "ó", "ú", "ü", "ñ",
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
        "Á", "É", "Í", "Ó", "Ú", "Ü", "Ñ"
    ]
    static let _russianWordsToFilterInContentCardGeneration = [
        "а", "б", "в", "г", "д", "е", "ё", "ж", "з", "и", "й", "к", "л", "м", "н", "о", "п", "р", "с", "т", "у", "ф", "х", "ц", "ч", "ш", "щ", "ъ", "ы", "ь", "э", "ю", "я",
        "А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й", "К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я"
    ]
    static let _germanWordsToFilterInContentCardGeneration = [
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
        "ä", "ö", "ü", "ß",
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
        "Ä", "Ö", "Ü", "ẞ"
    ] + [
        "der", "die", "das", "die",   // Nominative Case (masculine, feminine, neuter, plural)
        "den", "die", "das", "die",   // Accusative Case (masculine, feminine, neuter, plural)
        "dem", "der", "dem", "den",   // Dative Case (masculine, feminine, neuter, plural)
        "des", "der", "des", "der",    // Genitive Case (masculine, feminine, neuter, plural)
        
        "ein", "eine", "ein",      // Nominative Case (masculine, feminine, neuter)
        "einen", "eine", "ein",    // Accusative Case (masculine, feminine, neuter)
        "einem", "einer", "einem",  // Dative Case (masculine, feminine, neuter)
        "eines", "einer", "eines",   // Genitive Case (masculine, feminine, neuter)
    ]
    static let wordsToFilterInContentCardGeneration: Set<String> = Set(
        Tokens._englishWordsToFilterInContentCardGeneration
        + Tokens._spanishWordsToFilterInContentCardGeneration
        + Tokens._russianWordsToFilterInContentCardGeneration
        + Tokens._germanWordsToFilterInContentCardGeneration
    )
    
    static let chatgptToken: String = "[ChatGPT]"
    
}
