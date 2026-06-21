//
//  VideoShadowingPracticeProducer.swift
//  Polyglot
//
//  Created by Ho on 4/30/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import Foundation

class VideoShadowingPracticeProducer: TextMeaningPracticeProducer {
    
    override var currentPractice: BasePractice {
        get {
            if self.practiceList.isEmpty {
                self.practiceList.append(contentsOf: self.make())
            }
            
            let practice = self.practiceList[self.currentPracticeIndex]
            if
                let practice = practice as? VideoShadowingPractice,
                case let .article(articleId, _, _) = practice.textSource
            {
                practice.captionEvents = self.articles.getArticle(from: articleId)?.captionEvents ?? []
            }
            return practice
        }
        set {
            self.practiceList[self.currentPracticeIndex] = newValue
        }
    }
    
    // MARK: - Init
    
    var selectedArticle: Article?

    init(words: [Word], articles: [Article]) {

        super.init(
            words: words,
            articles: articles,
            isDuolingoOnly: false
        )
        
//        self.practiceList = VideoShadowingPracticeProducer.loadCachedPractices(for: LangCode.currentLanguage)
//
//        // Make and cache a practice.
//        DispatchQueue.main.async {
//            self.practiceList.append(self.make()[0])
//            self.cache()
//        }
        
    }
    
    override func make() -> [BasePractice] {
        
        // Use the selected article if provided, otherwise randomly choose.
        let youtubeVideo: Article
        if let selected = selectedArticle {
            youtubeVideo = selected
        } else {
            let youtubeVideos = articles.filter { $0.isYoutubeVideo }
            youtubeVideo = youtubeVideos.randomElement() ?? youtubeVideos[0]
        }
        
        // Starting timestamp: load from disk. If not stored on disk, from beginning.
        let metaData = VideoShadowingPracticeProducer.loadMetaData(for: LangCode.currentLanguage)
        let videoID = YoutubeVideoParser.getVideoID(from: youtubeVideo.source ?? "") ?? ""
        let startingTimestamp = Double(metaData[videoID] ?? "0") ?? 0
                
        let text = youtubeVideo.paras.compactMap { para in
            para.text
        }.joined(separator: "\n")
        
        let (
            existingPhraseRanges,
            existingPhraseMeanings
        ) = self.findExistingPhraseRangesAndMeanings(
            for: text,
            from: self.words
        )
                
        return [VideoShadowingPractice(
            text: text,
            meaning: "",
            textLang: LangCode.currentLanguage,
            meaningLang: LangCode.currentLanguage.configs.languageForTranslation,
            textSource: .article(
                articleId: youtubeVideo.id,
                paragraphId: nil,
                sentenceId: nil
            ),
            isTextMachineTranslated: false,
            machineTranslatorType: .none,
            existingPhraseRanges: existingPhraseRanges,
            existingPhraseMeanings: existingPhraseMeanings,
            textAccentLocs: [],
            videoURLString: youtubeVideo.source ?? "",
            videoID: videoID,
            startingTimestamp: startingTimestamp
        )]
            
    }
    
    override func cache() {
        
        guard var practicesToCache = practiceList as? [VideoShadowingPractice] else {
            return
        }
        
        VideoShadowingPracticeProducer.save(
            &practicesToCache,
            for: LangCode.currentLanguage
        )
        
    }
    
    func cache(timestamp: Double) {

        guard let currentPractice = currentPractice as? VideoShadowingPractice else {
            return
        }
        
        var metaData = VideoShadowingPracticeProducer.loadMetaData(for: LangCode.currentLanguage)
        metaData[currentPractice.videoID] = String(timestamp)
        VideoShadowingPracticeProducer.saveMetaData(
            &metaData,
            for: LangCode.currentLanguage
        )
        
    }
    
}

extension VideoShadowingPracticeProducer {
    
    // MARK: - IO
    
    static func fileName(for lang: String) -> String {
        return "cachedVideoShadowingPractices.\(lang).json"
    }
    
    static func loadCachedPractices(for lang: LangCode) -> [VideoShadowingPractice] {
        do {
            let practices = try readDataFromJson(
                fileName: VideoShadowingPracticeProducer.fileName(for: lang.rawValue),
                type: [VideoShadowingPractice].self
            ) as? [VideoShadowingPractice] ?? []
            return practices
        } catch {
            print(error)
            return []
        }
    }
    
    static func save(_ practicesToCache: inout [VideoShadowingPractice], for lang: LangCode) {
        do {
            try writeDataToJson(
                fileName: VideoShadowingPracticeProducer.fileName(for: lang.rawValue),
                data: practicesToCache
            )
        } catch {
            print(error.localizedDescription)
        }
    }
    
}
