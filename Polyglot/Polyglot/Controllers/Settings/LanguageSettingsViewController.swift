//
//  LanguageSettingsViewController.swift
//  Polyglot
//
//  Created by Ho on 8/22/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class LanguageSettingsViewController: SettingsViewController {
    
    var translationLangsForCurLang: [LangCode] {
        var langs = LangCode.learningLanguages
        langs.remove(at: LangCode.learningLanguages.firstIndex(of: LangCode.currentLanguage)!)
        langs = [LangCode.zh] + langs
        return langs
    }
    var selectedTranslationLang = LangCode.currentLanguage.configs.languageForTranslation

    var practiceType2isDuolingoOnly: [DuolingoOnlySelectionViewController.PracticeType: Bool] = [
        .shadowing: LangCode.currentLanguage.configs.isDuolingoOnlyForShadowing,
        .speaking: LangCode.currentLanguage.configs.isDuolingoOnlyForSpeaking,
        .reading: LangCode.currentLanguage.configs.isDuolingoOnlyForReading,
        .podcast: LangCode.currentLanguage.configs.isDuolingoOnlyForPodcast
    ]
    var textForDuolingoOnlyCell: String {
        var ss: [String] = []
        for (practiceType, isSelected) in practiceType2isDuolingoOnly {
            if isSelected {
                ss.append(practiceType.text)
            }
        }
        return ss.joined(separator: ", ")
    }
    var hasDuolingoArticles: Bool = false
    
    override func saveSettings() {
        LangCode.currentLanguage.configs = LangConfigs(
            
            languageForTranslation: selectedTranslationLang,
            
            voiceRate: (cells[1][0] as! SettingsSlidingCell).slider.value,
            slowVoiceRate: (cells[1][1] as! SettingsSlidingCell).slider.value,
            
            phraseReviewPracticeDuration: Int((cells[2][0] as! SettingsSlidingCell).slider.value),
            listeningPracticeDuration: Int((cells[2][1] as! SettingsSlidingCell).slider.value),
            speakingPracticeDuration: Int((cells[2][2] as! SettingsSlidingCell).slider.value),
            readingPracticeDuration: Int((cells[2][3] as! SettingsSlidingCell).slider.value),
            
            wordPracticeRepetition: Int((cells[3][0] as! SettingsSlidingCell).slider.value),
            listeningPracticeRepetition: Int((cells[3][1] as! SettingsSlidingCell).slider.value),
            speakingPracticeRepetition: Int((cells[3][2] as! SettingsSlidingCell).slider.value),

            isDuolingoOnlyForShadowing: practiceType2isDuolingoOnly[.shadowing],
            isDuolingoOnlyForSpeaking: practiceType2isDuolingoOnly[.speaking],
            isDuolingoOnlyForReading: practiceType2isDuolingoOnly[.reading],
            isDuolingoOnlyForPodcast: practiceType2isDuolingoOnly[.podcast],
            
            canGenerateTextsWithLLMsForPractices: (cells[4][0] as! SettingsSwitchingCell).switchView.isOn, 
            
            shouldRemindToAddNewArticles: (cells[5][0] as! SettingsSwitchingCell).switchView.isOn
            
        )
    }
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: - Update localization
        headers = [
            "Language for Translating \(LangCode.currentLanguage.rawValue) Texts",
            "Voice Rate for Synthesizing \(LangCode.currentLanguage.rawValue) Texts",
            "Practice Durations",
            "Practice Repetitions",
            "Duolingo Only",
            "Content Generation",
            "Reminders",
        ]
        cells = [
            // Language for translation.
            [
                {
                    let cell = UITableViewCell(
                        style: .value1,
                        reuseIdentifier: ""
                    )
                    
                    cell.selectionStyle = .none
                    cell.imageView?.image = Icons.googleTranslateIcon.scaledToListIconSize()
                    cell.textLabel?.text = "Translate \(LangCode.currentLanguage.rawValue) →"  // TODO: - Update localization
                    cell.textLabel?.font = UIFont.systemFont(ofSize: Sizes.mediumFontSize)
                    cell.textLabel?.textColor = Colors.normalTextColor
                    cell.textLabel?.textAlignment = .left
                    cell.detailTextLabel?.text = selectedTranslationLang.rawValue
                    cell.detailTextLabel?.font = UIFont.systemFont(ofSize: Sizes.mediumFontSize)
                    cell.detailTextLabel?.textColor = Colors.weakTextColor
                    cell.detailTextLabel?.textAlignment = .right
                    cell.accessoryType = .disclosureIndicator
                    
                    return cell
                }()
            ],
            // Voice rates.
            [
                {
                    let cell = SettingsSlidingCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = UIImage.init(systemName: "waveform")
                    cell.step = 0.05
                    cell.slider.minimumValue = 0.0
                    cell.slider.maximumValue = 1.0
                    cell.slider.value = LangCode.currentLanguage.configs.voiceRate
                    cell.formatingFunc = { (sliderVal: Float) -> String in
                        return String(format: "%.2f", sliderVal)
                    }
                    cell.label.text = cell.formatingFunc(cell.slider.value)
                    return cell
                }(),
                {
                    let cell = SettingsSlidingCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = UIImage.init(systemName: "tortoise")
                    cell.step = 0.05
                    cell.slider.minimumValue = 0.0
                    cell.slider.maximumValue = 1.0
                    cell.slider.value = LangCode.currentLanguage.configs.slowVoiceRate
                    cell.formatingFunc = { (sliderVal: Float) -> String in
                        return String(format: "%.2f", sliderVal)
                    }
                    cell.label.text = cell.formatingFunc(cell.slider.value)
                    return cell
                }()
            ],
            // Practice durations.
            [
                {
                    let cell = SettingsSlidingCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = Images.wordPracticeImage
                    cell.step = 5
                    cell.slider.minimumValue = 5
                    cell.slider.maximumValue = 30
                    cell.slider.value = Float(LangCode.currentLanguage.configs.phraseReviewPracticeDuration)
                    cell.formatingFunc = { (sliderVal: Float) -> String in
                        return "\(String(Int(sliderVal))) mins"  // TODO: - Update localization
                    }
                    cell.label.text = cell.formatingFunc(cell.slider.value)
                    return cell
                }(),
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
                }()
            ],
            // Practice repetitions.
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
                }()
            ],
            // Duolingo only.
            [
                {
                    let cell = UITableViewCell(
                        style: .value1,
                        reuseIdentifier: ""
                    )
                    
                    cell.selectionStyle = .none
                    cell.imageView?.image = Images.duolingoIcon
                    cell.textLabel?.text = textForDuolingoOnlyCell
                    cell.textLabel?.font = UIFont.systemFont(ofSize: Sizes.mediumFontSize)
                    cell.textLabel?.textColor = Colors.normalTextColor
                    cell.textLabel?.textAlignment = .left
                    cell.accessoryType = .disclosureIndicator
                    
                    return cell
                }()
            ],
            // Content generation.
            [
                {
                    let cell = SettingsSwitchingCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = Icons.chatgptIcon.scaledToListIconSize()
                    cell.switchView.isOn = LangCode.currentLanguage.configs.canGenerateTextsWithLLMsForPractices
                    cell.label.text = "Allow LLM Text Genetation"  // TODO: - Update localization
                    return cell
                }()
            ],
            // Reminders.
            [
                {
                    let cell = SettingsSwitchingCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = Images.articlesImage
                    cell.switchView.isOn = LangCode.currentLanguage.configs.shouldRemindToAddNewArticles
                    cell.label.text = "Remind to add new articles"  // TODO: - Update localization
                    return cell
                }()
            ]

            if !hasDuolingoArticles {
                cells[4][0].isHidden = true
            }
            
        ]
    }
    
    override func updateViews() {
        super.updateViews()
        
        navigationItem.title = Strings.configurations
    }
    
}

extension LanguageSettingsViewController {
    
    // MARK: - UITableView Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            let vc = LanguageSelectionViewController()
            vc.delegate = self
            vc.langs = translationLangsForCurLang
            vc.selectedLang = selectedTranslationLang
            navigationController?.pushViewController(
                vc,
                animated: true
            )
        } else if if indexPath.section == 4 && indexPath.row == 0 {
            let vc = DuolingoOnlySelectionViewController()
            vc.delegate = self
            vc.practiceType2isDuolingoOnly = self.practiceType2isDuolingoOnly
            navigationController?.pushViewController(
                vc,
                animated: true
            )
        }
    }
    
}

extension LanguageSettingsViewController: LanguageSelectionViewControllerDelegate {
    
    func updateLanguage(as language: LangCode) {
        selectedTranslationLang = language
        cells[0][0].detailTextLabel?.text = language.rawValue
    }
    
}

extension LanguageSettingsViewController: DuolingoOnlySelectionViewControllerDelegate {

    func updateselectionMapping(with selectionMapping: [PracticeType: Bool]) {
        self.practiceType2isDuolingoOnly = selectionMapping
        cells[4][0].detailTextLabel?.text = textForDuolingoOnlyCell
    }
    
}
