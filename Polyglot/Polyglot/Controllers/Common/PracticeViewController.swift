//
//  PracticeViewController.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit
import PaddingLabel
import IQKeyboardManagerSwift

enum PracticeStatus: UInt {
    case beforeAnswering = 0  // Before selection or filling in.
    case afterAnswering = 1  // After selection or filling in, but the done button has not been tapped.
    case finished = 2  // The done button has been tapped.
}

class PracticeViewController: UIViewController {
    
    // TODO: - Can it be overriden?
//    var practiceProducer: Any!
    
    // MARK: - Views
    
    var timingBar: TimingBar = {
        let bar = TimingBar(duration: Constants.practiceDuration)
        return bar
    }()
    
    var mainView: UIView = {
        let view = UIView()
        return view
    }()
    
    var promptLabelBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.lightBlue
        view.layer.masksToBounds = true
        view.layer.cornerRadius = Sizes.smallCornerRadius
        return view
    }()
    var promptLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = Colors.lightBlue
        label.numberOfLines = 0
        label.attributedText = NSAttributedString(string: " ", attributes: Attributes.practicePromptAttributes)
        return label
    }()
    
    var practiceView: PracticeViewDelegate!
    
    var doneButton: RoundButton = {
        let button = RoundButton(radius: Sizes.roundButtonRadius)
        button.setImage(Icons.doneIcon, for: .normal)
        button.backgroundColor = Colors.lightBlue
        return button
    }()
    
    var nextButton: RoundButton = {
        let button = RoundButton(radius: Sizes.roundButtonRadius)
        button.setImage(Icons.nextIcon, for: .normal)
        button.backgroundColor = Colors.lightBlue
        button.isHidden = true
        return button
    }()
    
    private var maskView: UILabel = {
        let label = UILabel()
        label.backgroundColor = Colors.maskBackgroundColor
        label.text = Strings.textForPausedPractice
        label.textColor = Colors.lightTextColor
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.layer.cornerRadius = Sizes.defaultCornerRadius
        label.font = UIFont.systemFont(ofSize: Sizes.mediumFontSize)
        label.isHidden = true
        return label
    }()
    
    // MARK: - Controllers
    
    // TODO: - Can it be overriden?
//    var delegate: UIViewController!
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateSetups()
        updateViews()
        updateLayouts()
        updatePracticeView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the nav bar separator but do not make the nav bar bg transparent.
        // https://stackoverflow.com/questions/61297266/hide-navigation-bar-separator-line-on-ios-13
        navigationController?.navigationBar.isTranslucent = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        navigationController?.navigationBar.isTranslucent = true
    }
    
    func updateSetups() {        
        timingBar.delegate = self
        timingBar.start()
        
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    func updateViews() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: Icons.cancelIcon,
            style: .plain,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        navigationItem.titleView = timingBar
                 
        view.backgroundColor = Colors.defaultBackgroundColor
        view.addSubview(mainView)
        view.addSubview(maskView)
        
        mainView.addSubview(promptLabelBackgroundView)
        mainView.addSubview(doneButton)
        mainView.addSubview(nextButton)
        
        promptLabelBackgroundView.addSubview(promptLabel)
    }
    
    func updateLayouts() {
        mainView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            // If the nav bar is translucent:
//            make.top.equalToSuperview().inset(navigationController!.navigationBar.frame.maxY + 100)
            // If the nav bar is not translucent.
            make.top.equalToSuperview().inset(navigationController!.navigationBar.frame.maxY)
            make.bottom.equalToSuperview().inset(50)
        }
        
        promptLabelBackgroundView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(-promptLabelBackgroundView.layer.cornerRadius * 2)  // Hide the left rounding.
            make.width.equalToSuperview().multipliedBy(0.95)
        }
        promptLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(Sizes.smallLineSpacing * 2)
            make.leading.equalToSuperview().inset(promptLabelBackgroundView.layer.cornerRadius * 2 + 15)
            make.trailing.equalToSuperview().inset(15)
        }
        
        doneButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(20)
            make.width.height.equalTo(Sizes.roundButtonRadius)
        }
        nextButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(20)
            make.width.height.equalTo(Sizes.roundButtonRadius)
        }
        
        maskView.snp.makeConstraints { (make) in
            // If the nav bar is translucent:
//            make.top.equalToSuperview().inset(navigationController!.navigationBar.frame.maxY + 60)
            // If the nav bar is not translucent.
            make.top.equalToSuperview().inset(navigationController!.navigationBar.frame.maxY)
            make.width.equalToSuperview().multipliedBy(0.9)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(30)
        }
    }
    
    func updatePracticeView() {
        fatalError("updatePracticeView() has not been implemented.")
    }
}

extension PracticeViewController {
    
    // MARK: - Selectors
    
    @objc func cancelButtonTapped() {
        stopPracticing()
    }
    
    @objc func doneButtonTapped() {
        fatalError("doneButtonTapped() has not been implemented.")
    }
    
    @objc func nextButtonTapped() {
        fatalError("nextButtonTapped() has not been implemented.")
    }
    
    @objc func appMovedToBackground() {
        // Hide the keyboard.
        // If the keyboard is not hidden,
        // it may shadow the textfield in the practice view
        // when entering foreground.
        // Seems that it's a bug of IQKeyboardManager: https://github.com/hackiftekhar/IQKeyboardManager/issues/1377
        
        // https://stackoverflow.com/questions/53555428/hide-the-keyboard-on-the-button-click
        IQKeyboardManager.shared.resignFirstResponder()
    }
}

extension PracticeViewController: TimingBarDelegate {
    
    private func presentTimeUpAlert(duration: TimeInterval, completion: @escaping (_ isOk: Bool) -> Void) {
        let reachedMaxDuration: Bool = duration == Constants.maxPracticeDuration
        
        let message: String = {
            var message: String = ""
            if !reachedMaxDuration {
                message = Strings.timeUpAlertBody
            } else {
                message = Strings.maxTimeUpAlertBody
            }
            
            let minutes: Int = Int(duration / 60)
            message = message.replacingOccurrences(of: Strings.maskToken, with: String(minutes))
            
            return message
        }()
        let alert = UIAlertController(
            title: Strings.timeUpAlertTitle,
            message: message,
            preferredStyle: .alert
        )
        
        let okButton = UIAlertAction(
            title: Strings.ok,
            style: .default,
            handler: { (_) -> Void in
                completion(true)
        })
        alert.addAction(okButton)
        
        if !reachedMaxDuration {
            let cancelButton = UIAlertAction(
                title: Strings.cancel,
                style: .cancel,
                handler: { (_) -> Void in
                    completion(false)
            })
            alert.addAction(cancelButton)
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func stopPracticing() {
        fatalError("stopPracticing() has not been implemented.")
    }
    
    // MARK: - TimingBar Delegate
    
    func timingBarSet(toggleButton: UIBarButtonItem) {
        navigationItem.rightBarButtonItem = toggleButton
    }
        
    func timingBarTimeUp(timingBar: TimingBar) {
        if timingBar.duration != Constants.maxPracticeDuration {
            presentTimeUpAlert(duration: timingBar.duration) { (isOk) in
                if isOk {
                    // Update the timing bar.
                    timingBar.add(duration: Constants.practiceDuration)
                    timingBar.start()
                } else {
                    self.stopPracticing()
                }
            }
        } else {
            presentTimeUpAlert(duration: timingBar.duration) { (_) in
                self.stopPracticing()
            }
        }
    }
    
    func timingBarTimingStarted(timingBar: TimingBar) {
        guard practiceView != nil else {
            return
        }
        
        maskView.isHidden = true
        mainView.isUserInteractionEnabled = true
    }
    
    func timingBarTimingPaused(timingBar: TimingBar) {
        guard practiceView != nil else {
            return
        }
        
        maskView.isHidden = false
        mainView.isUserInteractionEnabled = false
    }
}

extension PracticeViewController {
    
    // MARK: - Constants
    
    static let practiceViewWidthRatio: CGFloat = 0.8
    
}
