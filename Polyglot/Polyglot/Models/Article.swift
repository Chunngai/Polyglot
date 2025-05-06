//
//  Article.swift
//  Polyglot
//
//  Created by Sola on 2022/12/21.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation

struct Paragraph: Codable {
    
    var id: String
    var cDate: Date
    
    var text: String
    var meaning: String?
    
    // For Youtube video captions.
    var startMs: Double?
    var durationMs: Double?
    
    init(text: String, meaning: String? = nil, startMs: Double? = nil, durationMs: Double? = nil) {
        
        self.id = UUID().uuidString
        self.cDate = Date()
        
        self.text = text
        self.meaning = meaning
        
        self.startMs = startMs
        self.durationMs = durationMs
        
    }
    
    static let textMeaningSeparator = "\n"
    
    init(from paraString: String) {
        
        let text: String!
        let meaning: String!
        
        let splits: [String] = paraString.strip().split(with: Paragraph.textMeaningSeparator)
        text = splits[0]
        if splits.count == 2 {
            meaning = splits[1]
        } else {
            meaning = nil
        }
        
        self.init(text: text, meaning: meaning)
    }
    
}

struct Article {
    
    var id: String
    var cDate: Date  // Creation date.
    var mDate: Date  // Modification date.
    
    var title: String
    var topic: String?
    var paras: [Paragraph]
    var source: String?
        
    init(title: String, topic: String? = nil, body: String, source: String? = nil) {
                
        self.cDate = Date()
        self.id = UUID().uuidString
        self.mDate = cDate
        
        self.title = title.strip().normalizeQuotes()
        self.topic = topic?.strip()
        self.paras = Article.makeParas(from: body)
        self.source = source?.strip()
        
    }
    
    init(title: String, topic: String? = nil, captionEvents: [YoutubeVideoParser.CaptionEvent], source: String? = nil) {
                
        self.cDate = Date()
        self.id = UUID().uuidString
        self.mDate = cDate
        
        self.title = title.strip().normalizeQuotes()
        self.topic = topic?.strip()
        self.paras = Article.makeParas(from: captionEvents)
        self.source = source?.strip()
        
    }
    
    mutating func update(newTitle: String? = nil, newTopic: String? = nil, newBody: String? = nil, newSource: String? = nil) {
        
        if let newTitle = newTitle {
            self.title = newTitle.strip().normalizeQuotes()
        }
        
        if let newTopic = newTopic {
            self.topic = newTopic.strip()
        }
        
        if let newBody = newBody {
            updateParas(with: newBody)
        }
        
        if let newSource = newSource {
            self.source = newSource.strip()
        }
        
        self.mDate = Date()
        
    }
    
    mutating func update(newTitle: String? = nil, newTopic: String? = nil, newCaptionEvents: [YoutubeVideoParser.CaptionEvent]? = nil, newSource: String? = nil) {
        
        if let newTitle = newTitle {
            self.title = newTitle.strip().normalizeQuotes()
        }
        
        if let newTopic = newTopic {
            self.topic = newTopic.strip()
        }
        
        if let newCaptionEvents = newCaptionEvents {
            updateParas(with: newCaptionEvents)
        }
        
        if let newSource = newSource {
            self.source = newSource.strip()
        }
        
        self.mDate = Date()
        
    }
}

extension Article {
    
    static let paraSeparator: String = "\n\n"
    
    private static func makeParas(from body: String) -> [Paragraph] {
        
        // Expected body format:
        // text 1
        // meaning 1
        //
        // text 2
        // meaning 2
        //
        // ...
        let paraStrings = body
            .strip()
            .normalizeQuotes()
            .replaceMultipleBlankLinesWithSingleLine()
            .replaceMultipleSpacesWithSingleOne()
            .split(with: Article.paraSeparator)
        
        var paras: [Paragraph] = []
        for paraString in paraStrings {
            if paraString.strip().isEmpty {
                continue
            }
            paras.append(Paragraph(from: paraString))
        }
        
        return paras
    }
    
    private static func makeParas(from captionEvents: [YoutubeVideoParser.CaptionEvent]) -> [Paragraph] {
        
        return captionEvents.map { captionEvent in
            var segs = captionEvent.segs
            segs = segs
                .strip()
                .normalizeQuotes()
                .replaceMultipleSpacesWithSingleOne()
            return Paragraph(
                text: segs,
                startMs: captionEvent.startMs,
                durationMs: captionEvent.durationMs
            )
        }
        
    }
    
    private mutating func updateParas(with newBody: String) {
        
        let paraStringsInNewBody = newBody
            .strip()
            .normalizeQuotes()
            .replaceMultipleBlankLinesWithSingleLine()
            .replaceMultipleSpacesWithSingleOne()
            .split(with: Article.paraSeparator)
        
        var newParas: [Paragraph] = []
        for paraStringInNewBody in paraStringsInNewBody {
            if paraStringInNewBody.strip().isEmpty {
                continue
            }
            let paraInNewBody: Paragraph = Paragraph(from: paraStringInNewBody)
            
            // Check if the para is in the original paras.
            var isNew: Bool = true
            for paraInOldParas in self.paras {
                if paraInNewBody.text == paraInOldParas.text
                    && paraInNewBody.meaning == paraInOldParas.meaning {
                    
                    newParas.append(paraInOldParas)
                    isNew = false
                    
                    break
                }
            }
            if isNew {
                newParas.append(paraInNewBody)
            }
        }
        
        self.paras = newParas
    }
    
    private mutating func updateParas(with newCaptionEvents: [YoutubeVideoParser.CaptionEvent]) {
        self.paras = Self.makeParas(from: newCaptionEvents)
    }
    
}

extension Article: Codable {
    
    enum CodingKeys: String, CodingKey {
        
        case id
        case cDate
        case mDate
        
        case title
        case topic
        case paras
        case source
        
        // Old vars.
        
        case creationDate  // cDate.
        case modificationDate  // mDate.
        
        case body  // paras
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(cDate, forKey: .cDate)
        try container.encode(mDate, forKey: .mDate)
        
        try container.encode(title, forKey: .title)
        try container.encode(topic, forKey: .topic)
        try container.encode(paras, forKey: .paras)
        try container.encode(source, forKey: .source)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            id = try values.decode(String.self, forKey: .id)
        } catch {
            id = UUID().uuidString
        }
        
        do {
            cDate = try values.decode(Date.self, forKey: .cDate)
        } catch {
            cDate = try values.decode(Date.self, forKey: .creationDate)
        }
        
        do {
            mDate = try values.decode(Date.self, forKey: .mDate)
        } catch {
            mDate = try values.decode(Date.self, forKey: .modificationDate)
        }
        
        title = try values.decode(String.self, forKey: .title)
        
        do {
            topic = try values.decode(String?.self, forKey: .topic)
        } catch {
            topic = nil
        }
        
        do {
            paras = try values.decode([Paragraph].self, forKey: .paras)
        } catch {
            let body = try values.decode(String.self, forKey: .body)
            paras = Article.makeParas(from: body)
        }
        
        source = try values.decode(String?.self, forKey: .source)
    }
}

extension Article {
    
    // MARK: - IO
    
    static func fileName(for lang: LangCode) -> String {
        return "articles.\(lang.rawValue).json"
    }
    
    static func load(for lang: LangCode) -> [Article] {
        do {
            let articles = try readDataFromJson(
                fileName: Article.fileName(for: lang),
                type: [Article].self
            ) as? [Article] ?? []
            return articles
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static func save(_ articles: inout [Article], for lang: LangCode) {
        do {
            try writeDataToJson(
                fileName: Article.fileName(for: lang),
                data: articles
            )
        } catch {
            print(error)
            exit(1)
        }
    }
    
}

extension Article {
    
    static func metaDataFileName(for lang: LangCode) -> String {
        return "articles.meta.\(lang.rawValue).json"
    }
    
    static func loadMetaData(for lang: LangCode) -> [String:String] {
        do {
            let metaData = try readDataFromJson(
                fileName: Article.metaDataFileName(for: lang),
                type: [String: String].self
            ) as? [String:String] ?? [:]
            return metaData
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static func saveMetaData(_ metaData: inout [String:String], for lang: LangCode) {
        do {
            try writeDataToJson(
                fileName: Article.metaDataFileName(for: lang),
                data: metaData
            )
        } catch {
            print(error)
            exit(1)
        }
    }
    
}

extension Article {
    
    static let samples: [Article] = [
        Article(title: "日媒报道中国AI自动生成画像受非议，著作权何在？", body: "中国のインターネットで人工知能（AI）を使って制作した絵画やイラストが次々と登場している。画像生成AIは新たな娯楽として盛り上がっている一方、「盗作行為ではないか」という批判や、「AIアートには著作権が発生するか」という議論が起きている。\n在中国的互联网上，使用人工智能（AI）制作的绘画、插图接连不断地发布出来，作为一种新型娱乐方式颇受追捧的同时，也有批判的声音发生，“这是不是一种剽窃行为？”“AI艺术是否会产生著作权问题？”等也导致网民议论纷纷。\n\n画像生成AIとは、キーワードを打ち込むだけでイメージに合った画像を自動生成するもので、誰でも一瞬に「神絵」を創作することができる。世界的に「ミッドジャーニー（Midjourney）」や「ステーブル・ディフュージョン（Stable Diffusion）」といったツールが広まっているほか、「中国のグーグル」と呼ばれるIT大手・百度（Baidu）が開発した「ERNIE-ViLG」が中国では人気だ。\n所谓画像生成AI，是一种仅需要输入关键词即可自动生成符合其印象画作的工具，任何人都能在一瞬间创作出“神画”。从世界范围来说，除了以Midjourney和Stable Diffusion等工具传播以外，被称为“中国版谷歌”的IT大型公司百度开发的“ERNIE-ViLG”在中国颇具人气。", source: "https://www.baidu.com"),
        Article(title: "不带甜味的无糖茶真的好喝吗？", body: "このほど、無糖飲料「元気森林」ブランドの「燃茶」シリーズが全面リニューアルされ、これまで入っていた砂糖代用品のエリスリトールが原材料から除去され、甘みのない無糖茶に生まれ変わった。\nbbb\n\nスーパーを取材したところでは、今の無糖茶ブランドには、ミネラルウォーターメーカーの農夫山泉傘下の「東方樹葉」シリーズをはじめ、サントリー、淳茶舎、茶里王などがあった。\n\nまたお茶ドリンクチェーンの奈雪の茶もこのほど、その直営店で、店内で作るお茶ドリンクとペットボトル入りフルーツティーを含む甘みのある商品に、糖質ゼロで天然の砂糖代用品である羅漢果を全面的に使用することを明らかにした。\n\n今では、糖質ゼロの茶飲料を選ぶ若者が増え続けている。ソーシャルコマースプラットフォーム「小紅書」で「カロリー・糖質ゼロのミルクティ」を検索すると、5千件を超えるノートがヒットする。様々なブランドの低糖・低カロリーのおすすめ飲料を紹介する人もいる。糖質ゼロの登場は、健康な食生活を志向する消費者のニーズを満たしている。\n\n業界関係者は、「新しいスタイルのお茶飲料は、商品競争において『茶葉の競争』、『トッピングするフルーツの競争』、『乳製品の競争』の段階を経てきており、今は『糖質の競争』に突入している」との見方を示す。\n\n中国のデータサービス機関の零点有数が発表した「2022年中国無糖茶飲料産業インサイト報告」によると、無糖茶飲料産業は成長段階に入っており、無糖茶飲料市場の規模は2014年の6億元（1元は約19.6円）から2020年の48億5千万元に増加し、複合年間成長率は40％を超えた。", source: "https://www.baidu.com"),
        Article(title: "每天八杯水”真的健康吗？", body: "ネット上では「健康のために1日に8杯の水(約2リットル)を飲むと良い」という説をよく見かけるが、これには科学的根拠はあるのだろうか？11月25日に、国際学術誌「サイエンス」に掲載された研究は、ヒトの体における１日の水分の出入り（代謝回転量）の法則を導き出している。そして、飲む必要がある水の量に対する多くの人々の見方を覆す形となった。研究によると、「1日8杯の水」は、大部分の人にとっては必要な量を上回っている可能性があるからだ。\nccc\n\n同研究は、中国科学院深セン先進技術研究院医薬所や深セン理工大学（筹）薬学院科研チームが国際チーム約100チームと共同で、26ヶ国に住む生後8日の乳児から96歳の高齢者までの男女計5604人を対象に実施した。そして、ヒトの全ライフサイクルで体における水の代謝回転の法則を世界で初めて割り出した。\n\nヒトの生命維持には、水が必要不可欠だ。水の代謝回転量とは出入する水分を指し、人が必要な水の量をかなりの程度反映していると言える。\n\n研究では、1日の水の代謝回転は、男性で20‐35歳平均4.2リットル、女性では30‐60歳で平均3.3リットル、そして、年齢が上がるにつれて、その量は減り、90歳代では男女ともに約2.5リットルまで下がっていた。\n\nただ、水の代謝回転量は飲む必要がある水の量と同じではない点には注意が必要だ。例えば、20代男性の水の代謝回転量は4.2リットルであるものの、1日4.2リットルの水を飲む必要があるというわけではない。なぜなら、体内のエネルギー代謝の過程で産生される水が全体の約15％占めるほか、残りの85％のうち、半分を食物から、もう半分を飲む水で摂取することになるからだ。そのため、飲む必要がある水の量は1日1.5―1.8リットルということになる。\n\nまた、女性の非脂肪成分は男性より少ないため、女性が飲む必要がある水の量は男性よりも少なく、20代の場合、1日1.3‐1.4リットルが目安となるという。\n\n研究者は、「研究結果から見て1日に8杯の水を飲むというのは、大部分の人にとっては多すぎる可能性がある」と指摘している。\n\nまた、研究では、成人に限って見ると、1日に体水分量の5％しか水の代謝回転が起こらない人がいる一方で、20％もの水の代謝回転が生じる人がおり、個人差がかなり大きいことも分かった。年齢や性別、住んでいる国などによっても、飲む必要がある水の量は異なる。そのため、一律に示された飲む必要がある水の量が、全ての人の健康に有益であるというわけではない。\n\nまた同研究の分析では、気温と湿度が高い場所や標高の高い地域で生活している人、アスリート、妊婦、授乳期の女性、激しい運動をする人などの水の代謝回転率が高かった。加えて、発展途上国や肉体労働の多い人は高い水の代謝回転率を示し、日常的にスポーツをすることも水の代謝回転率を高めていた。", source: "https://www.baidu.com")
    ]
}
