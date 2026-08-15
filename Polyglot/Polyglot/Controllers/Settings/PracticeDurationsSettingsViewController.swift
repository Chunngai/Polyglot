//
//  PracticeDurationsSettingsViewController.swift
//  Polyglot
//
//  Created by Ho on 7/5/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import UIKit

protocol PracticeDurationsSettingsViewControllerDelegate: AnyObject {
    func practiceDurationsDidUpdate(
        listening: Int,
        videoShadowing: Int,
        speaking: Int,
        reading: Int,
        podcast: Int
    )
}

class PracticeDurationsSettingsViewController: SettingsViewController {

    weak var delegate: PracticeDurationsSettingsViewControllerDelegate?

    override func saveSettings() {
        delegate?.practiceDurationsDidUpdate(
            listening: Int((cells[0][0] as! SettingsSlidingCell).slider.value),
            videoShadowing: Int((cells[0][1] as! SettingsSlidingCell).slider.value),
            speaking: Int((cells[0][2] as! SettingsSlidingCell).slider.value),
            reading: Int((cells[0][3] as! SettingsSlidingCell).slider.value),
            podcast: Int((cells[0][4] as! SettingsSlidingCell).slider.value)
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        headers = [nil]
        cells = [
            [
                {
                    let cell = SettingsSlidingCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = Images.listeningPracticeImage
                    cell.step = 5
                    cell.slider.minimumValue = 5
                    cell.slider.maximumValue = 30
                    cell.slider.value = Float(LangCode.currentLanguage.configs.listeningPracticeDuration)
                    cell.formatingFunc = { (sliderVal: Float) -> String in
                        return "\(String(Int(sliderVal))) mins"  // TODO: - Update localization
                    }
                    cell.label.text = cell.formatingFunc(cell.slider.value)
                    return cell
                }(),
                {
                    let cell = SettingsSlidingCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = Images.videoShadowingPracticeImage
                    cell.step = 5
                    cell.slider.minimumValue = 5
                    cell.slider.maximumValue = 30
                    cell.slider.value = Float(LangCode.currentLanguage.configs.videoShadowingPracticeDuration)
                    cell.formatingFunc = { (sliderVal: Float) -> String in
                        return "\(String(Int(sliderVal))) mins"  // TODO: - Update localization
                    }
                    cell.label.text = cell.formatingFunc(cell.slider.value)
                    return cell
                }(),
                {
                    let cell = SettingsSlidingCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = Images.translationPracticeImage
                    cell.step = 5
                    cell.slider.minimumValue = 5
                    cell.slider.maximumValue = 30
                    cell.slider.value = Float(LangCode.currentLanguage.configs.speakingPracticeDuration)
                    cell.formatingFunc = { (sliderVal: Float) -> String in
                        return "\(String(Int(sliderVal))) mins"  // TODO: - Update localization
                    }
                    cell.label.text = cell.formatingFunc(cell.slider.value)
                    return cell
                }(),
                {
                    let cell = SettingsSlidingCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = Images.readingPracticeImage
                    cell.step = 5
                    cell.slider.minimumValue = 5
                    cell.slider.maximumValue = 30
                    cell.slider.value = Float(LangCode.currentLanguage.configs.readingPracticeDuration)
                    cell.formatingFunc = { (sliderVal: Float) -> String in
                        return "\(String(Int(sliderVal))) mins"  // TODO: - Update localization
                    }
                    cell.label.text = cell.formatingFunc(cell.slider.value)
                    return cell
                }(),
                {
                    let cell = SettingsSlidingCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = Images.podcastPracticeImage
                    cell.step = 5
                    cell.slider.minimumValue = 5
                    cell.slider.maximumValue = 30
                    cell.slider.value = Float(LangCode.currentLanguage.configs.podcastPracticeDuration)
                    cell.formatingFunc = { (sliderVal: Float) -> String in
                        return "\(String(Int(sliderVal))) mins"  // TODO: - Update localization
                    }
                    cell.label.text = cell.formatingFunc(cell.slider.value)
                    return cell
                }()
            ]
        ]
    }

    override func updateViews() {
        super.updateViews()
        navigationItem.title = "Practice Durations"  // TODO: - Update localization
    }

}
