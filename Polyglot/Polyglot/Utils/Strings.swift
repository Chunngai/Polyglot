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
    
    static let _zhStrings: [LangCode : String] = [
        LangCode.en : "Chinese",
        LangCode.ja : "中国語",
        LangCode.es : "Chino",
        LangCode.ru : "Китайский",
        LangCode.ko : "중국어",
        LangCode.de : "Chinesisch",
    ]
    static var zhString: String {
        return Strings._zhStrings[LangCode.currentLanguage]!
    }
    
    static let _enStrings: [LangCode : String] = [
        LangCode.en : "English",
        LangCode.ja : "英語",
        LangCode.es : "Inglés",
        LangCode.ru : "Английский",
        LangCode.ko : "영어",
        LangCode.de : "Englisch",
    ]
    static var enString: String {
        return Strings._enStrings[LangCode.currentLanguage]!
    }
    
    static let _jaStrings: [LangCode : String] = [
        LangCode.en : "Japanese",
        LangCode.ja : "日本語",
        LangCode.es : "Japonés",
        LangCode.ru : "Японский",
        LangCode.ko : "일본어",
        LangCode.de : "Japanisch",
    ]
    static var jaString: String {
        return Strings._jaStrings[LangCode.currentLanguage]!
    }
    
    static let _esStrings: [LangCode : String] = [
        LangCode.en : "Spanish",
        LangCode.ja : "スペイン語",
        LangCode.es : "Español",
        LangCode.ru : "Испанский",
        LangCode.ko : "스페인어",
        LangCode.de : "Spanisch",
    ]
    static var esString: String {
        return Strings._esStrings[LangCode.currentLanguage]!
    }
    
    static let _ruStrings: [LangCode : String] = [
        LangCode.en : "Russian",
        LangCode.ja : "ロシア語",
        LangCode.es : "Ruso",
        LangCode.ru : "Русский",
        LangCode.ko : "러시아어",
        LangCode.de : "Russisch",
    ]
    static var ruString: String {
        return Strings._ruStrings[LangCode.currentLanguage]!
    }
    
    static let _koStrings: [LangCode : String] = [
        LangCode.en : "Korean",
        LangCode.ja : "韓国語",
        LangCode.es : "Coreano",
        LangCode.ru : "Корейский",
        LangCode.ko : "한국어",
        LangCode.de : "Koreanisch",
    ]
    static var koString: String {
        return Strings._koStrings[LangCode.currentLanguage]!
    }
    
    static let _deStrings: [LangCode : String] = [
        LangCode.en : "German",
        LangCode.ja : "ドイツ語",
        LangCode.es : "Alemán",
        LangCode.ru : "Немецкий",
        LangCode.ko : "독일어",
        LangCode.de : "Deutsch",
    ]
    static var deString: String {
        return Strings._deStrings[LangCode.currentLanguage]!
    }

    static var languageNamesOfAllLanguages: [LangCode: [LangCode: String]] = [
        LangCode.zh : Strings._zhStrings,
        LangCode.en : Strings._enStrings,
        LangCode.ja : Strings._jaStrings,
        LangCode.es : Strings._esStrings,
        LangCode.ru : Strings._ruStrings,
        LangCode.ko : Strings._koStrings,
        LangCode.de : Strings._deStrings,
    ]
}

extension Strings {
    
    // MARK: - Home Texts
    
    static let _homeTitles: [LangCode : String] = [
        LangCode.en : "Home",
        LangCode.ja : "ホーム",
        LangCode.es : "Inicio",
        LangCode.ru : "Главная",
        LangCode.ko : "홈",
        LangCode.de : "Startseite",
    ]
    static var homeTitle: String {
        return Strings._homeTitles[LangCode.currentLanguage]!
    }
    
    static let _languageSelectionViewControllerTitle: [LangCode: String] = [
        LangCode.en : "Languages",
        LangCode.ja : "言語",
        LangCode.es : "Idiomas",
        LangCode.ru : "Языки",
        LangCode.ko : "언어",
        LangCode.de : "Sprachen",
    ]
    static var languageSelectionViewControllerTitle: String {
        return Strings._languageSelectionViewControllerTitle[LangCode.currentLanguage]!
    }
    
    static let _phrases: [LangCode : String] = [
        LangCode.en : "Phrases",
        LangCode.ja : "フレーズ",
        LangCode.es : "Frases",
        LangCode.ru : "Фразы",
        LangCode.ko : "문구",
        LangCode.de : "Sätze",
    ]
    static var phrases: String {
        return Strings._phrases[LangCode.currentLanguage]!
    }
    
    static let _articles: [LangCode : String] = [
        LangCode.en : "Articles",
        LangCode.ja : "記事",
        LangCode.es : "Artículos",
        LangCode.ru : "Статьи",
        LangCode.ko : "기사",
        LangCode.de : "Artikel",
    ]
    static var articles: String {
        return Strings._articles[LangCode.currentLanguage]!
    }
    
    static let _articleAdding: [LangCode : String] = [
        LangCode.en : "Add a new article",
        LangCode.ja : "新しい記事を追加してください",
        LangCode.es : "Añade un nuevo artículo",
        LangCode.ru : "Добавьте новую статью",
        LangCode.ko : "새로운 기사를 추가하세요",
        LangCode.de : "Neuen Artikel hinzufügen",
    ]
    static var articleAdding: String {
        return Strings._articleAdding[LangCode.currentLanguage]!
    }
    
    static let _phraseReview: [LangCode : String] = [
        LangCode.en : "Phrase Review",
        LangCode.ja : "フレーズレビュー",
        LangCode.es : "Revisión de frases",
        LangCode.ru : "Обзор фраз",
        LangCode.ko : "구문 복습",
        LangCode.de : "Phrasenüberprüfung",
    ]
    static var phraseReview: String {
        return Strings._phraseReview[LangCode.currentLanguage]!
    }
    
    static let _reading: [LangCode : String] = [
        LangCode.en : "Reading",
        LangCode.ja : "読むこと",
        LangCode.es : "Leer",
        LangCode.ru : "Чтение",
        LangCode.ko : "읽기",
        LangCode.de : "Lesen",
    ]
    static var reading: String {
        return Strings._reading[LangCode.currentLanguage]!
    }
    
    static let _listening: [LangCode : String] = [
        LangCode.en : "Listening",
        LangCode.ja : "聞くこと",
        LangCode.es : "Escuchar",
        LangCode.ru : "Слушание",
        LangCode.ko : "듣기",
        LangCode.de : "Hören",
    ]
    static var listening: String {
        return Strings._listening[LangCode.currentLanguage]!
    }
    
    static let _speaking: [LangCode : String] = [
        LangCode.en : "Speaking",
        LangCode.ja : "話すこと",
        LangCode.es : "Hablar",
        LangCode.ru : "Разговор",
        LangCode.ko : "말하기",
        LangCode.de : "Sprechen",
    ]
    static var speaking: String {
        return Strings._speaking[LangCode.currentLanguage]!
    }
    
    static let _recentPractice: [LangCode : String] = [
        LangCode.en : "Recent Practice",
        LangCode.ja : "最近の練習",
        LangCode.es : "Práctica Reciente",
        LangCode.ru : "Недавняя Практика",
        LangCode.ko : "최근 연습",
        LangCode.de : "Aktuelle Praxis",
    ]
    static var recentPractice: String {
        return Strings._recentPractice[LangCode.currentLanguage]!
    }
    
    static let _configurations: [LangCode : String] = [
        LangCode.en : "Configurations",
        LangCode.ja : "設定",
        LangCode.es : "Configuraciones",
        LangCode.ru : "Конфигурации",
        LangCode.ko : "설정",
        LangCode.de : "Konfigurationen",
    ]
    static var configurations: String {
        return Strings._configurations[LangCode.currentLanguage]!
    }
}

extension Strings {
    
    // MARK: - Alert Buttons
    
    private static let _ok: [LangCode : String] = [
        LangCode.en : "Ok",
        LangCode.ja : "はい",
        LangCode.es : "Sí",
        LangCode.ru : "Да",
        LangCode.ko : "예",
        LangCode.de : "Ja",
    ]
    static var ok: String {
        return Strings._ok[LangCode.currentLanguage]!
    }
    
    private static let _done: [LangCode : String] = [
        LangCode.en : "Done",
        LangCode.ja : "完了",
        LangCode.es : "Hecho",
        LangCode.ru : "Сделанный",
        LangCode.ko : "완료",
        LangCode.de : "Erledigt",
    ]
    static var done: String {
        return Strings._done[LangCode.currentLanguage]!
    }
    
    private static let _cancel: [LangCode : String] = [
        LangCode.en : "Cancel",
        LangCode.ja : "キャンセル",
        LangCode.es : "Cancelar",
        LangCode.ru : "Отмена",
        LangCode.ko : "취소",
        LangCode.de : "Stornieren",
    ]
    static var cancel: String {
        return Strings._cancel[LangCode.currentLanguage]!
    }
    
    // MARK: - Alert Prompts
    
    private static let _exitWithoutSavingAlertTitles: [LangCode : String] = [
        LangCode.en : "Leave without Saving",
        LangCode.ja : "保存せずに終了",
        LangCode.es : "Salir sin Guardar",
        LangCode.ru : "Выйти без сохранения",
        LangCode.ko : "저장하지 않고 종료",
        LangCode.de : "Beenden ohne Speichern",
    ]
    static var exitWithoutSavingAlertTitle: String {
        return Strings._exitWithoutSavingAlertTitles[LangCode.currentLanguage]!
    }
    
    private static let _exitWithoutSavingAlertBodies: [LangCode : String] = [
        LangCode.en : "Edits have been made. Leave without saving them?",
        LangCode.ja : "編集が行われました。 保存せずに終了しますか?",
        LangCode.es : "Se han hecho modificaciones. ¿Sale sin guardarlas?",
        LangCode.ru : "Внесены модификации. Выход без сохранения?",
        LangCode.ko : "편집이 이루어졌습니다. 저장하지 않고 종료 하시겠습니까?",
        LangCode.de : "Es wurde eine Bearbeitung vorgenommen. Beenden ohne Speichern?",
    ]
    static var exitWithoutSavingAlertBody: String {
        return Strings._exitWithoutSavingAlertBodies[LangCode.currentLanguage]!
    }
}

extension Strings {
    
    // MARK: - Word Adding
    
    private static let _addingNewWordAlertTitles: [LangCode : String] = [
        LangCode.en : "Add a New Word",
        LangCode.ja : "新単語を追加",
        LangCode.es : "Agregar una Nueva Palabra",
        LangCode.ru : "Добавить новое слово",
        LangCode.ko : "새 단어 추가",
        LangCode.de : "Neues Wort hinzufügen",
    ]
    static var addingNewWordAlertTitle: String {
        return Strings._addingNewWordAlertTitles[LangCode.currentLanguage]!
    }
    
    private static let _addingNewWordAlertTextFieldPlaceholderForTexts: [LangCode : String] = [
        LangCode.en : "Word",
        LangCode.ja : "単語",
        LangCode.es : "Palabra",
        LangCode.ru : "Слово",
        LangCode.ko : "단어",
        LangCode.de : "Wort",
    ]
    static var addingNewWordAlertTextFieldPlaceholderForText: String {
        return Strings._addingNewWordAlertTextFieldPlaceholderForTexts[LangCode.currentLanguage]!
    }
    
    private static let _addingNewWordAlertTextFieldPlaceHolderForMeanings: [LangCode : String] = [
        LangCode.en : "Meaning",
        LangCode.ja : "意味",
        LangCode.es : "Significado",
        LangCode.ru : "Значение",
        LangCode.ko : "의미",
        LangCode.de : "Bedeutung",
    ]
    static var addingNewWordAlertTextFieldPlaceHolderForMeaning: String {
        return Strings._addingNewWordAlertTextFieldPlaceHolderForMeanings[LangCode.currentLanguage]!
    }
    
    private static let _addingNewWordAlertTextFieldPlaceHolderForNotes: [LangCode : String] = [
        LangCode.en : "Notes",
        LangCode.ja : "ノート",
        LangCode.es : "Notas",
        LangCode.ru : "Ноты",
        LangCode.ko : "노트",
        LangCode.de : "Notizen",
    ]
    static var addingNewWordAlertTextFieldPlaceHolderForNote: String {
        return Strings._addingNewWordAlertTextFieldPlaceHolderForNotes[LangCode.currentLanguage]!
    }
    
    // MARK: - Bottom View / Text View
    
    private static let _newWordMenuItemStrings: [LangCode : String] = [
        LangCode.en : "New Word",
        LangCode.ja : "新単語",
        LangCode.es : "Palabra Nueva",
        LangCode.ru : "Новое слово",
        LangCode.ko : "새 단어",
        LangCode.de : "Neues Wort",
    ]
    static var newWordMenuItemString: String {
        return Strings._newWordMenuItemStrings[LangCode.currentLanguage]!
    }
    
    private static let _wordMeaningMenuItemStrings: [LangCode : String] = [
        LangCode.en : "Word Meaning",
        LangCode.ja : "言葉の意味",
        LangCode.es : "Significado de la Palabra",
        LangCode.ru : "Значение Слова",
        LangCode.ko : "단어 뜻",
        LangCode.de : "Bedeutung des Wortes",
    ]
    static var wordMeaningMenuItemString: String {
        return Strings._wordMeaningMenuItemStrings[LangCode.currentLanguage]!
    }
        
    private static let _wordMemorizationMenuItemStrings: [LangCode : String] = [
        LangCode.en : "Memorize",
        LangCode.ja : "記憶",
        LangCode.es : "Memorizar",
        LangCode.ru : "Запомнить",
        LangCode.ko : "기억",
        LangCode.de : "Auswendig Lernen",
    ]
    static var wordMemorizationMenuItemString: String {
        return Strings._wordMemorizationMenuItemStrings[LangCode.currentLanguage]!
    }
    
    static let wordMemorizationLanguageNamePlaceHolder: String = "[lang_name]"
    static let wordMemorizationWordPlaceHolder: String = "[word]"
    static let wordMemorizationPrompt: String = "Help me memorise the spelling of the \(Self.wordMemorizationLanguageNamePlaceHolder) word \"\(Self.wordMemorizationWordPlaceHolder)\" by providing \(Self.wordMemorizationLanguageNamePlaceHolder)/English words with similar/identical spelling/pronunciation, related words, or mnemonics."
    
    private static let _newWordBottomViewMeaningPrompts: [LangCode : String] = [
        LangCode.en : "Also select/type the corresponding meaning",
        LangCode.ja : "相応する意味も選択/入力してください",
        LangCode.es : "Seleccione/ingrese también el significado correspondiente",
        LangCode.ru : "Также выберите/введите соответствующее значение",
        LangCode.ko : "해당하는 의미도 선택/입력해 주세요",
        LangCode.de : "Bitte wählen Sie auch die entsprechende Bedeutung aus/geben Sie sie ein",
    ]
    static var newWordBottomViewMeaningPrompt: String {
        return Strings._newWordBottomViewMeaningPrompts[LangCode.currentLanguage]!
    }
}

extension Strings {
    
    // MARK: - Article Adding
    
    private static let _articleTitlePrompts: [LangCode : String] = [
        LangCode.en : "Title: ",
        LangCode.ja : "タイトル：",
        LangCode.es : "Título: ",
        LangCode.ru : "Заголовок: ",
        LangCode.ko : "제목: ",
        LangCode.de : "Titel: ",
    ]
    static var articleTitlePrompt: String {
        return Strings._articleTitlePrompts[LangCode.currentLanguage]!
    }
    
    private static let _articleTopicPrompts: [LangCode : String] = [
        LangCode.en : "Topic: ",
        LangCode.ja : "トピック：",
        LangCode.es : "Tema: ",
        LangCode.ru : "Тема: ",
        LangCode.ko : "주제: ",
        LangCode.de : "Thema: ",
    ]
    static var articleTopicPrompt: String {
        return Strings._articleTopicPrompts[LangCode.currentLanguage]!
    }
    
    private static let _articleBodyPrompts: [LangCode : String] = [
        LangCode.en : "Body:",
        LangCode.ja : "本文：",
        LangCode.es : "Cuerpo:",
        LangCode.ru : "Тело:",
        LangCode.ko : "본문:",
        LangCode.de : "Textkörper:",
    ]
    static var articleBodyPrompt: String {
        return Strings._articleBodyPrompts[LangCode.currentLanguage]!
    }
    
    private static let _articleSourcePrompts: [LangCode : String] = [
        LangCode.en : "Source: ",
        LangCode.ja : "ソース：",
        LangCode.es : "Fuente: ",
        LangCode.ru : "Источник: ",
        LangCode.ko : "출처: ",
        LangCode.de : "Quelle: ",
    ]
    static var articleSourcePrompt: String {
        return Strings._articleSourcePrompts[LangCode.currentLanguage]!
    }
    
    private static let _articleEditingTitles: [LangCode : String] = [
        LangCode.en : "Article Editing",
        LangCode.ja : "記事編集",
        LangCode.es : "Edición de Artículos",
        LangCode.ru : "Редактирование Статьи",
        LangCode.ko : "기사 편집",
        LangCode.de : "Artikelbearbeitung",
    ]
    static var articleEditingTitle: String {
        return Strings._articleEditingTitles[LangCode.currentLanguage]!
    }
    
    private static let _articleSplittingTitles: [LangCode : String] = [
        LangCode.en : "Split with Newlines",
        LangCode.ja : "改行で分割",
        LangCode.es : "Dividir con Nuevas Líneas",
        LangCode.ru : "Разделить с Помощью Новой Строки",
        LangCode.ko : "줄바꿈으로 분할",
        LangCode.de : "Mit Newlines Teilen",
    ]
    static var articleSplittingTitle: String {
        return Strings._articleSplittingTitles[LangCode.currentLanguage]!
    }
    
    static let windowsNewLineSymbol: String = "\r\n"
    static let macNewLineSymbol: String = "\n\r"
}

extension Strings {
    
    // MARK: - Practicing
    
    static let maskToken: String = "[MASK]"
    static let underscoreToken: String = String.init(repeating: "\u{FF3F}", count: 6)
    
    private static let _meaningSelectionAndFillingPracticePrompt: [LangCode : String] = [
        LangCode.en : "The meaning of\n\(Strings.maskToken)?",
        LangCode.ja : "\(Strings.maskToken)\nの意味は？",
        LangCode.es : "¿El significado de\n\(Strings.maskToken)?",
        LangCode.ru : "Что означает\n\(Strings.maskToken)?",
        LangCode.ko : "\(Strings.maskToken)\n의 의미는?",
        LangCode.de : "Die Bedeutung von\n\(Strings.maskToken)?",
    ]
    static var meaningSelectionAndFillingPracticePrompt: String {
        return Strings._meaningSelectionAndFillingPracticePrompt[LangCode.currentLanguage]!
    }
        
    private static let _referenceLabelPrefices: [LangCode : String] = [
        LangCode.en : "Reference: ",
        LangCode.ja : "参考：",
        LangCode.es : "Referencia: ",
        LangCode.ru : "Ссылка: ",
        LangCode.ko : "참고: ",
        LangCode.de : "Referenz: ",
    ]
    static var referenceLabelPrefix: String {
        return Strings._referenceLabelPrefices[LangCode.currentLanguage]!
    }
    
    private static let _contextSelectionPracticePrompts: [LangCode : String] = [
        LangCode.en : "Select a proper word.",
        LangCode.ja : "適切な単語を選んでください。",
        LangCode.es : "Seleccione una palabra adecuada.",
        LangCode.ru : "Выберите подходящее слово.",
        LangCode.ko : "적절한 단어를 선택하십시오.",
        LangCode.de : "Wählen Sie ein passendes Wort aus.",
    ]
    static var contextSelectionPracticePrompt: String {
        return Strings._contextSelectionPracticePrompts[LangCode.currentLanguage]!
    }
    
    private static let _accentSelectionPracticePrompts: [LangCode : String] = [
        LangCode.en : "The accents for\n\(Strings.maskToken)?",
        LangCode.ja : "\(Strings.maskToken)\nのアクセントは？",
        LangCode.es : "¿Los acentos para\n\(Strings.maskToken)?",
        LangCode.ru : "Какие акценты для\n\(Strings.maskToken)?",
        LangCode.ko : "\(Strings.maskToken)\n의 악센트는?",
        LangCode.de : "Die Akzente für\n\(Strings.maskToken)?",
    ]
    static var accentSelectionPracticePrompt: String {
        return Strings._accentSelectionPracticePrompts[LangCode.currentLanguage]!
    }
    
    private static let _reorderingPracticePrompts: [LangCode : String] = [
        LangCode.en : "Reorder the words.",
        LangCode.ja : "単語を並べ替えてください。",
        LangCode.es : "Reordene las palabras.",
        LangCode.ru : "Измените порядок слов.",
        LangCode.ko : "단어를 재정렬하십시오.",
        LangCode.de : "Ordnen Sie die Wörter neu.",
    ]
    static var reorderingPracticePrompt: String {
        return Strings._reorderingPracticePrompts[LangCode.currentLanguage]!
    }
    
    private static let _listeningAndRepeatPracticePrompts: [LangCode : String] = [
        LangCode.en : "Listening and Repeating",
        LangCode.ja : "聞き取りと繰り返し",
        LangCode.es : "Escucha y Repetición",
        LangCode.ru : "Прослушивание и Повторение",
        LangCode.ko : "청취와 반복",
        LangCode.de : "Hören und Wiederholung",
    ]
    static var listeningAndRepeatPracticePrompt: String {
        return Strings._listeningAndRepeatPracticePrompts[LangCode.currentLanguage]!
    }
    
    private static let _listenAndCompletePracticePrompts: [LangCode : String] = [
        LangCode.en : "Listening and completing",
        LangCode.ja : "聞き取りと完成",
        LangCode.es : "Escucha y completación",
        LangCode.ru : "Прослушивание и завершение",
        LangCode.ko : "청취와 완성",
        LangCode.de : "Hören und Vervollständigung",
    ]
    static var listenAndCompletePracticePrompt: String {
        return Strings._listenAndCompletePracticePrompts[LangCode.currentLanguage]!
    }
    
    static let _interpretationPracticePrompt: [LangCode : String] = [
        LangCode.en : "Interpretation",
        LangCode.ja : "通訳",
        LangCode.es : "Interpretación",
        LangCode.ru : "Интерпретация",
        LangCode.ko : "통역",
        LangCode.de : "Deutung",
    ]
    static var interpretationPracticePrompt: String {
        return Strings._interpretationPracticePrompt[LangCode.currentLanguage]!
    }
    
    static let _readingPracticePrompt: [LangCode : String] = [
        LangCode.en : "Read the text",
        LangCode.ja : "テキストを読んでください",
        LangCode.es : "Lee el texto",
        LangCode.ru : "Прочитайте текст",
        LangCode.ko : "텍스트를 읽어보세요",
        LangCode.de : "Lies den Text",
    ]
    static var readingPracticePrompt: String {
        return Strings._readingPracticePrompt[LangCode.currentLanguage]!
    }
    
    private static let _translationTokens: [LangCode : String] = [
        LangCode.en : "Translation",
        LangCode.ja : "訳文",
        LangCode.es : "Traducción",
        LangCode.ru : "Перевод",
        LangCode.ko : "번역",
        LangCode.de : "Übersetzung",
    ]
    static var translationToken: String {
        return Strings._translationTokens[LangCode.currentLanguage]!
    }
    
    private static let _machineTranslationTokens: [LangCode : String] = [
        LangCode.en : "Machine translation",
        LangCode.ja : "機械翻訳",
        LangCode.es : "Traducción automática",
        LangCode.ru : "Машинный перевод",
        LangCode.ko : "기계 번역",
        LangCode.de : "Maschinenübersetzung",
    ]
    static var machineTranslationToken: String {
        return Strings._machineTranslationTokens[LangCode.currentLanguage]!
    }
    
    private static let _machineTranslationErrorTokens: [LangCode : String] = [
        LangCode.en : "Machine translation error",
        LangCode.ja : "機械翻訳エラー",
        LangCode.es : "Error de traducción automática",
        LangCode.ru : "Ошибка машинного перевода",
        LangCode.ko : "기계 번역 오류",
        LangCode.de : "Fehler bei der maschinellen Übersetzung",
    ]
    static var machineTranslationErrorToken: String {
        return Strings._machineTranslationErrorTokens[LangCode.currentLanguage]!.uppercased()
    }
        
    private static let _textsForPausedPractice: [LangCode : String] = [
        LangCode.en : "Practice paused.",
        LangCode.ja : "練習を一時停止しました。",
        LangCode.es : "Práctica en pausa.",
        LangCode.ru : "Практика приостановлена.",
        LangCode.ko : "연습을 일시중지했습니다.",
        LangCode.de : "Das Training wurde unterbrochen.",
    ]
    static var textForPausedPractice: String {
        return Strings._textsForPausedPractice[LangCode.currentLanguage]!
    }
    
    private static let _GPTGeneratedContent: [LangCode : String] = [
        LangCode.en : "GPT-generated Content",
        LangCode.ja : "GPT生成コンテンツ",
        LangCode.es : "Contenido Generado por GPT",
        LangCode.ru : "Контент, Созданный с Помощью GPT",
        LangCode.ko : "GPT 생성 콘텐츠",
        LangCode.de : "GPT-generierter Inhalt",
    ]
    static var GPTGeneratedContent: String {
        return Strings._GPTGeneratedContent[LangCode.currentLanguage]!
    }
        
    private static let _reinforce: [LangCode : String] = [
        LangCode.en : "Reinforce",
        LangCode.ja : "強化",
        LangCode.es : "Reforzar",
        LangCode.ru : "Укрепить",
        LangCode.ko : "강화",
        LangCode.de : "Verstärken",
    ]
    static var reinforce: String {
        return Strings._reinforce[LangCode.currentLanguage]!
    }
    
    static let refreshingSymbol = "\u{21BB}"
    
    // MARK: - Timing
        
    private static let _timeUpAlertTitles: [LangCode : String] = [
        LangCode.en : "Time Up",
        LangCode.ja : "タイムアップ",
        LangCode.es : "Se Acabó el Tiempo",
        LangCode.ru : "Время вышло",
        LangCode.ko : "타임업",
        LangCode.de : "Zeit vorbei",
    ]
    static var timeUpAlertTitle: String {
        return Strings._timeUpAlertTitles[LangCode.currentLanguage]!
    }
    
    private static let _timeUpAlertBodies: [LangCode : String] = [
        LangCode.en : "You have practiced for \(Strings.maskToken) minutes. Continue practicing?",
        LangCode.ja : "もう\(Strings.maskToken)分練習しました。練習を続けますか？",
        LangCode.es : "¿Ha practicado por \(Strings.maskToken) minutos. Siga practicando?",
        LangCode.ru : "Вы тренировались в течение \(Strings.maskToken) минут(ы/a). Продолжай практиковаться?",
        LangCode.ko : "이제 \(Strings.maskToken)분간 연습했습니다. 연습을 계속하시겠습니까?",
        LangCode.de : "Sie haben \(Strings.maskToken) Minuten lang geübt. Weiter üben?",
    ]
    static var timeUpAlertBody: String {
        return Strings._timeUpAlertBodies[LangCode.currentLanguage]!
    }
    
    private static let _maxTimeUpAlertBodies: [LangCode : String] = [
        LangCode.en : "You have practiced for \(Strings.maskToken) minutes. Take a break.",
        LangCode.ja : "もう\(Strings.maskToken)分練習しました。少し休んでください。",
        LangCode.es : "Ya ha practicado por \(Strings.maskToken) minutos. Tome un descanso.",
        LangCode.ru : "Вы уже тренировались \(Strings.maskToken) минут. Сделайте перерыв.",
        LangCode.ko : "이제 \(Strings.maskToken)분간 연습했습니다. 조금 쉬십시오.",
        LangCode.de : "Sie haben \(Strings.maskToken) Minuten lang geübt. Machen Sie eine Pause.",
    ]
    static var maxTimeUpAlertBody: String {
        return Strings._maxTimeUpAlertBodies[LangCode.currentLanguage]!
    }
}

extension Strings {
    static let _wordSeparators: [LangCode : String] = [
        LangCode.en: " ",
        LangCode.ja: "",
        LangCode.es: " ",
        LangCode.ru: " ",
        LangCode.ko: " ",
        LangCode.de: " ",
    ]
    static var wordSeparator: String{
        return Strings._wordSeparators[LangCode.currentLanguage]!
    }
    
    private static let _subsentenceSeparators: [LangCode : String] = [
        LangCode.en: ",",
        LangCode.ja: "、",
        LangCode.es: ",",
        LangCode.ru: ",",
        LangCode.ko: ",",
        LangCode.de: ",",
    ]
    static var subsentenceSeparator: String {
        return Strings._subsentenceSeparators[LangCode.currentLanguage]!
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
        
        "ich", "du", "er", "sie", "es", "wir", "ihr"
    ]
    static let wordsToFilterInContentCardGeneration: Set<String> = Set(
        Tokens._englishWordsToFilterInContentCardGeneration
        + Tokens._spanishWordsToFilterInContentCardGeneration
        + Tokens._russianWordsToFilterInContentCardGeneration
        + Tokens._germanWordsToFilterInContentCardGeneration
    )
    
}
