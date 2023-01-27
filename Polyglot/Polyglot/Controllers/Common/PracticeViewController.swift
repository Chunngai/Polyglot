//
//  PracticeViewController.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit

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
    
    var promptLabel: UILabel = {
        let label = UILabel()
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
    
    func updateSetups() {        
        timingBar.delegate = self
        timingBar.start()
        
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
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
        
        mainView.addSubview(promptLabel)
        mainView.addSubview(doneButton)
        mainView.addSubview(nextButton)
    }
    
    func updateLayouts() {
        mainView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.top.equalToSuperview().inset(navigationController!.navigationBar.frame.maxY + 100)
            make.bottom.equalToSuperview().inset(50)
        }
        
        
        promptLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
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
    
}
