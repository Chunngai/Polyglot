//
//  ShareViewController.swift
//  YoutubeShareExtension
//
//  Created by Ho on 5/7/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {
    
    private var didAttemptAutoShare = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.attemptAutoShare()
    }
    
    private func attemptAutoShare() {
        guard !didAttemptAutoShare else { return }
        didAttemptAutoShare = true
        
        // Immediately process the shared content
        processSharedContent { [weak self] success in
            guard let self = self else { return }
            
            if success {
                // Complete immediately if successful
                self.extensionContext?.completeRequest(returningItems: nil)
            } else {
                // Fallback to showing the default compose UI if failed
                self.textView.isHidden = false
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            }
        }
    }
    
    private func processSharedContent(completion: @escaping (Bool) -> Void) {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            completion(false)
            return
        }
        
        for extensionItem in extensionItems {
            guard let providers = extensionItem.attachments else { continue }
            
            for provider in providers {
                let urlIdentifiers = ["public.url", "public.plain-text"]
                
                for identifier in urlIdentifiers {
                    if provider.hasItemConformingToTypeIdentifier(identifier) {
                        provider.loadItem(forTypeIdentifier: identifier) { (item, error) in
                            var sharedURL: URL?
                            
                            if let url = item as? URL {
                                sharedURL = url
                            } else if let text = item as? String, let url = URL(string: text) {
                                sharedURL = url
                            }
                            
                            guard let url = sharedURL else {
                                completion(false)
                                return
                            }
                            
                            DispatchQueue.main.async {
                                if self.openMainApp(with: url) {
                                    completion(true)
                                } else {
                                    completion(false)
                                }
                            }
                        }
                        return
                    }
                }
            }
        }
        
        completion(false)
    }
    
    private func openMainApp(with url: URL) -> Bool {
        var components = URLComponents()
        components.scheme = Constants.youtubeURLSchemeName
        components.host = Constants.youtubeURLHostName
        components.queryItems = [URLQueryItem(name: "url", value: url.absoluteString)]
        
        if let appURL = components.url {
            return self.openURL(appURL)
        }
        return false
    }
    
    @objc private func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            responder = responder?.next
        }
        return false
    }
    
    // MARK: - Override default behavior
    
    override func isContentValid() -> Bool {
        return false // Disable the Post button
    }
    
    override func didSelectPost() {
        // This won't be called because we disabled the Post button
        extensionContext?.completeRequest(returningItems: nil)
    }
    
    override func didSelectCancel() {
        // Handle cancellation if needed
        extensionContext?.cancelRequest(withError: NSError(domain: "com.yourapp.share", code: -1))
    }
    
    override func configurationItems() -> [Any]! {
        return []
    }
}

extension ShareViewController {
    struct Constants {
        static let youtubeURLSchemeName = "youtubeprocessor"
        static let youtubeURLHostName = "share"
    }
}
