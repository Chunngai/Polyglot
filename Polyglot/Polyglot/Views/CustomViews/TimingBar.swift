//
//  TimingBar.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import UIKit

class TimingBar: UIView {

    var duration: TimeInterval!
    private var secondCounter: TimeInterval = 0
    
    private var timer: Timer!
    private var isTiming: Bool = true {
        didSet {
            if isTiming {
                start()
            } else {
                pause()
            }
        }
    }
    
    // MARK: - Controllers
    
    var delegate: TimingBarDelegate! {
        didSet {
            delegate.timingBarSet?(toggleButton: toggleButton)
        }
    }
    
    // MARK: - Views
    
    private var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.trackTintColor = Colors.timingBarTintColor
        progressView.progressTintColor = Colors.lightBlue
        progressView.layer.masksToBounds = true
        progressView.layer.cornerRadius = Sizes.smallCornerRadius
        return progressView
    }()
    
    private var toggleButton: UIBarButtonItem!
    
    // MARK: - Init
    
    init(frame: CGRect = .zero, duration: TimeInterval = TimingBar.defaultDuration) {
        super.init(frame: frame)
        
        self.duration = duration
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func updateSetups() {
        toggleButton = UIBarButtonItem(
            image: nil,
            style: .plain,
            target: self,
            action: #selector(toggleTimingState)
        )
    }
    
    private func updateViews() {
        addSubview(progressView)
    }
    
    private func updateLayouts() {
        progressView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(300 / 414 * UIScreen.main.bounds.width)  // TODO: - Update here.
            make.height.equalTo(20)
        }
    }
}

extension TimingBar {
        
    func add(duration: TimeInterval) {
        self.duration += duration
    }
    
    func start() {
        
        toggleButton.image = Icons.pauseIcon
        delegate.timingBarTimingStarted?(timingBar: self)
        
        // https://www.hackingwithswift.com/example-code/system/how-to-make-an-action-repeat-using-timer
        timer = Timer.scheduledTimer(timeInterval: TimeInterval.second, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
    }
    
    func pause() {
        
        toggleButton.image = Icons.startIcon
        delegate.timingBarTimingPaused?(timingBar: self)

        // https://www.hackingwithswift.com/example-code/system/how-to-make-an-action-repeat-using-timer
        timer.invalidate()
    }
    
    func stop() {
        
        toggleButton.image = nil

        timer.invalidate()
    }
}

extension TimingBar {
    
    // MARK: - Selectors
    
    @objc private func fireTimer() {
        // TODO: - Note that the current timing will not be executed in background. So it is just a visual effect.
        if !Variables.isTimingEnabled {
            pause()
        }
        
        if self.secondCounter == self.duration {
            self.stop()
            self.delegate.timingBarTimeUp(timingBar: self)
        }
        
        self.progressView.setProgress(
            Float(self.secondCounter / self.duration),
            animated: true
        )
        
        self.secondCounter += TimeInterval.second
    }
    
    @objc private func toggleTimingState() {
        isTiming.toggle()
    }
    
}

extension TimingBar {
    
    // MARK: - Constants
    
    private static let defaultDuration: Double = TimeInterval.minute * 10
    
}

@objc protocol TimingBarDelegate {
    
    @objc optional func timingBarSet(toggleButton: UIBarButtonItem)
    
    func timingBarTimeUp(timingBar: TimingBar)
    
    @objc optional func timingBarTimingStarted(timingBar: TimingBar)
    @objc optional func timingBarTimingPaused(timingBar: TimingBar)
}
