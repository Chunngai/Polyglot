//
//  VideoShadowingPracticeView.swift
//  Polyglot
//
//  Created by Ho on 5/2/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import UIKit
import WebKit

class VideoShadowingPracticeView: TextMeaningPracticeView {
    
    var videoURLString: String!
    var videoID: String!
    var startingTimestamp: Double!
    var captionEvents: [YoutubeVideoParser.CaptionEvent] = []
    
    var highlightedCaptionRange: NSRange? = nil
    
    var hasJumpedToStartingTimestamp: Bool = false
    
    var isUserScrolling: Bool = false
    
    var isTextHidden: Bool = true
    var isTogglingTextHiddenState: Bool = false
    
    // MARK: - Views
    
    lazy var youtubeWebView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        let webView = WKWebView(
            frame: .zero,
            configuration: configuration
        )
        webView.navigationDelegate = self
        webView.configuration.userContentController.add(
            self,
            name: Self.youtubeWebViewPlayerHandler
        )
        webView.configuration.userContentController.add(
            self, 
            name: Self.youtubeWebViewTimeHandler
        )
        webView.layer.cornerRadius = Sizes.smallCornerRadius
        webView.layer.masksToBounds = true
        return webView
    }()
    
    lazy var rewindButton = createControlButton(
        image: Images.videoShadowingPracticeRewindButtonImage,
        action: #selector(rewindButtonTapped(_:))
    )
    lazy var playPauseButton = createControlButton(
        image: Images.videoShadowingPracticePlayButtonImage,
        action: #selector(playPauseButtonTapped(_:))
    )
    lazy var forwardButton = createControlButton(
        image: Images.videoShadowingPracticeForwardButtonImage,
        action: #selector(forwardButtonTapped(_:))
    )
    
    lazy var youtubeControlsView: UIStackView = {
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = Sizes.smallStackSpacing
        stackView.backgroundColor = Colors.lightGrayBackgroundColor
        stackView.layer.masksToBounds = true
        stackView.layer.cornerRadius = Sizes.defaultCornerRadius
        
        stackView.addArrangedSubview(rewindButton)
        stackView.addArrangedSubview(playPauseButton)
        stackView.addArrangedSubview(forwardButton)
        
        return stackView
    }()
    
    lazy var hideTextButton: UIButton = {
        let button = UIButton()
        button.addTarget(
            self,
            action: #selector(hideTextButtonTapped),
            for: .touchUpInside
        )
        button.setImage(
            Images.videoShadowingPracticeShowTextImage,
            for: .normal
        )
        return button
    }()
    
    // MARK: - Init
    
    init(
        frame: CGRect = .zero,
        text: String,
        meaning: String,
        textLang: LangCode,
        meaningLang: LangCode,
        textSource: TextSource,
        isTextMachineTranslated: Bool,
        machineTranslatorType: MachineTranslatorType,
        existingPhraseRanges: [NSRange],
        existingPhraseMeanings: [String],
        textAccentLocs: [Int],
        videoURLString: String,
        videoID: String,
        startingTimestamp: Double,
        captionEvents: [YoutubeVideoParser.CaptionEvent]
    ) {
        super.init(
            frame: frame,
            text: text,
            meaning: meaning,
            textLang: textLang,
            meaningLang: meaningLang,
            textSource: textSource,
            isTextMachineTranslated: isTextMachineTranslated,
            machineTranslatorType: machineTranslatorType,
            existingPhraseRanges: existingPhraseRanges,
            existingPhraseMeanings: existingPhraseMeanings,
            totalRepetitions: 1,
            currentRepetition: 1,
            textAccentLocs: textAccentLocs,
            repetitionIncrement: 1
        )
        
        self.videoURLString = videoURLString
        self.videoID = videoID
        self.startingTimestamp = startingTimestamp
        self.captionEvents = captionEvents
        
        upperString = text
        
        updateSetups()
        updateViews()
        updateLayouts()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateSetups() {
        super.updateSetups()
        
        loadYouTubeVideo()
        
        textView.tappingDelegate = self
    }
    
    override func updateViews() {
        super.updateViews()
        
        self.hideText()
        
        addSubview(youtubeWebView)
        addSubview(youtubeControlsView)
        addSubview(hideTextButton)
    }
    
    override func updateLayouts() {
        super.updateLayouts()
        
        youtubeWebView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(youtubeWebView.snp.width).multipliedBy(9.0/16.0) // 16:9比例
        }
        
        youtubeControlsView.snp.makeConstraints { make in
            make.width.equalTo(200)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(20)
            make.height.equalTo(60)
        }
        
        textView.snp.makeConstraints { make in
            make.top.equalTo(youtubeWebView.snp.bottom).offset(20)
            make.bottom.equalTo(youtubeControlsView.snp.top).offset(-20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        hideTextButton.snp.makeConstraints { make in
            make.leading.trailing.equalTo(listenButton)
            make.centerY.equalTo(youtubeControlsView.snp.centerY)
        }
    }

}

extension VideoShadowingPracticeView {
    
    // MARK: - Utils
    
    private func createControlButton(image: UIImage, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: Sizes.videoShadowingControlButtonSize)
        button.addTarget(
            self,
            action: action,
            for: .touchUpInside
        )
        return button
    }
    
    private func loadYouTubeVideo() {
        let embedHTML = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body { margin: 0; padding: 0; background-color: black; }
                .video-container { position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; }
                .video-container iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }
         </style>
        </head>
        <body>
            <div class="video-container">
                <iframe id="player" src="https://www.youtube.com/embed/\(self.videoID ?? "")?playsinline=1&autoplay=0&enablejsapi=1" frameborder="0" allowfullscreen></iframe>
            </div>
            <script>
                var player;
                function onYouTubeIframeAPIReady() {
                    player = new YT.Player('player', {
                        events: {
                            'onReady': onPlayerReady,
                            'onStateChange': onPlayerStateChange
                        }
                    });
                }
                function onPlayerReady(event) {
                    window.webkit.messageHandlers.playerHandler.postMessage('ready');
                }
                function onPlayerStateChange(event) {
                    // Send player state to Swift
                    window.webkit.messageHandlers.playerHandler.postMessage(event.data);
        
                    // If playing, start sending time updates
                    if (event.data === YT.PlayerState.PLAYING) {
                        startTimeUpdates();
                    } else {
                        stopTimeUpdates();
                    }
                }
                var timeUpdateInterval;
                function startTimeUpdates() {
                    // Send time updates every 100ms
                    timeUpdateInterval = setInterval(function() {
                        var currentTime = player.getCurrentTime();
                        window.webkit.messageHandlers.timeHandler.postMessage(currentTime);
                    }, 100);
                }
                function stopTimeUpdates() {
                    clearInterval(timeUpdateInterval);
                }
                function playPause() {
                    if (player.getPlayerState() === YT.PlayerState.PLAYING) {
                        player.pauseVideo();
                    } else {
                        player.playVideo();
                    }
                }
                function rewind(seconds) {
                    player.seekTo(player.getCurrentTime() - seconds);
                }
                function forward(seconds) {
                    player.seekTo(player.getCurrentTime() + seconds);
                }
                function setSpeed(speed) {
                    player.setPlaybackRate(speed);
                }
                function getCurrentTime() {
                    if (player && player.getCurrentTime) {
                        var currentTime = player.getCurrentTime();
                        return currentTime;
                    }
                    return 0;
                }
                function seekTo(seconds) {
                    if (player && player.seekTo) {
                        player.seekTo(seconds);
                    }
                }
             </script>
             <script src="https://www.youtube.com/iframe_api"></script>
        </body>
        </html>
        """
        
        youtubeWebView.loadHTMLString(embedHTML, baseURL: nil)
    }
    
    func currentTimestamp(completion: @escaping (Double) -> Void) {
        
        self.youtubeWebView.evaluateJavaScript("getCurrentTime()") { rst, error in
            if let error = error {
                print(error)
            }
            if let rst = rst as? Double {
                completion(rst)
            }
        }
        
    }
    
    private func hideText() {
        
        // Define the attributes for words
        let wordAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Colors.clozeMaskColor,
            .backgroundColor: Colors.clozeMaskColor
        ]
        
        // Regular expression to find word boundaries
        let pattern = "\\S+"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(
                in: textView.attributedText.string,
                range: NSRange(
                    location: 0,
                    length: textView.attributedText.length
                )
            )
            
            // Apply attributes to each matched word
            for match in matches {
                textView.textStorage.addAttributes(wordAttributes, range: match.range)
            }
        } catch {
            print("Error creating regex: \(error)")
        }
        
    }
    
    private func showText() {
        
        textView.textStorage.setTextColor(with: Colors.weakTextColor)
        if let highlightedCaptionRange = highlightedCaptionRange {
            textView.textStorage.setTextColor(for: highlightedCaptionRange, with: Colors.normalTextColor)
        }
        textView.textStorage.setBackgroundColor(with: textView.backgroundColor ?? Colors.defaultBackgroundColor)
        
        // Recover new words and highlighted words.
        textView.highlightAll()
        textView.underlineAll()
        
    }
    
}

extension VideoShadowingPracticeView {
    
    // MARK: - Selectors
    
    @objc private func rewindButtonTapped(_ sender: UIButton) {
        
        self.youtubeWebView.evaluateJavaScript("rewind(5)")

    }
    
    @objc private func playPauseButtonTapped(_ sender: UIButton) {

        self.youtubeWebView.evaluateJavaScript("playPause()") { result, error in
            if let error = error {
                print("JavaScript执行错误: \(error)")
            }
            if !self.hasJumpedToStartingTimestamp {
                let seekToScript = "seekTo(\(self.startingTimestamp ?? 0))"
                self.youtubeWebView.evaluateJavaScript(seekToScript) { result, error in
                    if let error = error {
                        print("Failed to seek to `startingTimestamp`,")
                    }
                }
                self.hasJumpedToStartingTimestamp = true
            }
        }

        
        if playPauseButton.image(for: .normal) == Images.videoShadowingPracticePlayButtonImage {
            playPauseButton.setImage(
                Images.videoShadowingPracticePauseButtonImage,
                for: .normal
            )
        } else {
            playPauseButton.setImage(
                Images.videoShadowingPracticePlayButtonImage,
                for: .normal
            )
        }

    }
    
    @objc private func forwardButtonTapped(_ sender: UIButton) {
        
        self.youtubeWebView.evaluateJavaScript("forward(5)")

    }
    
    @objc private func hideTextButtonTapped() {
        
        let currentContentOffset = textView.contentOffset
        self.isTogglingTextHiddenState = true  // Without this the showing/hiding will lead to strange scrolling.
                
        if hideTextButton.image(for: .normal) == Images.videoShadowingPracticeHideTextImage {
                        
            hideText()
                        
            hideTextButton.setImage(
                Images.videoShadowingPracticeShowTextImage,
                for: .normal
            )
            
            isTextHidden = true
            
            textView.setContentOffset(
                currentContentOffset,
                animated: false
            )
            
            isTogglingTextHiddenState = false
                    
            
        } else {
            
            showText()
                        
            hideTextButton.setImage(
                Images.videoShadowingPracticeHideTextImage,
                for: .normal
            )
                        
            isTextHidden = false
            
            textView.setContentOffset(
                currentContentOffset,
                animated: false
            )
                        
            isTogglingTextHiddenState = false
                        
        }
    }
    
}

extension VideoShadowingPracticeView {
    
    private func handlePlayerStateChange(_ state: Int) {
        
        // YouTube player states:
        // -1 (unstarted)
        // 0 (ended)
        // 1 (playing)
        // 2 (paused)
        // 3 (buffering)
        // 5 (video cued)
        
        DispatchQueue.main.async {
            if state == 1 { // Playing
                self.playPauseButton.setImage(
                    Images.videoShadowingPracticePauseButtonImage,
                    for: .normal
                )
            } else if state == 2 { // Paused
                self.playPauseButton.setImage(
                    Images.videoShadowingPracticePlayButtonImage,
                    for: .normal
                )
            }
        }
    }
    private func updateHighlightedCaption(for currentTime: Double, shouldScroll: Bool = true) {
        
        let currentTimeMs = currentTime * 1000  // S -> MS.
        var activeCaptionEvent: YoutubeVideoParser.CaptionEvent? = nil
        for captionEvent in self.captionEvents {
            if (
                currentTimeMs >= captionEvent.startMs
                && currentTimeMs < captionEvent.startMs + captionEvent.durationMs
            ) {
                
                activeCaptionEvent = captionEvent
            }
        }
        
        guard let activeCaptionEvent = activeCaptionEvent else {
            print("Could not find an active caption event.")
            return
        }
        
        // Update the text view with highlighting
        updateTextView(
            with: activeCaptionEvent.segs,
            currentTime: currentTime,
            shouldScroll: shouldScroll
        )
    }
        
    private func updateTextView(with activeCaption: String, currentTime: Double, shouldScroll: Bool) {

        // Set the old one with weak color.
        if
            let highlightedCaptionRange = highlightedCaptionRange,
            !isTextHidden
        {
            textView.textStorage.setTextColor(
                for: highlightedCaptionRange,
                with: Colors.weakTextColor
            )
        }
        
        let targetString = activeCaption
        let targetRange = (textView.text as NSString).range(of: targetString)
        
        if !isTextHidden {
            textView.textStorage.setTextColor(
                for: targetRange,
                with: Colors.normalTextColor
            )
        }
        if !isUserScrolling && !isTogglingTextHiddenState && shouldScroll {

            textView.scrollToTop(for: targetRange, animated: true)
            
        }
        
        highlightedCaptionRange = targetRange

    }
    
}

extension VideoShadowingPracticeView: WKNavigationDelegate {
        
    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
}

extension VideoShadowingPracticeView: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if message.name == Self.youtubeWebViewPlayerHandler {
            if
                let messageBody = message.body as? String,
                    messageBody == "ready"
            {
                print("Player is ready")
            } else if let state = message.body as? Int {
                // Handle player state changes
                handlePlayerStateChange(state)
            }
        } else 
        if message.name == Self.youtubeWebViewTimeHandler,
            let time = message.body as? Double
        {
            updateHighlightedCaption(for: time)
        }
    }

}

extension VideoShadowingPracticeView {
    
    override func tapped(at tappedTextRange: UITextRange) {
        super.tapped(at: tappedTextRange)
        
        // Get the full text of the text view
        guard let fullText = textView.text else {
            return
        }
        
        // Find the range of the tapped position in the full text
        let tappedPosition = tappedTextRange.start
        let offset = textView.offset(
            from: textView.beginningOfDocument,
            to: tappedPosition
        )
        
        // Find the nearest newlines before and after the tapped position
        let beforeRange = fullText.rangeOfCharacter(
            from: .newlines,
            options: .backwards,
            range: fullText.startIndex..<fullText.index(
                fullText.startIndex,
                offsetBy: offset
            )
        )
        
        let afterRange = fullText.rangeOfCharacter(
            from: .newlines,
            options: [],
            range: fullText.index(
                fullText.startIndex,
                offsetBy: offset
            )..<fullText.endIndex
        )
        
        // Extract the text between newlines
        let startIndex = beforeRange?.upperBound ?? fullText.startIndex
        let endIndex = afterRange?.lowerBound ?? fullText.endIndex
        let tappedText = String(fullText[startIndex..<endIndex]).strip()
        
        // Find and seek to the matching caption
        if let captionEvent = captionEvents.first(where: { $0.segs.strip() == tappedText }) {
            
            // Seek to the start time of this caption
            let seekScript = "seekTo(\(captionEvent.startMs / 1000));"
            youtubeWebView.evaluateJavaScript(seekScript) { _, error in
                
                if let error = error {
                    print("Seek failed: \(error.localizedDescription)")
                    return
                }
                
                // Optionally play the video if it's paused
                let playScript = "player.playVideo();"
                self.youtubeWebView.evaluateJavaScript(playScript)
                
            }
            
        }
    }
    
}

extension VideoShadowingPracticeView {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.isUserScrolling = true
        }
        
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.isUserScrolling = false
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.isUserScrolling = false
    }
    
}

extension VideoShadowingPracticeView {
    
    // MARK: - Constants
    
    static let youtubeWebViewPlayerHandler = "playerHandler"
    static let youtubeWebViewTimeHandler = "timeHandler"
    
}
