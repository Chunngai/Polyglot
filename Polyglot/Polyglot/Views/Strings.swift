//
//  Strings.swift
//  Polyglot
//
//  Created by Sola on 2022/12/20.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation
import UIKit

struct Assets {
    static let speechBubbleBackground = "speech_bubble"
    
    static let enIcon = "en"
    static let jaIcon = "ja"
    static let esIcon = "es"
    
    static let historyIcon = "history"
    
    static let background: String = "background"
}

struct Strings {
    
    static let mainPrimaryPrompt = NSAttributedString (
        string: "こんにちは",
        attributes: Attributes.primaryPromptAttributes
    )
    static let mainSecondaryPrompt = NSAttributedString (
        string: " 練習したい言語を選んでください",  // TODO: - The leading space is for aligning with the primary prompt.
        attributes: Attributes.secondaryPromptAttributes
    )
    
    static let menuPrimaryPrompt = NSAttributedString (
        string: "日本語",
        attributes: Attributes.primaryPromptAttributes
    )
    static let menuSecondaryPrompt = NSAttributedString (
        string: "  練習内容を選んでください",  // TODO: - The leading space is for aligning with the primary prompt.
        attributes: Attributes.secondaryPromptAttributes
    )
    
    static let en = NSAttributedString (
        string: "英語",
        attributes: Attributes.inactiveSelectionButtonTextAttributes
    )
    static let ja = NSAttributedString (
        string: "日本語",
        attributes: Attributes.inactiveSelectionButtonTextAttributes
    )
    static let es = NSAttributedString (
        string: "スペイン語",
        attributes: Attributes.inactiveSelectionButtonTextAttributes
    )
    
    static let words = "単語"
    static let reading = "読解"
    static let translation = "通訳"
    
//    static let articleTitlePrompt = NSMutableAttributedString (
//        string: "タイトル: ",
//        attributes: Attributes.newArticleTitleAttributes
//    )
//    static let articleBodyPrompt = NSMutableAttributedString (
//        string: "本文: \n",
//        attributes: Attributes.longTextAttributes
//    )
//    static let articleSourcePrompt = NSMutableAttributedString (
//        string: "ソース: ",
//        attributes: Attributes.longTextAttributes
//    )
    
    static let articleTitlePrompt: String = "タイトル: "
    static let articleBodyPrompt: String = "本文: \n"
    static let articleSourcePrompt: String = "ソース: "
    
    static let newWordBottomViewMeaningPrompt = "相応する意味も選択入力してください"
    
    static let newWord: String = "新単語"
    
    static let timeUpAlertTitle: String = "タイムアップ"
    static let timeUpAlertBody: String = "もう十分間練習しました。練習を続けますか。"
    static let maxTimeUpAlertBody: String = "もう三十分練習しました。少し休んでください。"
    
    static let ok: String = "はい"
    static let cancel: String = "キャンセル"
    
    static let saveNewWordsAlertTitle: String = "新単語情報"
    static let saveNewWordsAlertBodyPrefix: String = "総計: "
    
//    static let meaningFillingPracticeTextFieldPlaceHolder: String = "単語の意味をここに記入してください"
    
    static let maskToken: String = "[MASK]"
    static let meaningSelectionAndFillingPracticePromptSuffix: String = "は何と意味しますか"
    static let contextSelectionPracticePrompt: String = "適切な単語を選んでください"
    
    static let meaningFillingPracticeReferenceLabelPrefix: String = "参考: "
    
    static let exitWithoutSavingAlertTitle: String = "Exit without saving"
    static let exitWithoutSavingAlertBody: String = "Edits have been made. Exit without saving them?"
    
    static let newWordAlreadyAddedAlertTitle: String = "Already marked as new word"
    static let newWordAlreadyAddedAlertBody: String = "The word [MASK] has been marked as a new word."
    
    static let meaningSelectionPractice: String = "単語 翻訳 (選択)"
    static let meaningFillingPractice: String = "単語 翻訳 (入力)"
    static let contextSelectionPractice: String = "単語 コンテスト"
    static let readingPractice: String = "読解"
    static let translationPractice: String = "通訳"
    
    static let translationPracticePrompt: String = "この文を日本語に\n通訳してください"
    
    static let wordEditTextViewPrompt: String = "フォーマット：\n日付 - ノート\n1. 単語１\n2. 単語2\n\n日付 - ノート\n1. 単語１\n2. 単語2\n\n"
    
    static let wordMeaningSeparator: Substring.Element = " "  // TODO: - Language specific or unify
    
    static let paraSeparator: String = "\n\n"
    static let textAndMeaningSeparator: String = "\n"
}

struct Identifiers {
    
    static let historyTableCellIdentifier: String = "historyTableCellIdentifier"
    
    static let wordsTableCellIdentifier: String = "wordsTableCellIdentifier"
    static let wordsTableHeaderViewIdentifier: String = "wordsTableHeaderViewIdentifier"
    
    static let readingTableCellIdentifier: String = "readingTableCellIdentifier"
    static let readingEditTableCellIdentifier: String = "readingEditTableCellIdentifier"
    
}
