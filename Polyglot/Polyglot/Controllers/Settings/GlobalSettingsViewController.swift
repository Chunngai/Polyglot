//
//  SettingsViewController.swift
//  Polyglot
//
//  Created by Ho on 6/6/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit
import MessageUI

class GlobalSettingsViewController: SettingsViewController {
    
    override func saveSettings() {
        LangCode.currentLanguage.configs = Configs(
            
            languageForTranslation: LangCode.currentLanguage.configs.languageForTranslation,
            voiceRate: LangCode.currentLanguage.configs.voiceRate,
            phraseReviewPracticeDuration: LangCode.currentLanguage.configs.phraseReviewPracticeDuration,
            listeningPracticeDuration: LangCode.currentLanguage.configs.listeningPracticeDuration,
            speakingPracticeDuration: LangCode.currentLanguage.configs.speakingPracticeDuration,
            practiceRepetition: LangCode.currentLanguage.configs.practiceRepetition,
            canGenerateTextsWithLLMsForPractices: LangCode.currentLanguage.configs.canGenerateTextsWithLLMsForPractices,
            shouldRemindToAddNewArticles: LangCode.currentLanguage.configs.shouldRemindToAddNewArticles,
            
            ChatGPTAPIURL: (cells[0][0] as! SettingsInputCell).textField.text?.strip(),
            ChatGPTAPIKey: (cells[0][1] as! SettingsInputCell).textField.text?.strip(),
            
            baiduTranslateAPPID: (cells[1][0] as! SettingsInputCell).textField.text?.strip(),
            baiduTranslateAPIKey: (cells[1][1] as! SettingsInputCell).textField.text?.strip(),
            
            backupEmailAddr: (cells[2][0] as! SettingsInputCell).textField.text?.strip()
            
        )
    }
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: - Update localization
        headers = [
            "Content Generation",
            "Machine Translation",
            "Data Backup"
        ]
        cells = [
            // Content Generation.
            [
                {
                    let cell = SettingsInputCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = UIImage(systemName: "link")!
                    cell.textField.placeholder = "ChatGPT API URL"  // TODO: - Update localization
                    cell.textField.text = LangCode.currentLanguage.configs.ChatGPTAPIURL
                    return cell
                }(),
                {
                    let cell = SettingsInputCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = UIImage(systemName: "key")!
                    cell.textField.placeholder = "ChatGPT API key"  // TODO: - Update localization
                    cell.textField.text = LangCode.currentLanguage.configs.ChatGPTAPIKey
                    return cell
                }(),
            ],
            [
                {
                    let cell = SettingsInputCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = UIImage(systemName: "app")!
                    cell.textField.placeholder = "Baidu translate APP ID"  // TODO: - Update localization
                    cell.textField.text = LangCode.currentLanguage.configs.baiduTranslateAPPID
                    return cell
                }(),
                {
                    let cell = SettingsInputCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = UIImage(systemName: "key")!
                    cell.textField.placeholder = "Baidu translate API key"  // TODO: - Update localization
                    cell.textField.text = LangCode.currentLanguage.configs.baiduTranslateAPIKey
                    return cell
                }()
            ],
            // Data backup.
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
    }
    
    override func updateViews() {
        super.updateViews()
        
        navigationItem.title = "Settings"
    }
    
}

extension GlobalSettingsViewController {
    
    // MARK: - UITableView Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 && indexPath.row == 0 {
            emailAnCopy()
        }
    }
    
}

extension GlobalSettingsViewController {
    
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

extension GlobalSettingsViewController: MFMailComposeViewControllerDelegate {
    
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
