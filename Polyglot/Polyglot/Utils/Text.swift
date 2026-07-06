//
//  Text.swift
//  Polyglot
//
//  Created by Ho on 2/9/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation
import NaturalLanguage

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

func convertRussianJoToJe(text: String) -> String {
    return text.replacingOccurrences(of: "ё", with: "е")
}

// MARK: - Syllabification for phrase construction practice

func syllabifyPhrase(_ phrase: String, lang: LangCode) -> [String] {
    switch lang {
    case .ja: return _splitJapanese(phrase)
    case .ko: return _splitKorean(phrase)
    default:
        return phrase
            .components(separatedBy: CharacterSet(charactersIn: " -"))
            .filter { !$0.isEmpty }
            .flatMap { _syllabifyAlpha($0, lang: lang) }
    }
}

private func _splitJapanese(_ phrase: String) -> [String] {
    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.setLanguage(.japanese)
    tokenizer.string = phrase
    var rawWords: [String] = []
    tokenizer.enumerateTokens(in: phrase.startIndex..<phrase.endIndex) { range, _ in
        rawWords.append(String(phrase[range]))
        return true
    }
    var words: [String] = []
    var indexOfLastWord = -1
    for i in 0..<rawWords.count {
        let rawWord = rawWords[i]
        if i > 0 && Tokens.japaneseParticles.contains(rawWord) {
            words[indexOfLastWord] = words[indexOfLastWord] + rawWord
        } else {
            words.append(rawWord)
            indexOfLastWord += 1
        }
    }
    return words
}

private func _splitKorean(_ phrase: String) -> [String] {
    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.setLanguage(.korean)
    tokenizer.string = phrase
    var tokens: [String] = []
    tokenizer.enumerateTokens(in: phrase.startIndex..<phrase.endIndex) { range, _ in
        tokens.append(String(phrase[range]))
        return true
    }
    return tokens
}

private struct SyllabifyConfig {
    let vowels: CharacterSet
    let vowelMultigraphs: [String]
    let validOnsets: Set<String>
    let transparentChars: CharacterSet
}

private let syllabifyConfigs: [LangCode: SyllabifyConfig] = [
    .en: SyllabifyConfig(
        vowels: CharacterSet(charactersIn: "aeiouAEIOU"),
        vowelMultigraphs: ["eau","igh","ai","ay","ea","ee","ei","ey","ie","oa","oe","oi","oo","ou","ow","oy","au","aw","ew","ue","ui"],
        validOnsets: ["bl","br","cl","cr","dr","fl","fr","gl","gr","pl","pr","sc","sk","sl","sm","sn","sp","sq","st","sw","tr","tw","wh","wr","sch","scr","spl","spr","str","thr","shr","ch","sh","th","ph","gh","tch"],
        transparentChars: CharacterSet()
    ),
    .es: SyllabifyConfig(
        vowels: CharacterSet(charactersIn: "aeiouáéíóúüAEIOUÁÉÍÓÚÜ"),
        vowelMultigraphs: ["ai","ay","ei","ey","oi","oy","au","eu","ia","ie","io","iu","ua","ue","ui","uo"],
        validOnsets: ["bl","br","cl","cr","dr","fl","fr","gl","gr","pl","pr","tr","ch","ll","rr"],
        transparentChars: CharacterSet()
    ),
    .de: SyllabifyConfig(
        vowels: CharacterSet(charactersIn: "aeiouäöüAEIOUÄÖÜ"),
        vowelMultigraphs: ["äu","ei","ie","eu","au","ai","ay","oi","oy","ui","ee","aa","oo"],
        validOnsets: ["bl","br","cl","cr","dr","fl","fr","gl","gr","pl","pr","tr","tw","kn","pf","qu","tsch","sch","str","spr","schr","schm","schn","schw","schl","ch","sh","th","sp","st","ph"],
        transparentChars: CharacterSet()
    ),
    .ru: SyllabifyConfig(
        vowels: CharacterSet(charactersIn: "аеёиоуыэюяАЕЁИОУЫЭЮЯ"),
        vowelMultigraphs: [],
        validOnsets: ["стр","здр","зн","зд","зр","зг","ст","сп","сл","см","сн","св","ск","пр","тр","кр","гр","бр","вр","др","фр","жд","нт","нд","нк","нг","хт","фт","ств"],
        transparentChars: CharacterSet(charactersIn: "ьъЬЪ")
    ),
]

private let inseparableSequences: [LangCode: [String]] = [
    .en: ["tch","igh","ck","ch","sh","th","ph","gh","wh","qu","ee","ea","ou","oo","ai","ay","oi","oy","au","aw","ew","ue","ui","oa","oe"],
    .es: ["gu","qu","ch","ll","rr","ai","ay","ei","ey","oi","oy","au","eu","ia","ie","io","iu","ua","ue","ui","uo"],
    .de: ["tsch","sch","str","spr","schr","schm","schn","schw","schl","ck","ng","pf","qu","ch","sp","st","ph","th","ei","ie","eu","äu","au","ai","ay","oi","oy","ui"],
    .ru: ["стр","здр","ств","зн","зд","зр","зг","ст","сп","сл","см","сн","св","ск","пр","тр","кр","гр","бр","вр","др","фр","жд","нт","нд","нк","нг","хт","фт"],
]

private func _adjustSplitPoint(_ splitPoint: Int, in chars: [Character], lang: LangCode) -> Int {
    guard let seqs = inseparableSequences[lang] else { return splitPoint }
    let lower = chars.map { Character(String($0).lowercased()) }
    for seq in seqs.sorted(by: { $0.count > $1.count }) {
        let seqChars = Array(seq)
        let seqLen = seqChars.count
        for start in max(0, splitPoint - seqLen + 1)..<min(chars.count - seqLen + 1, splitPoint + 1) {
            let slice = Array(lower[start..<(start + seqLen)])
            if slice == seqChars && splitPoint > start && splitPoint < start + seqLen {
                return start
            }
        }
    }
    return splitPoint
}

private func _mergeShortChunks(_ chunks: [String], minLen: Int = 2) -> [String] {
    guard chunks.count > 1 else { return chunks }
    var result = chunks
    var i = 0
    while i < result.count - 1 {
        if result[i].count < minLen {
            result[i + 1] = result[i] + result[i + 1]
            result.remove(at: i)
        } else { i += 1 }
    }
    i = result.count - 1
    while i > 0 {
        if result[i].count < minLen {
            result[i - 1] = result[i - 1] + result[i]
            result.remove(at: i)
        }
        i -= 1
    }
    return result
}

private func _syllabifyAlpha(_ word: String, lang: LangCode) -> [String] {
    guard let config = syllabifyConfigs[lang] else { return [word] }
    let lower = word.lowercased()
    let chars = Array(lower)
    let origChars = Array(word)
    guard !chars.isEmpty else { return [] }

    func isVowel(_ idx: Int) -> Bool {
        String(chars[idx]).unicodeScalars.allSatisfy { config.vowels.contains($0) }
    }
    func isTransparent(_ idx: Int) -> Bool {
        String(chars[idx]).unicodeScalars.allSatisfy { config.transparentChars.contains($0) }
    }

    var nuclei: [Range<Int>] = []
    var i = 0
    while i < chars.count {
        if isTransparent(i) && i + 1 < chars.count && isVowel(i + 1) {
            nuclei.append(i..<(i + 2)); i += 2
        } else if isVowel(i) {
            var matched = false
            for mg in config.vowelMultigraphs {
                let mgChars = Array(mg)
                let end = i + mgChars.count
                if end <= chars.count && Array(chars[i..<end]) == mgChars {
                    nuclei.append(i..<end); i = end; matched = true; break
                }
            }
            if !matched {
                let start = i
                while i < chars.count && isVowel(i) { i += 1 }
                nuclei.append(start..<i)
            }
        } else { i += 1 }
    }

    if nuclei.count <= 1 {
        if chars.count <= 2 { return [word] }
        var splitPoint: Int
        if let nucleus = nuclei.first {
            splitPoint = nucleus.upperBound
            if splitPoint >= chars.count { splitPoint = chars.count / 2 }
            if splitPoint == 0 { splitPoint = 1 }
        } else {
            splitPoint = (chars.count + 1) / 2
        }
        splitPoint = _adjustSplitPoint(splitPoint, in: Array(word), lang: lang)
        if splitPoint <= 0 || splitPoint >= origChars.count { return [word] }
        return _mergeShortChunks([String(origChars[0..<splitPoint]), String(origChars[splitPoint...])])
    }

    func splitConsonants(_ consonants: [Character]) -> Int {
        let n = consonants.count
        if n == 0 { return 0 }
        if n == 1 { return 0 }
        var nonTransparentStart = 0
        while nonTransparentStart < n &&
              String(consonants[nonTransparentStart]).unicodeScalars.allSatisfy({ config.transparentChars.contains($0) }) {
            nonTransparentStart += 1
        }
        if nonTransparentStart == n { return n }
        let lc = consonants.map { Character(String($0).lowercased()) }
        for keepLeft in nonTransparentStart..<n {
            let onset = String(lc[keepLeft...])
            if config.validOnsets.contains(onset) || keepLeft == n - 1 { return keepLeft }
        }
        return max(0, n - 1)
    }

    var syllables: [String] = []
    var pos = 0
    for k in 0..<nuclei.count {
        let nucleus = nuclei[k]
        if k == nuclei.count - 1 {
            syllables.append(String(origChars[pos...]))
        } else {
            let nextNucleus = nuclei[k + 1]
            let consonants = Array(chars[nucleus.upperBound..<nextNucleus.lowerBound])
            let keepLeft = splitConsonants(consonants)
            var splitPoint = nucleus.upperBound + keepLeft
            splitPoint = _adjustSplitPoint(splitPoint, in: Array(word), lang: lang)
            syllables.append(String(origChars[pos..<splitPoint]))
            pos = splitPoint
        }
    }
    return _mergeShortChunks(syllables.filter { !$0.isEmpty })
}
