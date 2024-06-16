//
//  SettingsViewController.swift
//  Polyglot
//
//  Created by Ho on 6/6/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit
import MessageUI

class SettingsViewController: UIViewController {
    
    var possibleTranslationLangsForCurLang: [LangCode] {
        var langs = LangCode.learningLanguages
        langs.remove(at: LangCode.learningLanguages.firstIndex(of: LangCode.currentLanguage)!)
        langs = [LangCode.zh] + langs
        return langs
    }
    var selectedTranslationLang = LangCode.currentLanguage.configs.languageForTranslation
    
    // TODO: - Update localization
    var headers: [String?] = [
        "Language for translating \(LangCode.currentLanguage.rawValue) texts",
        "Voice rate for \(LangCode.currentLanguage.rawValue) texts",
        "Practice duration",
        "Repetition for listening/speaking practices",
        "Text generation with LLMs",
        "Data backup"
    ]
    lazy var cells: [[UITableViewCell]] = [
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
        [
            {
                let cell = SettingsSlidingCell(style: .default, reuseIdentifier: "")
                cell.imageView?.image = UIImage.init(systemName: "waveform")
                cell.step = 0.05
                cell.slider.minimumValue = 0.0
                cell.slider.maximumValue = 1.0
                cell.slider.value = LangCode.currentLanguage.configs.voiceRate
                cell.label.text = cell.formatingFunc(cell.slider.value)
                return cell
            }()
        ],
        [
            {
                let cell = SettingsSlidingCell(style: .default, reuseIdentifier: "")
                cell.imageView?.image = UIImage.init(systemName: "timer")
                cell.step = 5
                cell.slider.minimumValue = 5
                cell.slider.maximumValue = 30
                cell.slider.value = Float(LangCode.currentLanguage.configs.practiceDuration)
                cell.formatingFunc = { (sliderVal: Float) -> String in
                    return "\(String(Int(sliderVal))) mins"  // TODO: - Update localization
                }
                cell.label.text = cell.formatingFunc(cell.slider.value)
                return cell
            }()
        ],
        [
            {
                let cell = SettingsSlidingCell(style: .default, reuseIdentifier: "")
                cell.imageView?.image = Images.textMeaningPracticeReinforceImage
                cell.step = 1
                cell.slider.minimumValue = 0
                cell.slider.maximumValue = 5
                cell.slider.value = Float(LangCode.currentLanguage.configs.practiceRepetition)
                cell.formatingFunc = { (sliderVal: Float) -> String in
                    return "\(String(Int(sliderVal))) times"  // TODO: - Update localization
                }
                cell.label.text = cell.formatingFunc(cell.slider.value)
                return cell
            }()
        ],
        [
            {
                let cell = SettingsSwitchingCell(style: .default, reuseIdentifier: "")
                cell.imageView?.image = Icons.chatgptIcon.scaledToListIconSize()
                cell.switchView.isOn = LangCode.currentLanguage.configs.canGenerateTextsWithLLMsForPractices
                cell.label.text = "Allow Text Genetation"  // TODO: - Update localization
                cell.funcAfterSwitching = { isOn in
                    self.cells[4][1].isHidden = !isOn
                    self.cells[4][2].isHidden = !isOn
                    self.tableView.reloadData()
                }
                return cell
            }(),
            {
                let cell = SettingsInputCell(style: .default, reuseIdentifier: "")
                cell.imageView?.image = UIImage(systemName: "link")!
                cell.textField.placeholder = "ChatGPT API URL"  // TODO: - Update localization
                cell.textField.text = LangCode.currentLanguage.configs.ChatGPTAPIURL
                cell.isHidden = !LangCode.currentLanguage.configs.canGenerateTextsWithLLMsForPractices
                return cell
            }(),
            {
                let cell = SettingsInputCell(style: .default, reuseIdentifier: "")
                cell.imageView?.image = UIImage(systemName: "key")!
                cell.textField.placeholder = "ChatGPT API key"  // TODO: - Update localization
                cell.textField.text = LangCode.currentLanguage.configs.ChatGPTAPIKey
                cell.isHidden = !LangCode.currentLanguage.configs.canGenerateTextsWithLLMsForPractices
                return cell
            }(),
        ],
        [
            {
                let cell = SettingsInputCell(style: .default, reuseIdentifier: "")
                cell.imageView?.image = UIImage(systemName: "envelope")!
                cell.textField.placeholder = "Email address"  // TODO: - Update localization
                cell.textField.text = LangCode.currentLanguage.configs.backupEmailAddr
                return cell
            }(),
            {
                let cell = SettingsButtonCell(style: .default, reuseIdentifier: "")
                cell.imageView?.image = UIImage(systemName: "square.and.arrow.up")!
                cell.button.setTitle("Send a copy", for: .normal)  // TODO: - Update localization
                cell.buttonFunc = self.emailAnCopy
                return cell
            }()
        ]
    ]
    
    // MARK: - Views
    
    var tableView: UITableView = {
        let tableView = UITableView(
            frame: CGRect.zero,
            style: .insetGrouped
        )
        return tableView
    }()
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        LangCode.currentLanguage.configs = Configs(
            languageForTranslation: selectedTranslationLang,
            voiceRate: (cells[1][0] as! SettingsSlidingCell).slider.value,
            practiceDuration: Int((cells[2][0] as! SettingsSlidingCell).slider.value),
            practiceRepetition: Int((cells[3][0] as! SettingsSlidingCell).slider.value),
            canGenerateTextsWithLLMsForPractices: (cells[4][0] as! SettingsSwitchingCell).switchView.isOn,
            ChatGPTAPIURL: (cells[4][1] as! SettingsInputCell).textField.text?.strip(),
            ChatGPTAPIKey: (cells[4][2] as! SettingsInputCell).textField.text?.strip(),
            backupEmailAddr: (cells[5][0] as! SettingsInputCell).textField.text?.strip()
        )
    }
    
    private func updateSetups() {
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func updateViews() {
        navigationItem.title = "Settings"
        
        view.backgroundColor = Colors.defaultBackgroundColor
        view.addSubview(tableView)
    }
    
    private func updateLayouts() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension SettingsViewController: UITableViewDataSource {
    
    // MARK: - UITableView Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return cells.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.section][indexPath.row]
    }
    
}

extension SettingsViewController: UITableViewDelegate {
    
    // MARK: - UITableView Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            let vc = LanguageSelectionViewController()
            vc.delegate = self
            vc.langs = possibleTranslationLangsForCurLang
            vc.selectedLang = selectedTranslationLang
            navigationController?.pushViewController(
                vc,
                animated: true
            )
        case (1, 1):
            emailAnCopy()
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return (
            !cells[indexPath.section][indexPath.row].isHidden
            ? Sizes.mediumFontSize * 3
            : 0
        )
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (
            !cells[indexPath.section][indexPath.row].isHidden
            ? Sizes.mediumFontSize * 3
            : 0
        )
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headers[section]
    }
}

extension SettingsViewController {
    
    // MARK: - Utils
    
    private func emailAnCopy() {
        guard MFMailComposeViewController.canSendMail() else {
            // Handle the case where the device can't send emails, e.g., display an alert.
            print("Cannot send email.")
            return
        }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        
        for fileName in Constants.filesToSend {
            
            if let fileURL = try? constructFileUrl(
                from: fileName,
                create: false
            ) {
                if let data = try? Data(contentsOf: fileURL) {
                    mailComposer.addAttachmentData(
                        data,
                        mimeType: "application/json",
                        fileName: fileName
                    )
                } else {
                    // Handle the case where reading the file data failed.
                    print("Failed to read data from \(fileName)")
                    return
                }
            } else {
                // Handle any errors related to constructing the file URL
                print("Failed to construct URL for \(fileName)")
                return
            }
            
        }
        
        mailComposer.setToRecipients([LangCode.currentLanguage.configs.backupEmailAddr ?? ""])
        mailComposer.setSubject("Data Copy \(Date().repr(of: Date.defaultDateFormat))")
        mailComposer.setMessageBody("", isHTML: false)
        
        // Present the mail composer view controller
        self.present(mailComposer, animated: true, completion: nil)
        
    }
    
}

extension SettingsViewController: LanguageSelectionViewControllerDelegate {
    
    func updateLanguage(as language: LangCode) {
        cells[0][0].detailTextLabel?.text = language.rawValue
        selectedTranslationLang = language
    }
    
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    
    // MARK: - MFMailCompose ViewController Delegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        
        switch result {
        case .sent:
            // Handle the email sent successfully
            print("Email sent successfully")
        case .saved:
            // Handle the email being saved as a draft
            print("Email saved as draft")
        case .cancelled:
            // Handle the user canceling the email composition
            print("Email composition canceled")
        case .failed:
            // Handle the case where the email failed to send
            if let error = error {
                print("Email send error: \(error.localizedDescription)")
            }
        @unknown default:
            break
        }
    }

}
