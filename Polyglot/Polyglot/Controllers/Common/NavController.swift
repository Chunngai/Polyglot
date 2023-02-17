//
//  DefaultNavController.swift
//  Polyglot
//
//  Created by Sola on 2022/12/25.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class NavController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateViews()
    }
    
    private func updateViews() {
        // https://stackoverflow.com/questions/56435510/presenting-modal-in-ios-13-fullscreen
        modalPresentationStyle = .fullScreen
        
        navigationBar.hideBarSeparator()
    }

}
