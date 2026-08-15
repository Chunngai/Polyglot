//
//  LanguageSettingsViewController.swift
//  Polyglot
//
//  Created by Ho on 8/22/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit

class LanguageSettingsViewController: SettingsViewController {

    var selectedTranslationLang = LangCode.currentLanguage.configs.languageForTranslation
    var nounCaseIsOn = LangCode.currentLanguage.configs.shouldShowNounCasesInPractices
    var nounCaseExcludedWords = LangCode.currentLanguage.configs.nounCasesExcludedWords

    var practiceType2isDuolingoOnly: [DuolingoOnlySelectionViewController.PracticeType: Bool] = [
        .shadowing: LangCode.currentLanguage.configs.isDuolingoOnlyForShadowing,
        .speaking: LangCode.currentLanguage.configs.isDuolingoOnlyForSpeaking,
        .reading: LangCode.currentLanguage.configs.isDuolingoOnlyForReading,
        .podcast: LangCode.currentLanguage.configs.isDuolingoOnlyForPodcast
    ]
    var textForDuolingoOnlyCell: String {
        var ss: [String] = []
        for practiceType in [
            DuolingoOnlySelectionViewController.PracticeType.shadowing,
            DuolingoOnlySelectionViewController.PracticeType.speaking,
            DuolingoOnlySelectionViewController.PracticeType.reading,
            DuolingoOnlySelectionViewController.PracticeType.podcast
        ] {
            if practiceType2isDuolingoOnly[practiceType]! {
                ss.append(practiceType.text)
            }
        }

        var text = ss.joined(separator: ", ")
        if text.strip().isEmpty {
            text = "Inactive"
        }
        return text
    }
    var hasDuolingoArticles: Bool = false
    var isRussianLanguage: Bool = LangCode.currentLanguage == .ru

    var phraseReviewEnabledPracticeTypes = LangCode.currentLanguage.configs.phraseReviewEnabledPracticeTypes

    var phraseReviewPracticeDuration = LangCode.currentLanguage.configs.phraseReviewPracticeDuration
    var listeningPracticeDuration = LangCode.currentLanguage.configs.listeningPracticeDuration
    var videoShadowingPracticeDuration = LangCode.currentLanguage.configs.videoShadowingPracticeDuration
    var speakingPracticeDuration = LangCode.currentLanguage.configs.speakingPracticeDuration
    var readingPracticeDuration = LangCode.currentLanguage.configs.readingPracticeDuration
    var podcastPracticeDuration = LangCode.currentLanguage.configs.podcastPracticeDuration

    var wordPracticeRepetition = LangCode.currentLanguage.configs.wordPracticeRepetition
    var listeningPracticeRepetition = LangCode.currentLanguage.configs.listeningPracticeRepetition
    var speakingPracticeRepetition = LangCode.currentLanguage.configs.speakingPracticeRepetition
    var phraseReviewDefaultSelectionCount = LangCode.currentLanguage.configs.phraseReviewDefaultSelectionCount

    override func saveSettings() {
        let base = hasDuolingoArticles ? 1 : 0
        LangCode.currentLanguage.configs = LangConfigs(

            languageForTranslation: selectedTranslationLang,

            voiceRate: (cells[1][0] as! SettingsSlidingCell).slider.value,
            slowVoiceRate: (cells[1][1] as! SettingsSlidingCell).slider.value,

            phraseReviewPracticeDuration: phraseReviewPracticeDuration,
            listeningPracticeDuration: listeningPracticeDuration,
            videoShadowingPracticeDuration: videoShadowingPracticeDuration,
            speakingPracticeDuration: speakingPracticeDuration,
            readingPracticeDuration: readingPracticeDuration,
            podcastPracticeDuration: podcastPracticeDuration,

            wordPracticeRepetition: wordPracticeRepetition,
            listeningPracticeRepetition: listeningPracticeRepetition,
            speakingPracticeRepetition: speakingPracticeRepetition,
            phraseReviewDefaultSelectionCount: phraseReviewDefaultSelectionCount,

            isDuolingoOnlyForShadowing: practiceType2isDuolingoOnly[.shadowing]!,
            isDuolingoOnlyForSpeaking: practiceType2isDuolingoOnly[.speaking]!,
            isDuolingoOnlyForReading: practiceType2isDuolingoOnly[.reading]!,
            isDuolingoOnlyForPodcast: practiceType2isDuolingoOnly[.podcast]!,
            phraseReviewEnabledPracticeTypes: phraseReviewEnabledPracticeTypes,

            canGenerateTextsWithLLMsForPractices: (cells[3 + base][0] as! SettingsSwitchingCell).switchView.isOn,

            shouldRemindToAddNewArticles: LangCode.currentLanguage.configs.shouldRemindToAddNewArticles,

            shouldShowVerbAspectsInPractices: isRussianLanguage
                ? (cells[4 + base][0] as! SettingsSwitchingCell).switchView.isOn
                : LangCode.currentLanguage.configs.shouldShowVerbAspectsInPractices,

            shouldShowNounCasesInPractices: isRussianLanguage
                ? nounCaseIsOn
                : LangCode.currentLanguage.configs.shouldShowNounCasesInPractices,

            nounCasesExcludedWords: isRussianLanguage
                ? nounCaseExcludedWords
                : LangCode.currentLanguage.configs.nounCasesExcludedWords

        )
    }

    // MARK: - Init

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: - Update localization
        headers = [
            "Language for Translating \(LangCode.currentLanguage.rawValue) Texts",
            "Voice Rate for Synthesizing \(LangCode.currentLanguage.rawValue) Texts",
            "Practice Configs",
            "Duolingo Only",
            "Content Generation",
            "Grammar",
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
            // Practice configs.
            [
                {
                    let cell = UITableViewCell(style: .value1, reuseIdentifier: "")
                    cell.selectionStyle = .none
                    cell.imageView?.image = UIImage(systemName: "clock")
                    cell.textLabel?.text = "Practice Durations"  // TODO: - Update localization
                    cell.textLabel?.font = UIFont.systemFont(ofSize: Sizes.mediumFontSize)
                    cell.textLabel?.textColor = Colors.normalTextColor
                    cell.accessoryType = .disclosureIndicator
                    return cell
                }(),
                {
                    let cell = UITableViewCell(style: .value1, reuseIdentifier: "")
                    cell.selectionStyle = .none
                    cell.imageView?.image = UIImage(systemName: "repeat")
                    cell.textLabel?.text = "Practice Repetitions"  // TODO: - Update localization
                    cell.textLabel?.font = UIFont.systemFont(ofSize: Sizes.mediumFontSize)
                    cell.textLabel?.textColor = Colors.normalTextColor
                    cell.accessoryType = .disclosureIndicator
                    return cell
                }(),
                {
                    let cell = UITableViewCell(style: .value1, reuseIdentifier: "")
                    cell.selectionStyle = .none
                    cell.imageView?.image = UIImage(systemName: "checklist")
                    cell.textLabel?.text = "Practice Types"  // TODO: - Update localization
                    cell.textLabel?.font = UIFont.systemFont(ofSize: Sizes.mediumFontSize)
                    cell.textLabel?.textColor = Colors.normalTextColor
                    cell.accessoryType = .disclosureIndicator
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
                    cell.imageView?.image = Icons.duolingoIcon.scaledToListIconSize()
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
            // Russian-specific.
            [
                {
                    let cell = SettingsSwitchingCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = UIImage(systemName: "v.square")
                    cell.switchView.isOn = LangCode.currentLanguage.configs.shouldShowVerbAspectsInPractices
                    cell.label.text = "Show Verb Aspects"
                    return cell
                }(),
                {
                    let cell = UITableViewCell(style: .value1, reuseIdentifier: "")
                    cell.selectionStyle = .none
                    cell.imageView?.image = UIImage(systemName: "n.square")
                    cell.textLabel?.text = "Show Noun Cases"
                    cell.textLabel?.font = UIFont.systemFont(ofSize: Sizes.mediumFontSize)
                    cell.textLabel?.textColor = Colors.normalTextColor
                    cell.detailTextLabel?.text = LangCode.currentLanguage.configs.shouldShowNounCasesInPractices ? "On" : "Off"
                    cell.detailTextLabel?.font = UIFont.systemFont(ofSize: Sizes.mediumFontSize)
                    cell.detailTextLabel?.textColor = Colors.weakTextColor
                    cell.accessoryType = .disclosureIndicator
                    return cell
                }()
            ]

        ]

        if !hasDuolingoArticles {
            headers.remove(at: 3)
            cells.remove(at: 3)
        }
        if !isRussianLanguage {
            headers.removeLast()
            cells.removeLast()
        }

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
            vc.langs = LangCode.currentLanguage.languagesForTranslation
            vc.selectedLang = selectedTranslationLang
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.section == 2 && indexPath.row == 0 {
            let vc = PracticeDurationsSettingsViewController()
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.section == 2 && indexPath.row == 1 {
            let vc = PracticeRepetitionsSettingsViewController()
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.section == 2 && indexPath.row == 2 {
            let vc = PhraseReviewPracticeTypeSettingsViewController()
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
        } else if hasDuolingoArticles && indexPath.section == 3 && indexPath.row == 0 {
            let vc = DuolingoOnlySelectionViewController()
            vc.delegate = self
            vc.practiceType2isDuolingoOnly = self.practiceType2isDuolingoOnly
            navigationController?.pushViewController(vc, animated: true)
        } else if isRussianLanguage && indexPath.section == cells.count - 1 && indexPath.row == 1 {
            let vc = NounCaseSettingsViewController(isOn: nounCaseIsOn, excludedWords: nounCaseExcludedWords)
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
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

    func updateselectionMapping(with selectionMapping: [DuolingoOnlySelectionViewController.PracticeType: Bool]) {
        self.practiceType2isDuolingoOnly = selectionMapping
        cells[3][0].textLabel?.text = textForDuolingoOnlyCell
    }

}

extension LanguageSettingsViewController: NounCaseSettingsViewControllerDelegate {

    func nounCaseSettingsDidUpdate(isOn: Bool, excludedWords: String) {
        nounCaseIsOn = isOn
        nounCaseExcludedWords = excludedWords
        let base = hasDuolingoArticles ? 1 : 0
        cells[4 + base][1].detailTextLabel?.text = isOn ? "On" : "Off"
    }

}

extension LanguageSettingsViewController: PracticeDurationsSettingsViewControllerDelegate {

    func practiceDurationsDidUpdate(
        listening: Int,
        videoShadowing: Int,
        speaking: Int,
        reading: Int,
        podcast: Int
    ) {
        listeningPracticeDuration = listening
        videoShadowingPracticeDuration = videoShadowing
        speakingPracticeDuration = speaking
        readingPracticeDuration = reading
        podcastPracticeDuration = podcast
    }

}

extension LanguageSettingsViewController: PracticeRepetitionsSettingsViewControllerDelegate {

    func practiceRepetitionsDidUpdate(word: Int, listening: Int, speaking: Int, phraseReviewDefaultSelectionCount: Int) {
        wordPracticeRepetition = word
        listeningPracticeRepetition = listening
        speakingPracticeRepetition = speaking
        self.phraseReviewDefaultSelectionCount = phraseReviewDefaultSelectionCount
    }

}

extension LanguageSettingsViewController: PhraseReviewPracticeTypeSettingsViewControllerDelegate {

    func phraseReviewPracticeTypesDidUpdate(_ enabledTypes: Set<WordPractice.PracticeType>) {
        phraseReviewEnabledPracticeTypes = enabledTypes
    }

}
