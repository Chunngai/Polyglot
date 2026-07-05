//
//  PhraseReviewPracticeTypeSettingsViewController.swift
//  Polyglot
//
//  Created by Ho on 7/5/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import UIKit

protocol PhraseReviewPracticeTypeSettingsViewControllerDelegate: AnyObject {
    func phraseReviewPracticeTypesDidUpdate(_ enabledTypes: Set<WordPractice.PracticeType>)
}

class PhraseReviewPracticeTypeSettingsViewController: SettingsViewController {

    weak var delegate: PhraseReviewPracticeTypeSettingsViewControllerDelegate?

    private let orderedTypes: [WordPractice.PracticeType] = [
        .meaningSelection,
        .meaningFilling,
        .contextSelection,
        .reordering,
        .imageSelection,
        .imageFilling,
        .accentSelection
    ]

    private let typeImages: [WordPractice.PracticeType: UIImage?] = [
        .meaningSelection: UIImage(systemName: "list.bullet"),
        .meaningFilling:   UIImage(systemName: "pencil"),
        .contextSelection: UIImage(systemName: "text.bubble"),
        .reordering:       UIImage(systemName: "arrow.left.arrow.right"),
        .imageSelection:   UIImage(systemName: "photo"),
        .imageFilling:     UIImage(systemName: "photo.badge.plus"),
        .accentSelection:  UIImage(systemName: "textformat.abc")
    ]

    private let typeLabels: [WordPractice.PracticeType: String] = [
        .meaningSelection: "Meaning Selection",
        .meaningFilling:   "Meaning Filling",
        .contextSelection: "Context Selection",
        .reordering:       "Reordering",
        .imageSelection:   "Image Selection",
        .imageFilling:     "Image Filling",
        .accentSelection:  "Accent Selection"
    ]

    override func saveSettings() {
        var enabled = Set<WordPractice.PracticeType>()
        enabled.insert(.meaningSelection)  // Always on.
        for (index, type) in orderedTypes.enumerated() {
            if (cells[0][index] as! SettingsSwitchingCell).switchView.isOn {
                enabled.insert(type)
            }
        }
        delegate?.phraseReviewPracticeTypesDidUpdate(enabled)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let enabled = LangCode.currentLanguage.configs.phraseReviewEnabledPracticeTypes

        headers = [nil]
        cells = [
            orderedTypes.map { type in
                let cell = SettingsSwitchingCell(style: .default, reuseIdentifier: "")
                cell.imageView?.image = typeImages[type] ?? nil
                cell.switchView.isOn = type == .meaningSelection ? true : enabled.contains(type)
                cell.switchView.isEnabled = type != .meaningSelection
                cell.label.text = typeLabels[type]
                return cell
            }
        ]
    }

    override func updateViews() {
        super.updateViews()
        navigationItem.title = "Practice Types"  // TODO: - Update localization
    }

}
