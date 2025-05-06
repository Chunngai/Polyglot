//
//  VideoShadowingPractice.swift
//  Polyglot
//
//  Created by Ho on 5/1/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import Foundation

class VideoShadowingPractice: TextMeaningPractice {
    
    var videoURLString: String
    var videoID: String
    var startingTimestamp: Double
    var captionEvents: [YoutubeVideoParser.CaptionEvent]
    
    init(
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
        captionEvents: [YoutubeVideoParser.CaptionEvent] = []
    ) {
        self.videoURLString = videoURLString
        self.videoID = videoID
        self.startingTimestamp = startingTimestamp
        self.captionEvents = captionEvents
        
        super.init(
            text: text,
            meaning: meaning,
            textLang: textLang,
            meaningLang: meaningLang,
            textSource: textSource,
            isTextMachineTranslated: isTextMachineTranslated,
            machineTranslatorType: machineTranslatorType,
            existingPhraseRanges: existingPhraseRanges,
            existingPhraseMeanings: existingPhraseMeanings,
            totalRepetitions: 0,
            currentRepetition: 0,
            textAccentLocs: textAccentLocs
        )
        
    }
    
    private enum CodingKeys: String, CodingKey {
        
        case videoURLString
        case videoID
        case startingTimestamp
        case captionEvents
        
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(videoURLString, forKey: .videoURLString)
        try container.encode(videoID, forKey: .videoID)
        try container.encode(startingTimestamp, forKey: .startingTimestamp)
        try container.encode(captionEvents, forKey: .captionEvents)
        
        try super.encode(to: encoder)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        videoURLString = try container.decode(String.self, forKey: .videoURLString)
        videoID = try container.decode(String.self, forKey: .videoID)
        startingTimestamp = try container.decode(Double.self, forKey: .startingTimestamp)
        captionEvents = try container.decode([YoutubeVideoParser.CaptionEvent].self, forKey: .captionEvents)
        
        try super.init(from: decoder)
    }
    
}
