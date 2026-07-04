//
//  SettingsViewController.swift
//  Polyglot
//
//  Created by Ho on 6/6/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import UIKit
import MessageUI

struct GlobalConfigs: Codable {

    var ChatGPTAPIURL: String?
    var ChatGPTAPIKey: String?
    var ChatGPTModel: String?

    var ChatGPTImageAPIURL: String?
    var ChatGPTImageAPIKey: String?
    var ChatGPTImageModel: String?

    var baiduTranslateAPPID: String?
    var baiduTranslateAPIKey: String?

    var backupEmailAddr: String?

    init(
        ChatGPTAPIURL: String? = nil, ChatGPTAPIKey: String? = nil, ChatGPTModel: String? = nil,
        ChatGPTImageAPIURL: String? = nil, ChatGPTImageAPIKey: String? = nil, ChatGPTImageModel: String? = nil,
        baiduTranslateAPPID: String? = nil, baiduTranslateAPIKey: String? = nil,
        backupEmailAddr: String? = nil
    ) {
        self.ChatGPTAPIURL = ChatGPTAPIURL
        self.ChatGPTAPIKey = ChatGPTAPIKey
        self.ChatGPTModel = ChatGPTModel
        self.ChatGPTImageAPIURL = ChatGPTImageAPIURL
        self.ChatGPTImageAPIKey = ChatGPTImageAPIKey
        self.ChatGPTImageModel = ChatGPTImageModel
        self.baiduTranslateAPPID = baiduTranslateAPPID
        self.baiduTranslateAPIKey = baiduTranslateAPIKey
        self.backupEmailAddr = backupEmailAddr
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {

        case ChatGPTAPIURL
        case ChatGPTAPIKey
        case ChatGPTModel

        case ChatGPTImageAPIURL
        case ChatGPTImageAPIKey
        case ChatGPTImageModel

        case baiduTranslateAPPID
        case baiduTranslateAPIKey

        case backupEmailAddr
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(ChatGPTAPIURL, forKey: .ChatGPTAPIURL)
        try container.encode(ChatGPTAPIKey, forKey: .ChatGPTAPIKey)
        try container.encode(ChatGPTModel, forKey: .ChatGPTModel)
        try container.encode(ChatGPTImageAPIURL, forKey: .ChatGPTImageAPIURL)
        try container.encode(ChatGPTImageAPIKey, forKey: .ChatGPTImageAPIKey)
        try container.encode(ChatGPTImageModel, forKey: .ChatGPTImageModel)
        try container.encode(baiduTranslateAPPID, forKey: .baiduTranslateAPPID)
        try container.encode(baiduTranslateAPIKey, forKey: .baiduTranslateAPIKey)
        try container.encode(backupEmailAddr, forKey: .backupEmailAddr)
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        ChatGPTAPIURL = try values.decode(String?.self, forKey: .ChatGPTAPIURL)
        ChatGPTAPIKey = try values.decode(String?.self, forKey: .ChatGPTAPIKey)
        do { ChatGPTModel = try values.decode(String?.self, forKey: .ChatGPTModel) } catch { ChatGPTModel = nil }
        do { ChatGPTImageAPIURL = try values.decode(String?.self, forKey: .ChatGPTImageAPIURL) } catch { ChatGPTImageAPIURL = nil }
        do { ChatGPTImageAPIKey = try values.decode(String?.self, forKey: .ChatGPTImageAPIKey) } catch { ChatGPTImageAPIKey = nil }
        do { ChatGPTImageModel = try values.decode(String?.self, forKey: .ChatGPTImageModel) } catch { ChatGPTImageModel = nil }
        do { baiduTranslateAPPID = try values.decode(String?.self, forKey: .baiduTranslateAPPID) } catch { baiduTranslateAPPID = nil }
        do { baiduTranslateAPIKey = try values.decode(String?.self, forKey: .baiduTranslateAPIKey) } catch { baiduTranslateAPIKey = nil }
        backupEmailAddr = try values.decode(String?.self, forKey: .backupEmailAddr)
    }
    
    // MARK: - IO
    
    static let fileName: String = "global_configs.json"
    
    static func load() -> GlobalConfigs {
        do {
            if let configs = try readDataFromJson(
                fileName: Self.fileName,
                type: GlobalConfigs.self
            ) as? GlobalConfigs {
                return configs
            }
            
            if let configs = try readDataFromJson(
                fileName: "configs.en.json",  // Compatibility.
                type: GlobalConfigs.self
            ) as? GlobalConfigs {
                return configs
            }
            
            return GlobalConfigs()
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static func save(_ configs: inout GlobalConfigs) {
        do {
            try writeDataToJson(
                fileName: Self.fileName,
                data: configs
            )
        } catch {
            print(error)
            exit(1)
        }
    }
    
}

var globalConfigs: GlobalConfigs = GlobalConfigs.load() {
    didSet {
        GlobalConfigs.save(&globalConfigs)
    }
}

class GlobalSettingsViewController: SettingsViewController {
        
    override func saveSettings() {
        globalConfigs = GlobalConfigs(
            ChatGPTAPIURL: (cells[0][0] as! SettingsInputCell).textField.text?.strip(),
            ChatGPTAPIKey: (cells[0][1] as! SettingsInputCell).textField.text?.strip(),
            ChatGPTModel: (cells[0][2] as! SettingsInputCell).textField.text?.strip(),
            ChatGPTImageAPIURL: (cells[1][0] as! SettingsInputCell).textField.text?.strip(),
            ChatGPTImageAPIKey: (cells[1][1] as! SettingsInputCell).textField.text?.strip(),
            ChatGPTImageModel: (cells[1][2] as! SettingsInputCell).textField.text?.strip(),
            baiduTranslateAPPID: (cells[2][0] as! SettingsInputCell).textField.text?.strip(),
            baiduTranslateAPIKey: (cells[2][1] as! SettingsInputCell).textField.text?.strip(),
            backupEmailAddr: (cells[3][0] as! SettingsInputCell).textField.text?.strip()
        )
    }
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: - Update localization
        headers = [
            "Text Generation",
            "Image Generation",
            "Machine Translation",
            "Data Backup"
        ]
        cells = [
            // Text Generation.
            [
                {
                    let cell = SettingsInputCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = UIImage(systemName: "link")!
                    cell.textField.placeholder = "ChatGPT API URL"
                    cell.textField.text = globalConfigs.ChatGPTAPIURL
                    return cell
                }(),
                {
                    let cell = SettingsInputCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = UIImage(systemName: "key")!
                    cell.textField.placeholder = "ChatGPT API key"
                    cell.textField.text = globalConfigs.ChatGPTAPIKey
                    return cell
                }(),
                {
                    let cell = SettingsInputCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = UIImage(systemName: "cpu")!
                    cell.textField.placeholder = "ChatGPT model"
                    cell.textField.text = globalConfigs.ChatGPTModel
                    return cell
                }(),
            ],
            // Image Generation.
            [
                {
                    let cell = SettingsInputCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = UIImage(systemName: "link")!
                    cell.textField.placeholder = "Image API URL"
                    cell.textField.text = globalConfigs.ChatGPTImageAPIURL
                    return cell
                }(),
                {
                    let cell = SettingsInputCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = UIImage(systemName: "key")!
                    cell.textField.placeholder = "Image API key"
                    cell.textField.text = globalConfigs.ChatGPTImageAPIKey
                    return cell
                }(),
                {
                    let cell = SettingsInputCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = UIImage(systemName: "cpu")!
                    cell.textField.placeholder = "Image model"
                    cell.textField.text = globalConfigs.ChatGPTImageModel
                    return cell
                }(),
            ],
            [
                {
                    let cell = SettingsInputCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = UIImage(systemName: "app")!
                    cell.textField.placeholder = "Baidu translate APP ID"
                    cell.textField.text = globalConfigs.baiduTranslateAPPID
                    return cell
                }(),
                {
                    let cell = SettingsInputCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = UIImage(systemName: "key")!
                    cell.textField.placeholder = "Baidu translate API key"
                    cell.textField.text = globalConfigs.baiduTranslateAPIKey
                    return cell
                }()
            ],
            // Data backup.
            [
                {
                    let cell = SettingsInputCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = UIImage(systemName: "envelope")!
                    cell.textField.placeholder = "Email address"
                    cell.textField.text = globalConfigs.backupEmailAddr
                    return cell
                }(),
                {
                    let cell = SettingsButtonCell(style: .default, reuseIdentifier: "")
                    cell.imageView?.image = UIImage(systemName: "square.and.arrow.up")!
                    cell.button.setTitle("Send a copy", for: .normal)
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
        
        mailComposer.setToRecipients([globalConfigs.backupEmailAddr ?? ""])
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
