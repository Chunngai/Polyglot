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
    
    // MARK: - Controllers
    
    var delegate: TimingBarDelegate!
    
    // MARK: - Views
    
    private var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.trackTintColor = Colors.timingBarTintColor
        progressView.progressTintColor = Colors.lightBlue
        progressView.layer.masksToBounds = true
        progressView.layer.cornerRadius = Sizes.smallCornerRadius
        return progressView
    }()
        
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
        
        delegate.timingBarTimingStarted?(timingBar: self)
        
        // https://www.hackingwithswift.com/example-code/system/how-to-make-an-action-repeat-using-timer
        timer = Timer.scheduledTimer(timeInterval: TimeInterval.second, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
    }
    
    func pause() {
        
        delegate.timingBarTimingPaused?(timingBar: self)

        // https://www.hackingwithswift.com/example-code/system/how-to-make-an-action-repeat-using-timer
        timer.invalidate()
    }
    
    func stop() {
        
        timer.invalidate()
    }
}

extension TimingBar {
    
    // MARK: - Selectors
    
    @objc private func fireTimer() {
        // TODO: - Note that the current timing will not be executed in background. So it is just a visual effect.
        if !TimingBar.isTimingEnabled {
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

}

extension TimingBar {
    
    // MARK: - Constants
    
    private static let defaultDuration: Double = TimeInterval.minute * 10
    static var isTimingEnabled: Bool = true
    
}

@objc protocol TimingBarDelegate {
    
    @objc optional func timingBarSet(toggleButton: UIBarButtonItem)
    
    func timingBarTimeUp(timingBar: TimingBar)
    
    @objc optional func timingBarTimingStarted(timingBar: TimingBar)
    @objc optional func timingBarTimingPaused(timingBar: TimingBar)
}
