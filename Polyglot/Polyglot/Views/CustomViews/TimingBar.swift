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
    
    private var countSeconds: TimeInterval = 0
    
    // MARK: - Controllers
    
    var delegate: TimingBarDelegate!
    
    // MARK: - Views
    
    private var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.trackTintColor = Colors.timingBarTintColor
        progressView.progressTintColor = Colors.weakLightBlue
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
        
        activateProgress()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        updateSetups()
        updateViews()
        updateLayouts()
        
        activateProgress()
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
    
    // MARK: - Utils
    
    private func presentTimeUpAlert(duration: TimeInterval, completion: @escaping (_ isOk: Bool) -> Void) {
        let reachedMaxDuration: Bool = duration == Vars.maxPracticeDuration
        
        let alert = UIAlertController(
            title: Strings.timeUpAlertTitle,
            message:  reachedMaxDuration ? Strings.maxTimeUpAlertBody : Strings.timeUpAlertBody,
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
        
        if let delegate = delegate as? UIViewController {
            delegate.present(alert, animated: true, completion: nil)
        }
    }
    
    private func timeUp() {
        
        if duration != Vars.maxPracticeDuration {
            presentTimeUpAlert(duration: duration) { (isOk) in
                if isOk {
                    // Update the timing bar.
                    self.addDuration(duration: Vars.practiceDuration)
                    return
                } else {
                    self.delegate.stopPracticing()
                }
            }
        } else {
            presentTimeUpAlert(duration: duration) { (_) in
                self.delegate.stopPracticing()
            }
        }
    }
    
    private func activateProgress() {
        
        // https://www.hackingwithswift.com/example-code/system/how-to-make-an-action-repeat-using-timer
        
        Timer.scheduledTimer(withTimeInterval: TimeInterval.second, repeats: true) { (timer) in
            if self.countSeconds == self.duration {
                timer.invalidate()
                
                self.timeUp()
            }
            
            self.progressView.setProgress(
                Float(self.countSeconds / self.duration),
                animated: true
            )
            
            self.countSeconds += TimeInterval.second
        }
    }
}

extension TimingBar {
    
    func addDuration(duration: TimeInterval) {
        self.duration += duration
        
        activateProgress()
    }
    
}

extension TimingBar {
    
    // MARK: - Constants
    
    private static let defaultDuration: Double = TimeInterval.minute * 10
    
}

@objc protocol TimingBarDelegate {
    
    func stopPracticing()
    
}
