//
//  SceneDelegate.swift
//  Polyglot
//
//  Created by Sola on 2022/12/20.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import AVFAudio

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var rootViewController = HomeViewController()


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        self.window = UIWindow(windowScene: scene as! UIWindowScene)
        self.window?.rootViewController = NavController(rootViewController: rootViewController)
        self.window?.makeKeyAndVisible()
        
        guard let _ = (scene as? UIWindowScene) else { return }
        
        // https://github.com/hackiftekhar/IQKeyboardManager
        IQKeyboardManager.shared.enable = true
        // https://stackoverflow.com/questions/40124364/how-to-hide-toolbar-in-iqkeyboardmanager-ios-swift-3
        IQKeyboardManager.shared.enableAutoToolbar = false
        
        // https://stackoverflow.com/questions/44343858/make-ios-text-to-speech-work-when-ringer-is-muted
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        
        // Handle shared youtube urls when the app is firstly launched.
        // https://stackoverflow.com/questions/58973143/method-scene-openurlcontexts-is-not-called
        let urlinfo = connectionOptions.urlContexts
        if let url = urlinfo.first?.url {
            handleIncomingURL(url)
        }
        
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        
        TimingBar.isTimingEnabled = true
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        
        TimingBar.isTimingEnabled = false
    }

    // Handle URL when app is running (foreground/background)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {

        guard let url = URLContexts.first?.url else {
            return
        }
            
        handleIncomingURL(url)
        
    }
    
    func handleIncomingURL(_ url: URL) {

        let readingViewController = ReadingViewController()
        readingViewController.delegate = rootViewController
        rootViewController.navigationController?.pushViewController(
            readingViewController,
            animated: false
        )
        
        let readingEditViewController = ReadingEditViewController()
        readingEditViewController.delegate = readingViewController
        let readingEditNavController = NavController(rootViewController: readingEditViewController)
        rootViewController.navigationController?.present(
            readingEditNavController,
            animated: false,
            completion: nil
        )

        readingEditViewController.handleSharedURLFromYoutube(url: url)

    }
    
}

