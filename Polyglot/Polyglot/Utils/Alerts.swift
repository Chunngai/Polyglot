//
//  Alerts.swift
//  Polyglot
//
//  Created by Sola on 2023/1/2.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation
import UIKit

func presentExitWithoutSavingAlert(viewController: UIViewController, completion: @escaping (_ isOk: Bool) -> Void) {
    let alert = UIAlertController(
        title: Strings.exitWithoutSavingAlertTitle,
        message: Strings.exitWithoutSavingAlertBody,
        preferredStyle: .alert
    )
    
    let okButton = UIAlertAction(
        title: Strings.ok,
        style: .default,
        handler: { (_) -> Void in
            completion(true)
    })
    alert.addAction(okButton)
    
    let cancelButton = UIAlertAction(
        title: Strings.cancel,
        style: .cancel) { (_) -> Void in
            completion(false)
    }
    alert.addAction(cancelButton)
    
    viewController.present(alert, animated: true, completion: nil)
}
