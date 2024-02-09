//
//  Text.swift
//  Polyglot
//
//  Created by Ho on 2/9/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation

func convertJapaneseToRomaji(text: String) -> String {
    
    // https://github.com/auramagi/furigana-converter/blob/e8175699d98b60572a6716d60f4fb51ed29e0e2e/furigana-converter/RubyConversionRequestCoreFoundation.swift#L37

    var result = ""
    
    let fullRange: CFRange = CFRangeMake(
        0,
        (text as NSString).length
    )
    
    let tokenizer = CFStringTokenizerCreate(
        kCFAllocatorDefault,
        text as CFString,
        fullRange,
        kCFStringTokenizerUnitWord,
        Locale(identifier: "ja") as CFLocale
    )
    
    // Scan through the string tokens, appending to result Latin transcription and ranges that can't be transcribed.
    var lastPosition: CFIndex = 0
    let kCFStringTokenizerTokenNone = CFStringTokenizerTokenType(rawValue: 0)
    while CFStringTokenizerAdvanceToNextToken(tokenizer) != kCFStringTokenizerTokenNone {
        let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
        if range.location > lastPosition {
            let missingRange = CFRange(
                location: lastPosition,
                length: range.location - lastPosition
            )
            result.append((text as CFString).subString(with: missingRange) as String)
        }
        lastPosition = range.maxPosition
        if let latin = CFStringTokenizerCopyCurrentTokenAttribute(
            tokenizer,
            kCFStringTokenizerAttributeLatinTranscription
        ) as? String {
            result += latin
        }
    }
    if fullRange.maxPosition > lastPosition {
        let missingRange = CFRange(
            location: lastPosition,
            length: fullRange.maxPosition - lastPosition
        )
        result.append((text as CFString).subString(with: missingRange) as String)
    }
    
    return result
}

func convertUSSpellingToUKSpelling(text: String) -> String {
    return us2ukSpellingMapping[text] ?? us2ukSpellingMapping2[text] ?? text
}
