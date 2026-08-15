//
//  PracticeRepetitionsSettingsViewController.swift
//  Polyglot
//
//  Created by Ho on 7/5/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import UIKit

protocol PracticeRepetitionsSettingsViewControllerDelegate: AnyObject {
    func practiceRepetitionsDidUpdate(
        word: Int,
        listening: Int,
        speaking: Int,
        phraseReviewDefaultSelectionCount: Int
    )
}

class PracticeRepetitionsSettingsViewController: SettingsViewController {

    weak var delegate: PracticeRepetitionsSettingsViewControllerDelegate?

    override func saveSettings() {
        delegate?.practiceRepetitionsDidUpdate(
            word: Int((cells[0][0] as! SettingsSlidingCell).slider.value),
            listening: Int((cells[0][1] as! SettingsSlidingCell).slider.value),
            speaking: Int((cells[0][2] as! SettingsSlidingCell).slider.value),
            phraseReviewDefaultSelectionCount: Int((cells[0][3] as! SettingsSlidingCell).slider.value)
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        headers = [nil]
        cells = [
            [
                {
                    let cell = SettingsSlidingCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = Images.wordPracticeImage
                    cell.step = 1
                    cell.slider.minimumValue = 0
                    cell.slider.maximumValue = 5
                    cell.slider.value = Float(LangCode.currentLanguage.configs.wordPracticeRepetition)
                    cell.formatingFunc = { (sliderVal: Float) -> String in
                        return "\(String(Int(sliderVal))) times"  // TODO: - Update localization
                    }
                    cell.label.text = cell.formatingFunc(cell.slider.value)
                    return cell
                }(),
                {
                    let cell = SettingsSlidingCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = Images.listeningPracticeImage
                    cell.step = 1
                    cell.slider.minimumValue = 0
                    cell.slider.maximumValue = 5
                    cell.slider.value = Float(LangCode.currentLanguage.configs.listeningPracticeRepetition)
                    cell.formatingFunc = { (sliderVal: Float) -> String in
                        return "\(String(Int(sliderVal))) times"  // TODO: - Update localization
                    }
                    cell.label.text = cell.formatingFunc(cell.slider.value)
                    return cell
                }(),
                {
                    let cell = SettingsSlidingCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = Images.translationPracticeImage
                    cell.step = 1
                    cell.slider.minimumValue = 0
                    cell.slider.maximumValue = 5
                    cell.slider.value = Float(LangCode.currentLanguage.configs.speakingPracticeRepetition)
                    cell.formatingFunc = { (sliderVal: Float) -> String in
                        return "\(String(Int(sliderVal))) times"  // TODO: - Update localization
                    }
                    cell.label.text = cell.formatingFunc(cell.slider.value)
                    return cell
                }(),
                {
                    let cell = SettingsSlidingCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = UIImage(systemName: "checklist")
                    cell.step = 1
                    cell.slider.minimumValue = 1
                    cell.slider.maximumValue = 20
                    cell.slider.value = Float(LangCode.currentLanguage.configs.phraseReviewDefaultSelectionCount)
                    cell.formatingFunc = { (sliderVal: Float) -> String in
                        return "\(String(Int(sliderVal))) words"  // TODO: - Update localization
                    }
                    cell.label.text = cell.formatingFunc(cell.slider.value)
                    return cell
                }()
            ]
        ]
    }

    override func updateViews() {
        super.updateViews()
        navigationItem.title = "Practice Repetitions"  // TODO: - Update localization
    }

}
