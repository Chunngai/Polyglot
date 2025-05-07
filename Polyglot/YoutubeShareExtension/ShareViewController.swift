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
    
    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }
    
    override func didSelectPost() {
        
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            extensionContext?.completeRequest(returningItems: nil)
            return
        }
        
        for extensionItem in extensionItems {
            
            guard let providers = extensionItem.attachments else {
                continue
            }
            
            for provider in providers {
                // Try both URL type identifiers
                let urlIdentifiers = ["public.url", "public.plain-text"]
                
                for identifier in urlIdentifiers {
                    if !provider.hasItemConformingToTypeIdentifier(identifier) {
                        continue
                    }
                    
                    provider.loadItem(forTypeIdentifier: identifier) { [weak self] (item, error) in
                        guard let self = self else {
                            return
                        }
                        
                        // Handle both URL and text cases
                        var sharedURL: URL?
                        
                        if let url = item as? URL {
                            sharedURL = url
                        } else 
                        if let text = item as? String,
                            let url = URL(string: text)
                        {
                            sharedURL = url
                        }
                        
                        guard let url = sharedURL else {
                            DispatchQueue.main.async {
                                self.extensionContext?.completeRequest(returningItems: nil)
                            }
                            return
                        }

                        // Process the URL
                        DispatchQueue.main.async {
                            self.processYouTubeURL(url)
                            self.extensionContext?.completeRequest(returningItems: nil)
                        }
                    }
                    return // Exit after first successful provider
                    
                }
            }
        }
        
        // If we get here, no URL was found
        extensionContext?.completeRequest(returningItems: nil)
    }
    
    private func processYouTubeURL(_ url: URL) {
        
        // Open main app directly
        var components = URLComponents()
        components.scheme = Constants.youtubeURLSchemeName // Your custom URL scheme
        components.host = Constants.youtubeURLHostName
        components.queryItems = [URLQueryItem(
            name: "url",
            value: url.absoluteString
        )]
        
        if let appURL = components.url {
            _ = self.openURL(appURL) // Will transition to main app
        }
        
    }
    
    // Helper function to open main app
    @objc func openURL(_ url: URL) -> Bool {

        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            responder = responder?.next
        }
        return false
        
    }
    
    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}

extension ShareViewController {
    
    struct Constants {
        
        static let youtubeURLSchemeName: String = "youtubeprocessor"
        static let youtubeURLHostName: String = "share"
        
    }

    
}
