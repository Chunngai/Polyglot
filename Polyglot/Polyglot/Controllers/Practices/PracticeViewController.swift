//
//  PracticeViewController.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift

class PracticeViewController: UIViewController {
        
    var practiceDuration: Int!
    var shouldFinishPracticing: Bool = false
    
    // MARK: - Models
    
    var words: [Word]! {
        didSet {
            delegate.words = words
        }
    }
    var articles: [Article]! {
        didSet {
            delegate.articles = articles
        }
    }
    
    var practiceMetaData: [String:String]! {
        didSet {
            delegate.practiceMetaData = practiceMetaData
        }
    }
    
    // MARK: - Controllers
    
    var delegate: HomeViewController! {
        didSet {
            self.words = delegate.words
            self.articles = delegate.articles
            
            self.practiceMetaData = delegate.practiceMetaData
        }
    }
    
    // MARK: - Views
    
    lazy var timingBar: TimingBar = {
        let bar = TimingBar(duration: Double(practiceDuration) * TimeInterval.minute)
        return bar
    }()
    var cancelButton: UIBarButtonItem!
    var toggleButton: UIBarButtonItem!
    
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
    
    var practiceView: BasePracticeView!
    
    var doneButton: RoundButton = {
        let button = RoundButton(radius: Sizes.roundButtonRadius)
        button.setImage(Icons.doneIcon, for: .normal)
        button.backgroundColor = Colors.lightBlue
        button.layer.borderColor = Colors.borderColor.cgColor
        button.layer.borderWidth = Sizes.defaultBorderWidth
        return button
    }()
    
    var nextButton: RoundButton = {
        let button = RoundButton(radius: Sizes.roundButtonRadius)
        button.setImage(Icons.nextIcon, for: .normal)
        button.backgroundColor = Colors.lightBlue
        button.layer.borderColor = Colors.borderColor.cgColor
        button.layer.borderWidth = Sizes.defaultBorderWidth
        button.isHidden = true
        return button
    }()
    
    var maskView: UIView = {  // TODO: - Merge with the timing bar.
        let backgroundView = UIView()
        backgroundView.backgroundColor = Colors.maskBackgroundColor
        backgroundView.layer.masksToBounds = true
        backgroundView.layer.cornerRadius = Sizes.defaultCornerRadius
        backgroundView.isHidden = true
        
        let imageView = UIImageView(image: Icons.startIcon)
        imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .white
        backgroundView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(30)
            make.centerX.centerY.equalToSuperview()
        }
        
        return backgroundView
    }()
    
    // MARK: - Init
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Ensure that the status bar has a bg color in the modal presentation mode.
        UIApplication.shared.statusBarUIView?.backgroundColor = Colors.defaultBackgroundColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Reset the status bar bg color.
        UIApplication.shared.statusBarUIView?.backgroundColor = nil
    }
    
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
        
        maskView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(maskViewTapped)))
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appMovedToBackground),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAPINotification(_:)),
            name: .apiDidFail,
            object: nil
        )
    }
    
    func updateViews() {
        // Ensure that the nav bar has a bg color in the modal presentation mode.
        navigationController?.navigationBar.backgroundColor = Colors.defaultBackgroundColor
        
        cancelButton = UIBarButtonItem(
            image: Icons.cancelIcon,
            style: .plain,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        toggleButton = UIBarButtonItem(
            image: Icons.pauseIcon,
            style: .plain,
            target: self,
            action: #selector(toggleButtonTapped)
        )
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = toggleButton
        navigationItem.titleView = timingBar
                 
        view.backgroundColor = Colors.defaultBackgroundColor
        view.addSubview(mainView)
        view.addSubview(maskView)
        
        mainView.addSubview(promptLabel)
        mainView.addSubview(doneButton)
        mainView.addSubview(nextButton)
    }
    
    func updateLayouts() {
        let topOffset = UIApplication.shared.statusBarFrame.height  // https://stackoverflow.com/questions/25973733/status-bar-height-in-swift
            + navigationController!.navigationBar.frame.maxY
            + 50
        
        mainView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            // If the nav bar is translucent:
//            make.top.equalToSuperview().inset(navigationController!.navigationBar.frame.maxY + 100)
            // If the nav bar is not translucent.
            make.top.equalToSuperview().inset(topOffset)
            make.bottom.equalToSuperview().inset(30)
        }
        
        promptLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(PracticeViewController.practiceViewWidthRatio)
            make.centerX.equalToSuperview()
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
            make.top.equalToSuperview().inset(topOffset * 0.9)
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
    
    @objc func toggleButtonTapped() {
        if toggleButton.image == Icons.startIcon {
            timingBar.start()
            toggleButton.image = Icons.pauseIcon
        } else if toggleButton.image == Icons.pauseIcon {
            timingBar.pause()
            toggleButton.image = Icons.startIcon
        }
    }
    
    @objc func doneButtonTapped() {
        doneButton.isHidden = true
        nextButton.isHidden = false
    }
    
    @objc func nextButtonTapped() {
        doneButton.isHidden = false
        nextButton.isHidden = true
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
    
    @objc func handleAPINotification(_ notification: Notification) {
        guard let message = notification.userInfo?["message"] as? String else {
            return
        }
        DispatchQueue.main.async {
            ErrorMessageView.show(
                in: self.view,
                message: message
            )
        }
    }
    
    @objc func maskViewTapped() {
        timingBar.start()
        toggleButton.image = Icons.pauseIcon
    }
}

extension PracticeViewController: TimingBarDelegate {
    
    private func presentTimeUpAlert(duration: TimeInterval, completion: @escaping (_ isOk: Bool) -> Void) {
        
        let message: String = {
            var message = Strings.timeUpAlertBody
            
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
        
        let cancelButton = UIAlertAction(
            title: Strings.cancel,
            style: .cancel,
            handler: { (_) -> Void in
                completion(false)
            })
        alert.addAction(cancelButton)
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func stopPracticing() {
        fatalError("stopPracticing() has not been implemented.")
    }
    
    // MARK: - TimingBar Delegate
    
    func timingBarTimeUp(timingBar: TimingBar) {
        self.shouldFinishPracticing = true
        
        self.cancelButton.isEnabled = false
        self.cancelButton.tintColor = Colors.inactiveSystemButtonColor
        
        self.toggleButton.isEnabled = false
        self.toggleButton.tintColor = Colors.inactiveSystemButtonColor
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
        view.bringSubviewToFront(maskView)  // The mask view should be in the front of all views.
    }
}

extension PracticeViewController {
    
    // MARK: - Constants
    
    static let practiceViewWidthRatio: CGFloat = 0.8
    
}
