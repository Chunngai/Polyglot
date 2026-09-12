# Polyglot 问题分析

---

## 1. 名词 Case 标注

### 1.1 по алгебре 和 теории 消歧失败

**现象**：по *алгебре* и *теории* вероятности 中，алгебре 和 теории 均无法确定为 dat。

**原因（两个独立问题）**：

- **алгебре**：`prepToCase` 字典（`AccentAnalyzerProtocol.swift` 约 146–168 行）完全缺少 "по" 的条目。Rule B 找到前驱词 "по" 后查 `prepToCase["по"]` 返回 nil，消歧逻辑直接跳过，导致 алгебре 保持 `ambiguous_dat_prep` 状态。
- **теории**：`findPrecedingNonAdjective()` 遇到连词 "и" 就停止，找不到介词 "по"，消歧同样失败。

**修复**：两个问题各自修复：

1. 在 `prepToCase` 字典中补充 "по"（AccentAnalyzerProtocol.swift 约第 155 行 Dative 部分）：

```swift
"по": ["dat"],
```

2. 扩展 `findPrecedingNonAdjective()` 跳过连词和名词：

```swift
private func findPrecedingNonAdjective(_ i: Int, in tokens: [Token], maxSkip: Int = 5) -> String {
    let skipWords: Set<String> = ["и", "или", "но", "да"]
    var j = i - 1
    var skipped = 0
    while j >= 0 && skipped < maxSkip {
        let t = tokens[j].text.lowercased()
        if looksLikeAdjective(t) || skipWords.contains(t) || tokens[j].nounCase != nil {
            j -= 1; skipped += 1
        } else {
            break
        }
    }
    return j >= 0 ? tokens[j].text.lowercased() : ""
}
```

> **批注**：那 алгебре 消歧失败是为什么？
> **回应**：已查明——根本原因是 `prepToCase` 字典缺少 "по" 的条目，与 теории 的问题完全无关。修复只需在字典里加一行 `"по": ["dat"]`。
> **批注**：по 只要求 dat 吗？会不会跟其他 case？
> **回应**：标准俄语中 по 几乎只支配 dative（по дороге、по алгебре、по расписанию 等），个别分配义用法（"по одному"）也是 dat。不支配 gen/inst/prep，极偶尔见 acc 但非常边缘。写 `["dat"]` 即可，不会引起歧义。

---

### 1.2 形容词阻止介词消歧

**现象**：в существующие диалоговые *решения* 中，решения 无法识别格。

**原因**：消歧 Rule B 用 `tokens[i-1]`（直接前驱词）查介词，当前驱词是形容词时查不到介词。

**文件**：`AccentAnalyzerProtocol.swift`，Rule B 消歧逻辑（约 218–236 行）。

**修复**：Rule B 统一改用 `findPrecedingNonAdjective()` 而非 `tokens[i-1]`：

```swift
let precedingWord = findPrecedingNonAdjective(i, in: tokens)
if let prepCases = prepToCase[precedingWord] {
    let resolvedCases = prepCases.intersection(ambiguousCases)
    if resolvedCases.count == 1 {
        nounCase = resolvedCases.first!
    }
}
```

> **批注**：同意

---

### 1.3 В + 年份 + годы 缺少 italics 规则

**现象**：В 1980-е годы 中，В 和 годы 均未斜体。

**原因**：现有规则只处理 "в/на 直接跟着 acc 名词" 的情况，数字夹在中间时被中断。

**文件**：`AccentAnalyzerProtocol.swift`，italics 标注逻辑。

**修复**：处理每个 token 时，若发现 год/годы/лет，向前回溯跳过数字找介词，找到 в/во 则将两者都标为 italics：

```swift
let yearWords: Set<String> = ["год", "годы", "лет", "года"]
if yearWords.contains(token.text.lowercased()) && i >= 2 {
    var k = i - 1
    while k >= 0 && tokens[k].text.range(of: #"^\d"#, options: .regularExpression) != nil {
        k -= 1
    }
    if k >= 0 && (tokens[k].text.lowercased() == "в" || tokens[k].text.lowercased() == "во") {
        // 标记 годы 和 В 为 italics
    }
}
```

> **批注**：同意

---

### 1.4 名词-名词 gen. 结构被 "только" 阻断

**现象**：noun1 только noun2 中，noun2 应确定为 gen.（跟随 noun1 的名词-名词属格结构），但因 "только" 挡在中间，无法向前找到 noun1 确定 case。

**原因**：`AccentAnalyzerProtocol.swift` 第 306-317 行（`calculateNounCaseAnnotations` 的 Rule A）直接用 `tokens[i - 1]` 判断前一个 token 是否为名词（`prevIsNoun`），未做任何跳词处理。"только" 本身没有 `nounCase`，导致 `prevIsNoun` 为 false，gen. 判定失败。

**修复**：新增 `restrictiveParticles` 集合（目前只含 "только"）和 `precedingIndexSkippingParticles()` 函数，向前跳过限定性副词/助词，找到真正的前驱 token 再判断：

```swift
private let restrictiveParticles: Set<String> = ["только"]

private func precedingIndexSkippingParticles(_ i: Int, in tokens: [Token]) -> Int {
    var j = i - 1
    while j >= 0 && restrictiveParticles.contains(tokens[j].text.lowercased()) {
        j -= 1
    }
    return j
}
```

Rule A 中的 `prevText`/`prevIsNoun`/`prevEndsWithOgo`/`prevIsQuantity` 改用跳过 "только" 后的 token（`skipIdx`/`skipText`）计算，其余逻辑不变。

---

## 2. 动词 Aspect 标注

### 2.1 берет 未识别为动词 *(暂不处理)*

**现象**：берет на себя 中，берет 没有 aspect 标注。

---

### 2.2 形动词需要混合着色

**现象**：разбира́ющийся 整词用同一颜色，应该词根部分（разбира́ю+ся）用 aspect 颜色，形容词后缀（щий）用 case 颜色。

**原因**：代码库中完全没有形动词拆分逻辑。`Token` 结构只有 `aspect` 和 `nounCase` 字段，注解结构只支持整词范围，着色逻辑对整个 token 应用单一颜色。

**修复**（分三步）：

1. **`Models/Word.swift`**：`Token` 添加 `participleVerbLength: Int?`，标记**动词部分**（词根 + ся，若有）的字符长度，其余为形容词后缀。

   例：разбира́ющийся → 动词部分 = "разбира́ю" + "ся"，participleVerbLength = len("разбира́юся") = 10；形容词后缀 = "щий"。
   例：разбира́ющий（无 ся）→ participleVerbLength = len("разбира́ю") = 8；形容词后缀 = "щий"。

   因此识别时：先定位形容词后缀（щий/щая/щего/вший 等）起始位置，若后缀前有 "ся"，则 participleVerbLength 包含 ся。

2. **`RussianAccentAnalyzer.swift`**：识别形动词后缀，计算 participleVerbLength 时处理 ся：

   ```swift
   let adjectivalSuffixes = ["ющий", "ющая", "ющего", "вший", "вшая", "щий", "щая", ...]
   if let suffix = adjectivalSuffixes.first(where: { word.hasSuffix($0) }) {
       var verbPart = word.dropLast(suffix.count)
       // ся 属于动词部分，保留在 verbPart 内
       token.participleVerbLength = verbPart.count
   }
   ```

3. **`GrammarAnnotationLegendView.swift`**，`markVerbAspects()` / `markNounCases()`：形动词结构为 [动词词根][形容词后缀][ся?]，需要三段着色：

   - 前 `participleVerbLength` 个字符（动词词根）→ aspect 颜色
   - 中间（形容词后缀）→ case 颜色
   - 末尾 ся（若有，由 `hasReflexiveSuffix: Bool` 标记）→ aspect 颜色

   因此 `Token` 需同时存 `participleVerbLength` 和 `hasReflexiveSuffix`，着色时分三段处理。

> **批注**：同意

---

### 2.3 形动词着色错位（受重音符号插入影响）

**现象**：начинающих 期望 начинаю 用 aspect 颜色、щих 用 case 颜色，实际只有 начина 有颜色，ющих 无色；научившемуся 期望 научив/шему/ся 三段分色，实际只有 науч 和 ус（诡异碎片）有颜色，其余无色。

**原因**：`WordPracticeProducer.swift`，`calculateVerbAspectAnnotations`/`calculateNounCaseAnnotations`（约第 423/426、519/522 行）在 `practice.query` **还是纯净词形**（无重音符号）时计算 verb-root/adjectival-suffix/ся 三段的 position/length。随后 `addAccents()`（约第 468、556 行）把 `practice.query` 替换成带 `Token.accentSymbol`（单引号 `'`）的重音词形，每个 token 插入一个符号，字符串变长，插入点之后的所有字符整体右移。已经算好的三段 annotation 坐标没有跟着调整，导致插入点之后的分段整体错位：始终不受影响的前段（插入点之前的动词词根）颜色正常，插入点之后的段落（形容词后缀、ся）整体错位或消失。这不是形动词专属问题，是任何"先算标注坐标、后插重音符号"的路径共有的隐性 bug，只是形动词因为多段分色，错位效果最明显。

**修复**：不改变计算顺序，改为在 `addAccents()` 之后对已计算的三个 annotation 数组做一次位置修正。新增 `shiftForAccentInsertions()` 计算给定 position/length 在若干重音插入点（用已有的 `calculateAccentLocs(for:with:)` 取得，坐标系与算标注时的纯净词形一致）下的修正后坐标：插入点在 position 之前则 position+1；插入点落在 [position, position+length) 内则 position+1 且 length+1。对 `[VerbAspectAnnotation]`/`[NounCaseAnnotation]`/`[ShortAdjectiveAnnotation]` 各写一个重载调用它，汇总成 `adjustAnnotationsForAccentInsertions(of:tokens:word:)`，在两处 `addAccents()` 调用之后（`makeAndCachePractices()` 约第 468 行、`annotateExistingPractices()` 约第 556 行）分别调用。choices/context 的 annotation 走独立的 `analyzeAccents(for: choice/context)`，未经过 `addAccents()`，字符串未被插入符号，不受影响，无需修正。

实现：✅ 已修复（WordPracticeProducer.swift：新增 `shiftForAccentInsertions`/`adjustForAccentInsertions`（三个重载）/`adjustAnnotationsForAccentInsertions`；两处 `addAccents()` 调用后接入修正）

---

## 3. Phrase Review

### 3.1 case/aspect 标注不一致，且缺少重音标注（使用 3.10 修复，不使用这点的修复方法）

**现象**：部分练习有 case/aspect 标注，部分没有；所有练习缺少重音标注。

**原因**：`WordPracticeProducer.swift`，`makeAndCachePractices()` 中注解逻辑只覆盖 `.meaningSelection`、`.meaningFilling`、`.contextSelection`，phraseConstruction（reordering）类型被排除在外。重音标注同理，未在 phrase review 的渲染路径中调用。

**修复**：重构 `makeAndCachePractices()` 的异步流程，用 `DispatchGroup` 确保所有标注回调完成后再落盘。具体：

```swift
// 伪代码
let annotationGroup = DispatchGroup()
analyzeAccents(for: word) { tokens, _, _ in
    // 主词标注...
    
    // 对选项和上下文，进入嵌套 group
    for choice in choices {
        annotationGroup.enter()
        analyzeAccents(for: choice) { choiceTokens, _, _ in
            // 写入 choiceVerbAspectAnnotations
            annotationGroup.leave()
        }
    }
    
    annotationGroup.notify(queue: .main) {
        self.cache()  // 所有标注完成后统一缓存
    }
}
```

避免标注写入一半时落盘，确保原子性。

> **批注**：我感觉是后台标注存储 timing 问题？不是 phraseConstruction 的原因
> **回应**：用户判断正确。调查确认：phraseConstruction practice 在第 292 行**同步创建后立即 `cache()` 写入磁盘**，而 `analyzeAccents()` 是异步的，回调未完成时 practice 已落盘，导致缓存里的 practice 无标注。其他练习类型（image、reordering、meaning）都在异步回调内部创建和缓存，天然等到标注完成。**修复方向**：延迟 phraseConstruction 的 `cache()` 调用，将其移到 `analyzeAccents()` 回调完成之后，确保标注和 practice 原子性写入。
> **批注**：不对啊，我意思是 phraseConstruction 之外的其它类型的练习，有些有标注有些没标注。我没关注 phraseConstruction 是否有这个情况，但是其他练习类型有
> **回应**：已重新调查。其他练习类型的 timing 问题更复杂——`makeAndCachePractices()` 中有 **7 处 `cache()` 调用**，分布在多层嵌套异步回调中。具体缺失场景：(1) meaningSelection/meaningFilling 的**选项标注**（choiceVerbAspectAnnotations）在嵌套的 `analyzeAccents(for: choice)` 回调中写入，若该回调超时或被中断则永久缺失；(2) contextSelection 的**上下文标注**同理；(3) 用户切换语言或退出 app 时，`word2langForAccentAnalysis` 检查失败，后续所有回调被丢弃，已缓存的 practice 标注永久为空。**根本原因**：标注写入分散在多层嵌套异步回调里，没有统一的"全部完成再缓存"的保证。**修复方向**：用 `DispatchGroup` 包住所有嵌套的 `analyzeAccents()` 调用，在 `notify` 回调中统一执行最后一次 `cache()`，避免标注写入一半时落盘。

---

### 3.2 重音用加粗而非 ' 字符

**现象**：Phrase review 用粗体标重音，其他地方用 `'` 字符。

**原因**：`TextMeaningPracticeView.swift`，`markAccents()` 方法（约 595–619 行）使用 `.font: UIFont.systemFont(weight: .bold)`，而 `Word.accentSymbol` 字符（`WordExtensions.swift` 第 15 行）未被使用。

**修复**：统一使用加粗表示重音。确认 `markAccents()` 方法（约 595–619 行）的加粗逻辑覆盖所有练习类型的渲染路径，phrase review 的 view 层调用同一个方法。

> **批注**：不对，应该统一使用加粗作为重音表示，而不是单引号。
> **回应**：已更新，统一使用加粗。

---

### 3.3 列表项显示练习类型和时间格式

**现象**：列表项左下角缺少练习类型，右下角时间显示带"下一次"标签。

**原因**：`PhraseReviewWordSelectionViewController.swift`，`cellForRowAt`（约 161–189 行）只显示 meaning 或带前缀的日期字符串，无练习类型。

**修复**：左下角从 `EbbinghausSchedule` 读取该词下一次的 practiceType 并显示；右下角去掉 `Strings.nextAvailableDate` 的"下一次"前缀，只显示时间字符串。

> **批注**：同意

---

### 3.4 后台返回时 home 界面练习数量不更新

**原因**：`HomeViewController.swift`，`appMovedToForeground()`（约 410 行）只调用 `displayContentCards()`，未重新加载 `wordPracticeCounter` 和 `ebbinghausSchedule`。

**修复**：

```swift
@objc private func appMovedToForeground() {
    self.wordPracticeCounter = WordPracticeProducer.countWordPractices(for: LangCode.currentLanguage)
    self.ebbinghausSchedule = EbbinghausSchedule.load(for: LangCode.currentLanguage)
    DispatchQueue.main.async { self.applySnapShots() }
    DispatchQueue.global(qos: .userInitiated).async { self.displayContentCards() }
}
```

> **批注**：同意

---

### 3.5 选择单个单词练习时闪退

**原因**：`makePhraseConstructionPractice()` 对单个单词返回 `nil`（chunks.count < 2），导致练习列表为空。`WordsPracticeViewController.swift` 第 145 行强制转换 `as! WordPractice` 崩溃。

**修复**：`WordPracticeProducer.swift` 第 832 行，将 `makePhraseConstructionPractice()` 的限制放宽：

```swift
private func makePhraseConstructionPractice(word: String) -> WordPractice? {
    let chunks = word.syllabified(for: self.lang)
    guard !chunks.isEmpty else { return nil }  // 改为只要非空即可
    // ... 后续逻辑不变
}
```

允许单音节词（chunks.count = 1）参与练习，UI 层 ReorderingPracticeView 可以正常处理。

> **批注**：单个单词也应该允许练习吧？
> **回应**：正确。根本原因是 `makePhraseConstructionPractice()` 第 832 行要求 `chunks.count >= 2`，单音节词返回 nil 导致列表为空崩溃。**修复方向**：将限制改为 `guard !chunks.isEmpty else { return nil }`，允许单词（即使只有一个 chunk）生成 phraseConstruction 练习，UI 层 ReorderingPracticeView 可以正常处理单元素列表。

---

### 3.6 含逗号的短语分割错误

**现象**："правда в том, что" 被分成 "прав", "да", "в", "том, ч", "то"。

**原因**：`Text.swift`，`syllabifyPhrase()` 只按空格和连字符分割，逗号不在分隔符集合内。

**修复**：

```swift
.components(separatedBy: CharacterSet(charactersIn: " -,"))
```

> **批注**：同意

---

### 3.7 部分短语无翻译

**原因**：`WordPracticeProducer.swift`，`uniqueWordEntries()` 初始化 meaning 为空字符串，只在特定练习方向（textToMeaning/meaningToText）下才填充，其他方向的词条 meaning 永远为空。

**修复**：遍历所有练习类型收集 meaning，优先用 `textToMeaning` 方向的 key 字段，兜底用任意非空 meaning 字段。

> **批注**：同意

---

### 3.8 点击按钮显示列表时加载慢

**原因**：`PhraseReviewWordSelectionViewController.swift`，`viewDidLoad()` 在主线程同步调用 `generatePracticesForAvailableWords()`，该方法加载所有单词和文章并生成练习，阻塞 UI。

**修复**：将 `generatePracticesForAvailableWords()` 移至后台线程：

```swift
DispatchQueue.global(qos: .userInitiated).async {
    self.generatePracticesForAvailableWords()
    DispatchQueue.main.async { self.tableView.reloadData() }
}
```

> **批注**：同意

---
### 3.9 Phrase Review 练习进度显示

**现象**：Phrase review 的 practice view 中缺少练习进度指示，用户无法直观看到已完成/本轮总练习数。

**原因（调查结果）**：

1. **practice view 实现**：Phrase review 由 `WordsPracticeViewController`（继承自 `PracticeViewController`）驱动，使用多种 WordPracticeView 子类：
   - `SelectionPracticeView`（选择题）
   - `FillingPracticeView`（填空题）
   - `ReorderingPracticeView`（重排题/短语组词）
   - `ImageSelectionPracticeView`（图片选择）
   均由 `updatePracticeView()` 方法（WordsPracticeViewController.swift 约 143–321 行）根据 practiceType 动态创建。

2. **prompt label 定位**：`PracticeViewController.swift` 第 61–66 行定义 promptLabel，第 194–198 行约束：
   ```swift
   promptLabel.snp.makeConstraints { (make) in
       make.top.equalToSuperview()
       make.width.equalToSuperview().multipliedBy(PracticeViewController.practiceViewWidthRatio)
       make.centerX.equalToSuperview()
   }
   ```
   prompt 水平方向约束为 `centerX`，右侧有充足空间用于放置进度显示。

3. **练习进度来源**：
   - 已完成数：`WordPracticeProducer.practiceList.count` 的减少量，即 `初始总数 - 当前剩余数`
   - 本轮总数：通过 `WordPracticeProducer` 初始化时保存的 `practiceList` 总长度，或从 `wordPracticeCounter` 累加所有 value
   - 两者均在 WordsPracticeViewController 中可访问（practiceProducer 属性）

**修复**：

在 `PracticeViewController` 中新增 `progressLabel: UILabel`：

```swift
var progressLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: Sizes.smallFontSize)
    label.textColor = Colors.weakTextColor
    label.textAlignment = .right
    return label
}()
```

在 `updateLayouts()` 中添加 progressLabel 约束（promptLabel 右侧）：

```swift
progressLabel.snp.makeConstraints { (make) in
    make.top.equalTo(promptLabel.snp.top)
    make.trailing.equalToSuperview().inset(20)
    make.width.greaterThanOrEqualTo(80)
}
```

在 `WordsPracticeViewController.updatePracticeView()` 中，更新完 promptLabel 后计算并显示进度：

```swift
// 计算进度
let totalPractices = practiceProducer.practiceList.count + practiceProducer.excludedPractices.count
let completedCount = initialPracticeCount - practiceProducer.practiceList.count
progressLabel.text = "\(completedCount)/\(initialPracticeCount)"
```

其中 `initialPracticeCount` 在进入练习时保存一次。

> **批注**：进度条应该跟 next() 同步更新吗？

---

### 3.10 标注完成状态记录与优先显示

**现象**：WordPractice 的每个练习的重音和语法标注缺少"是否已完成"状态；进入练习时无法优先显示已标注的练习，也没有后台补标注机制。此外，ShortAdjectiveAnnotation 目前未 apply 到 phrase review 的标注渲染中。

**原因（调查结果）**：

1. **完成状态字段缺失**：`WordPractice.swift` 中无任何完成标记字段。"完成"定义为：accent/grammatical 的 apply 函数被调用过（字段已填充），无需用户确认按钮。

2. **练习列表排序逻辑**：`WordPracticeProducer.swift` 初始化时只执行 `.shuffle()`，无排序逻辑。进入练习时直接取 `practiceList.first`，顺序完全随机。

3. **后台标注机制**：`WordPracticeProducer.makeAndCachePractices()` 中标注是同步的，完成后直接缓存，无后台补标注或 in-place 更新。

4. **ShortAdjectiveAnnotation 未应用于 phrase review**：phrase review 渲染时只 apply 了 VerbAspectAnnotation 和 NounCaseAnnotation，ShortAdjectiveAnnotation 被遗漏。

**修复方向**（分步）：

1. **在 WordPractice 添加完成状态字段** — 仅对 WordPractice（不含 TextMeaningPractice）：
   ```swift
   // WordPractice.swift
   var isAccentAnnotationCompleted: Bool = false      // 新增
   var isGrammarAnnotationCompleted: Bool = false // 新增
   ```
   在 accent apply 函数调用后设 `isAccentAnnotationCompleted = true`，在 grammatical（verb aspect / noun case / short adjective）apply 函数调用后设 `isGrammarAnnotationCompleted = true`。

2. **进入练习时优先显示已标注** — 在 `WordsPracticeViewController` 初始化或 `viewDidLoad()` 中，对 `practiceList` 排序：
   ```swift
   // 两个 flag 均为 true 的排最前，其余保持随机
   producer.practiceList.sort { a, b in
       guard let wa = a as? WordPractice, let wb = b as? WordPractice else { return false }
       let scoreA = (wa.isAccentAnnotationCompleted ? 1 : 0) + (wa.isGrammarAnnotationCompleted ? 1 : 0)
       let scoreB = (wb.isAccentAnnotationCompleted ? 1 : 0) + (wb.isGrammarAnnotationCompleted ? 1 : 0)
       return scoreA > scoreB
   }
   ```

3. **后台补标注 + in-place 更新** — 在 `WordsPracticeViewController.viewDidLoad()` 后启动后台任务，对 incomplete 的练习异步补标注，完成后在 main queue 设置 flag 并触发 UI 更新：
   ```swift
   DispatchQueue.global(qos: .userInitiated).async { [weak self] in
       for (index, practice) in practiceProducer.practiceList.enumerated() {
           guard let wp = practice as? WordPractice,
                 !wp.isAccentAnnotationCompleted || !wp.isGrammarAnnotationCompleted
           else { continue }
           // 调用标注函数 ...
           DispatchQueue.main.async {
               wp.isAccentAnnotationCompleted = true
               wp.isGrammarAnnotationCompleted = true
               // in-place 更新当前练习视图（若 index == currentIndex）
           }
       }
   }
   ```

4. **ShortAdjectiveAnnotation apply 到 phrase review** — 在 phrase review 渲染标注的代码路径中，补充 apply ShortAdjectiveAnnotation（参考 VerbAspectAnnotation 的 apply 方式）。

> **批注**：case 和 aspect 函数 apply 过就算。看看能不能在 wordpractice 增加 isAccentAnnotationCompleted 和 isGrammarAnnotationCompleted 吧。另外 ShortAdjectiveAnnotation 也要 apply 到 phrase review 的标注。

---

### 3.11 Phrase Review 隐藏标注图例

**现象**：Phrase review 的 practice view 显示了 verb aspect / noun case 的标注图例（legend），但与 TextMeaningPracticeView 不同的是，phrase review 中这个图例应该被隐藏。

**原因（调查结果）**：

1. **Legend 实现**：`GrammarAnnotationLegendView.swift` 是可复用的图例组件，包含 verb aspect 和 noun case 的颜色说明（第 14–57 行）。

2. **使用位置**（两套独立实例）：
   - **WordsPracticeViewController**（Phrase Review）：第 16 行创建 `grammarAnnotationLegendView`，在 `updateViews()` 中添加到 mainView（第 131 行），在 `updateLayouts()` 中约束到 promptLabel 下方（第 138–140 行）。
   - **TextMeaningPracticeView**（文本理解练习）：第 195 行创建 `legendView`，同样添加到 mainView（第 323 行），约束在 chatInputBar 上方（第 389–392 行）。

3. **独立性**：两个视图各自拥有独立的 `GrammarAnnotationLegendView` 实例，互不共享。legend 的显示/隐藏由其内部逻辑控制（`isHidden` 属性，第 54 行初始为 true）。

**修复**：

在 `WordsPracticeViewController` 中，阻止 grammarAnnotationLegendView 显示。修改方案：

**方案 1**（推荐，最小改动）：在 `WordsPracticeViewController.updateViews()` 中，创建后立即隐藏：

```swift
override func updateViews() {
    super.updateViews()
    mainView.addSubview(grammarAnnotationLegendView)
    grammarAnnotationLegendView.isHidden = true  // 新增：强制隐藏
}
```

或在 `updatePracticeView()` 中每次都确保隐藏：

```swift
override func updatePracticeView() {
    // ... 现有逻辑 ...
    grammarAnnotationLegendView.reset()
    // 标注逻辑...
    grammarAnnotationLegendView.isHidden = true  // 强制隐藏
}
```

**方案 2**（更清晰，独立配置）：在 `GrammarAnnotationLegendView` 中添加配置选项：

```swift
class GrammarAnnotationLegendView: UIStackView {
    var shouldShow: Bool = true  // 新增控制开关
    
    private func updateVisibility() {
        isHidden = !shouldShow || (aspectLegendView.isHidden && nounCaseLegendView.isHidden)
    }
}
```

在 `WordsPracticeViewController` 中使用：

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    grammarAnnotationLegendView.shouldShow = false  // 禁用 legend 显示
    // ...
}
```

> **批注**：是否考虑让 Phrase Review 的某些练习类型显示 legend，而其他类型隐藏？  
> 全部隐藏



---

## 4. TextMeaningPracticeView

### 4.1 显示翻译后自动滚动到底部

**原因**：`displayLower()` 在显示翻译后调用 `updateChatBubblesPosition()`，而该方法无条件将 contentOffset 设置到底部（约 935–942 行）。

**修复**：从 `displayLower()` 中移除对 `updateChatBubblesPosition()` 的调用，只在 `chatDidReceiveChunk()` 等实际新增气泡的回调中触发滚动。

> **批注**：同意

---

### 4.2 双击选中单词有时不显示在输入框

**原因**：`textViewDidChangeSelection()`（约 627–649 行）处理 unselectableRanges 时计算 `newLength = abs(r.length - newLocation)`，当选中范围与图标重叠时该值可能为 0，导致 selectedRange 被清空，输入框得不到文本。

**修复**：计算 newLength 后加有效性检查，并用调整后的最终 range 填充输入框：

```swift
if newLength > 0 {
    textView.selectedRange = NSRange(location: newLocation, length: newLength)
}
let finalRange = textView.selectedRange
if finalRange.length > 0, let selected = ... {
    chatTextField.text = "\"\(selected)\""
}
```

> **批注**：同意

---

### 4.3 点击空白处清空输入框文本

**原因**：`backgroundTapped()`（约 854–858 行）调用了 `selectionDidClear()`，后者将以引号开头的输入框文本清空。

**修复**：从 `backgroundTapped()` 中移除对 `selectionDidClear()` 的调用：

```swift
@objc private func backgroundTapped() {
    chatTextField.resignFirstResponder()
    textView.resignFirstResponder()
    textView.selectedRange = NSRange(location: 0, length: 0)
}
```

> **批注**：同意

---

### 4.4 loading 按钮被 legend 遮挡

**原因**：legendView 在 contentGenerationSpinner 之后加入 mainView（约 322–323 行），z-order 更高，遮挡 spinner。

**修复**：调整 `contentGenerationSpinner` 的垂直约束，使其位于 legendView 上方，不隐藏 legend：

```swift
// updateLayouts() 中
contentGenerationSpinner.snp.makeConstraints { make in
    make.centerX.equalToSuperview()
    make.centerY.equalTo(legendView.snp.top).offset(-40)
}
```

spinner 始终显示在 legend 顶部以上 40pt 处，无需在 `startedContentGeneration` / `completedContentGeneration` 中切换 legendView 的 isHidden。

> **批注**：置顶也会 overlap 吧？需要处理 offset
> **回应**：把 spinner 调高，不要隐藏 legend 显示 spinner。

---

## 5. 其他

### 5.1 LLM timeout 改为 30s

**原因**：`Constants.swift` 第 26 行 `requestTimeLimit = TimeInterval.second * 10`，`ContentCreator.swift` 所有 URLRequest 均使用此常量，超时仅 10 秒。

**修复**：

```swift
// Constants.swift
static let llmRequestTimeLimit: TimeInterval = TimeInterval.second * 30

// ContentCreator.swift init 默认参数
requestTimeLimit: TimeInterval = Constants.llmRequestTimeLimit
```

> **批注**：同意

---

### 5.2 段落翻译未缓存到磁盘

**原因**：`TextMeaningPracticeProducer.swift`，`updateMeaningsAndExistingPhrasesAndAccentLocs()` 翻译完后只更新 practice 对象的 `meaning` 字段，不写回 `Article.paras[].meaning`，下次进入练习重新翻译。

**修复**（分三步）：

1. **扩展 `Paragraph` 结构**（`Article.swift`）：

```swift
struct Paragraph: Codable {
    var id: String
    var text: String
    var meaning: String?  // 完整段落翻译
    var segmentedMeanings: [Int: String]?  // 新增：按 sentenceId 缓存句子翻译
    // ... 其他字段
}
```

2. **读取缓存**：在 `updateMeaningsAndExistingPhrasesAndAccentLocs()` 过滤阶段（约第 382 行）：

```swift
let needsTranslation = practices.filter { practice in
    guard practice.meaning.isEmpty else { return false }
    
    // 尝试从缓存读取
    if case let .article(articleId, paragraphId, sentenceId) = practice.textSource,
       let para = articles.first(where: { $0.id == articleId })?.paras.first(where: { $0.id == paragraphId }) {
        if let sentenceId = sentenceId, let cached = para.segmentedMeanings?[sentenceId] {
            practice.meaning = cached  // 缓存命中
            return false
        } else if sentenceId == nil, let cached = para.meaning {
            practice.meaning = cached
            return false
        }
    }
    return true  // 需要翻译
}
```

3. **写回缓存**：在 `maybeTranslate()` 回调中：

```swift
self.maybeTranslate(text: practice.text) { translation, _ in
    practice.meaning = translation
    
    if case let .article(articleId, paragraphId, sentenceId) = practice.textSource,
       let aIdx = self.articles.firstIndex(where: { $0.id == articleId }),
       let pIdx = self.articles[aIdx].paras.firstIndex(where: { $0.id == paragraphId }) {
        if let sentenceId = sentenceId {
            if self.articles[aIdx].paras[pIdx].segmentedMeanings == nil {
                self.articles[aIdx].paras[pIdx].segmentedMeanings = [:]
            }
            self.articles[aIdx].paras[pIdx].segmentedMeanings?[sentenceId] = translation
        } else {
            self.articles[aIdx].paras[pIdx].meaning = translation
        }
    }
    translateNext(index + 1)
}

// 全部翻译完成后
var articles = self.articles
Article.save(&articles, for: LangCode.currentLanguage)
```

> **批注**：但是一般来说翻译的是段落的一部分内容，怎么处理段落一部分内容的翻译和段落的关系？
> **回应**：确认问题成立。textSource 携带 `(articleId, paragraphId, sentenceId?)`，同一段落可能有多个 practice 对应不同 sentenceId（即不同句子）。`paragraph.meaning` 只有一个 String 字段，不能存多句翻译。**修复方案**：在 `Paragraph` 结构中新增 `segmentedMeanings: [Int: String]?` 字段，key 为 sentenceId：
> - sentenceId 为 nil（整段练习）→ 存入 `paragraph.meaning`
> - sentenceId 有值（单句练习）→ 存入 `paragraph.segmentedMeanings[sentenceId]`
>
> 读取时先查 segmentedMeanings，没有再查 meaning。
> **批注**：那什么时候会读取？
> **回应**：读取时机在 `updateMeaningsAndExistingPhrasesAndAccentLocs()` 的过滤阶段（`TextMeaningPracticeProducer.swift` 约第 382 行）。该方法已有 `practice.meaning.isEmpty` 的判断来决定是否需要翻译。改动后在此处加一步：先用 `practice.textSource` 的 `sentenceId` 查 `paragraph.segmentedMeanings[sentenceId]`，命中则直接赋值 `practice.meaning = cached`，跳过翻译请求；未命中再走原有的 `maybeTranslate()` 流程并在回调中写回缓存。整条链路：进入练习 → `updateMeanings…()` 过滤需翻译的 practices → 缓存命中则直接赋值，不发网络请求。

---

### 5.3 阅读/说话练习进度回退

**现象**：进度在 6，点击 next 后变成 5。文本显示为黑色（注解未完成）时点击 next 后更容易出现。

**原因**：`ReadingPracticeProducer.swift`，`cacheCurrentProgress()`（约 273–289 行）根据 `practiceList.first` 计算当前段落 index。后台异步的 `updateMeaningsAndExistingPhrasesAndAccentLocs()` 完成时可能再次触发 `cacheCurrentProgress()`，此时 `practiceList.first` 指向的段落 index 可能小于已保存的值，导致进度倒退。

**修复**：在 `cacheCurrentProgress()` 中记录已保存的最大 index，确保只增不减。同样修复应用到 `SpeakingPracticeProducer`：

```swift
private var lastSavedParagraphIndex: Int = 0

func cacheCurrentProgress() {
    guard let article = selectedArticle else { return }
    let paraIndex: Int
    if let practice = practiceList.first as? ReadingPractice,
       case let .article(_, paragraphId, _) = practice.textSource,
       let paragraphId = paragraphId,
       let idx = article.paras.firstIndex(where: { $0.id == paragraphId }) {
        paraIndex = max(idx, lastSavedParagraphIndex)
        cancelledDuringLoading = false
    } else if practiceList.isEmpty {
        cancelledDuringLoading = true
        paraIndex = pendingStartParaIndex
    } else {
        paraIndex = currentSelectedParaIndex
    }
    lastSavedParagraphIndex = paraIndex
    cache(paragraphIndex: paraIndex, articleId: article.id)
}
```

> **批注**：同意

### 5.4 Article edit VC 中 source 字段改为 URL 样式（带颜色 + 标题显示）

**现象**：Article 编辑界面中 source 字段目前是普通文本输入框（UITextView），用户无法直观看出这是一个 URL，也无法点击跳转。

**原因（调查结果）**：

1. **source 字段 UI 实现**：`ReadingEditViewController.swift` 第 17 行 source 对应 `sourceIdentifier = 2`，使用 `ReadingEditTableCell` 中的 `ReadingEditTableCellTextView`（继承自 `AutoResizingTextViewWithPrompt`），本质是编辑用的 `UITextView`。
2. **source 数据格式**：`Article.swift` 第 65 行定义 `var source: String?`，存储纯 URL 字符串。初始化时调用 `.strip()` 规范化（第 76 行、89 行、108 行、130 行）。
3. **内置浏览器现有使用**：`SafariServices` 框架已被项目引入，`TextMeaningPracticeViewController.swift` 第 275 行有现成示例：
   ```swift
   let url = URL(string: urlString)
   guard let url = url else { return }
   let vc = SFSafariViewController(url: url)
   present(vc, animated: true, completion: nil)
   ```

**修复方向**：

1. **UI 改造**：source 字段行为二选一——
   - **方案 A（推荐）**：保留编辑用的 UITextView，但在其上层添加一个只读的、经过样式处理的 URL 按钮/标签视图。编辑时显示 UITextView，查看时显示 URL 按钮。
   - **方案 B**：完全替换为自定义 UIControl（仿 UIButton 样式），按下时进入文本编辑模式，失焦后恢复显示样式，点击时跳转。

2. **样式处理**：
   - 颜色：用 `Colors.activeSystemButtonColor` 或蓝色主题色标记 URL
   - 字体：比普通字体略小，以区分 title/topic
   - 排版：截断长 URL（显示 "https://example.com" 而非完整 URL）

3. **交互逻辑**：
   - 编辑时 (`textViewDidBeginEditing`)：隐藏 URL 按钮，显示 UITextView
   - 失焦时 (`textViewDidEndEditing`)：隐藏 UITextView，显示格式化的 URL 按钮，调用 `maybeGenerateBodyText()` 检测 YouTube 视频
   - 点击 URL 按钮：用 `SFSafariViewController` 跳转，改动点在 `ReadingEditViewController` 中添加：
     ```swift
     @objc private func sourceURLTapped() {
         guard let urlString = cells[Self.sourceIdentifier].textView.text,
               !urlString.isEmpty,
               let url = URL(string: urlString) else {
             return
         }
         let vc = SFSafariViewController(url: url)
         present(vc, animated: true, completion: nil)
     }
     ```

4. **实现文件清单**：
   - `ReadingEditTableCell.swift`：添加只读 URL 按钮视图和切换逻辑
   - `ReadingEditViewController.swift`：delegate 回调中处理按钮点击，跳转至 SFSafariViewController
   - `Article.swift`：无需改动（source 已是 String?）

**批注栏**：
> 是否需要 URL 有效性校验（在显示前检查 URL(string:) 是否非 nil）？需要。
> 是否需要支持 WKWebView 作为 SFSafariViewController 的备选方案（特殊场景下）？不需要。

---

### 5.5 并发写入 `word2langForAccentAnalysis` 导致崩溃（EXC_BAD_ACCESS）

**现象**：App 在 `PhraseReviewWordSelectionViewController.viewDidLoad()` 触发练习生成后随机崩溃，崩溃日志 2026-08-11 18:16:18。

**Exception Type**：`EXC_BAD_ACCESS (SIGSEGV)`，子类型 `KERN_INVALID_ADDRESS at 0x0000000000000010`（即 nil + 16，典型的访问已释放对象的偏移字段）。

**崩溃线程**：Thread 8，队列 `NSManagedObjectContext 0x285cc41a0`，关键崩溃帧：

```
objc_msgSend                              ← 访问地址 0x10，已释放内存
Dictionary._Variant.setValue(_:forKey:)
Dictionary.subscript.setter
analyzeAccents(for:completion:)           ← AccentAnalyzerProtocol.swift 第 32/34 行
closure #5 in WordPracticeProducer.makeAndCachePractices(for:skipDuplicates:)
```

**原因**：`word2langForAccentAnalysis` 是定义在 `AccentAnalyzerProtocol.swift` 第 25 行的全局 `[String: LangCode]` 字典，没有任何线程保护。`makeAndCachePractices()` 对每个单词调用 `analyzeAccents(for:)`，其回调在 `NSManagedObjectContext` 私有串行队列中执行，但日志中同时存在至少四个不同的 `NSManagedObjectContext`（`0x285cc41a0`、`0x285cef4d0`、`0x285cef5a0`、`0x285cef670`）并发运行，互相之间没有同步。多个线程同时对该字典执行写入（第 32 行 `word2langForAccentAnalysis[text] = ...`）和读取（第 34 行 `word2langForAccentAnalysis[text]`），Swift `Dictionary` 不是线程安全的，并发访问触发内存损坏，最终在 `objc_msgSend` 处以 `SIGSEGV` 崩溃。代码中已有注释 `// TODO: - The following commented code leads to crash.`，说明作者早已察觉该字典存在并发问题，但仅注释掉了一处写法，未修复根本的竞态条件。

**修复**：用一个串行 dispatch queue 保护 `word2langForAccentAnalysis` 的所有读写：

```swift
// AccentAnalyzerProtocol.swift
private let word2langQueue = DispatchQueue(label: "com.polyglot.word2lang")
var word2langForAccentAnalysis: [String: LangCode] = [:]

func analyzeAccents(for text: String, completion: @escaping (
    [Token], String?, String
) -> Void) {
    word2langQueue.sync {
        word2langForAccentAnalysis[text] = LangCode.currentLanguage
    }
    LangCode.currentLanguage.accentAnalyzer?.analyze(for: text) { tokens, fixedText in
        let lang = word2langQueue.sync { word2langForAccentAnalysis[text] }
        guard LangCode.currentLanguage == lang else { return }
        completion(tokens, fixedText, text)
    }
}
```

所有对字典的读写串行化，消除竞态条件，不影响 `analyze()` 本身的异步特性。

> **批注**：同意

# 新需求

1. Phrase review

（1）练习生成过程修改如下：
目前，generateWordPractices() 和 PhraseReviewWordSelectionViewController.generatePracticesForAvailableWords() 都会调用 .makeAndCachePractices()。现在需要修改调用如下：
- text meaning practice 结束，点击 next 时：搜集需要练习的单词存进 reinforcementWords（需要写入硬盘），并给这些单词生成第一轮练习（三种类型）
- 从 phrase review list 选择单词进入练习模式，在练习过程中，后台生成当前练习中的单词的下一轮练习
- 此外，每次点开 phrase review list 时，扫描全部单词，对于每一个单词，如果其当轮练习没有全部生成，需要后台补上
- 注意：对于一个单词，如果其全部练习阶段都完成，需要从硬盘的 reinforcementWords 删除其记录
原因：现有练习生成逻辑效率低，需要优化成分批生成和后台补充
修复：修改 text meaning practice 结束时初始化生成，练习中后台生成下轮，列表打开时补齐未完成练习

（2）重音和语法标注修改如下：
- 弃用目前补标注方法，即：选中单词练习时，先练习已完成标注的练习，后台标注并替换未完成标注的练习。弃用原因：该方法不能确保练习的随机性，实际使用发现很多时候 context selection 几乎全都在另外两种类型之前
- 修改 phrase review 标注方法如下：
a. text meaning practice 练习结束，基于 reinforcementWordsInfo 搜集并存储 reinforcementWords（如上所述）。除了存储单词本身，还需要存储包含该单词的已标注语句（text meaning practice 的文本语句一般已经标注重音和语法元素了）、以及该单词的翻译。为了达到这个目的，text meaning practice 练习过程中，点击 menuitem 的 reinforce 按钮将单词放进 reinforcementWordsInfo 时，顺便（1）将包含该单词的当前句子也放进去，（2）后台调用接口得到翻译。即需要存储 [word_to_reinforce: [context_sentence, meaning]] 。这样做的话，在生成该单词的练习时，就可以直接复用有标注的文本 `context_sentence` 了。此外注意：对于 context selection 等包含大段文本的练习，单词所在的句子 `context_sentence` 有标注就可以，其他内容（如一个段落的其他句子）不用标注。通过这种方法，就可以不需要练习的过程中动态补标注了。此外，每次从 home view vc 打开 phrase review list 时，都要扫描一遍检查有没有单词的对应文本没标注，并补标注。
b. 如上所述，除了存单词对应的句子内容，加入 reinforcementWords 列表时还需要存单词的意思（翻译接口获取）。生成练习的时候，和 meaning 相关的练习就可以直接用这个单词意义，而不用再次翻译获取了。同样，每次从 home view vc 打开 phrase review 列表，都要扫描一遍检查有没有单词没翻译，并补翻译。
c. 总结：每次打开 phrase review list 需要在后台（1）补上没生成的当轮练习（2）补重音和语法标注（3）补单词意思
原因：当前动态补标注方法破坏练习随机性，导致某些练习类型总是先出现
修复：在 reinforce 单词时存储已标注句子和翻译，生成练习时直接复用，列表打开时补齐缺失标注和翻译

（3）只有到达练习时间（已实现），并且标注和翻译都完成（需实现）的单词，才可以选择练习，否则，即使到了练习时间，也不能练习，需要标注和翻译完成后再练习。
原因：缺少标注和翻译完成状态的检查，导致未准备好的单词也可以开始练习
修复：在单词可选择性判断中增加标注和翻译完成状态检查条件

（4）Phrase review 列表布局更新：
- Header 右侧显示本轮包含的三种练习类型对应的 icon（language settings 里面的练习 icon）
- 左上显示单词（和目前一致）；右上显示练习类型实际数量（如，该单词实际上已生成该轮三种类型数量是 211，则显示 211，同时，如果某练习类型已完成重音和语法标注，则对应数字加粗；左下meaning；右下日期。可练习、不可练习的单词都是这个布局，区别在于字体颜色不同
原因：当前列表布局信息不完整，缺少练习类型 icon 和标注完成状态显示
修复：在 header 添加练习类型 icon，右上显示练习数量并根据标注状态加粗数字

（5）设置成无单词可练习也可以点开列表，但是无法选择单词练习（现在是没单词可练习就点不开列表）
原因：当前逻辑在无可练习单词时直接禁用列表入口，用户无法查看列表状态
修复：将入口禁用逻辑移除，改为进入列表后禁用单词选择操作

（6）进度标签 offset 设置成 6，颜色淡一点（尽量使用 Colors extension 的颜色）。同时，顶部计时栏改成进度条，每完成一个练习增加进度。（仅限 phrase review 改成进度条，其他练习，如 text meaning practice，仍然维持 timing bar）。此外，language setting 去除 phrase review 时长设置
原因：进度标签偏移量和颜色不符合设计规范，且 timing bar 不适合展示练习完成进度
修复：调整进度标签 offset 为 6 并使用 Colors extension 颜色，phrase review 顶部改为进度条并移除时长设置

（7）不需要显示legend，目前还没修复
原因：phrase review 中仍然显示 legend 视图，与设计要求不符
修复：在 phrase review 视图中隐藏或移除 legendView

（8）重音标注使用字体加粗，和 text meaning practice view 统一。现在有些文本还是用单引号表示重音。此外，语法标注颜色有问题，颜色没覆盖全部字母，是不是和重音符号有关？（1）使用单引号表示重音的文本，颜色没覆盖全部字母（2）还发现有些文本重音已经用加粗标注，颜色还是不能覆盖所有字母，为什么？
原因：重音标注方式不统一（部分仍用单引号），且重音符号与语法颜色标注存在字符范围冲突
修复：统一将单引号重音替换为字体加粗，修复重音符号导致颜色标注范围计算偏移的问题

2. Text meaning practice view
（1）显示的翻译文本前面的翻译icon不见了
原因：upperIcon 和 lowerIcon 未正确初始化导致翻译图标未显示
修复：在 TextMeaningPracticeView.init() 中根据 textSource/.chatGpt 设置 upperIcon，根据 isTextMachineTranslated 设置 lowerIcon，同时初始化 upperString/lowerString 默认值
实现：✅ 已修复（TextMeaningPracticeView.swift init）

（2）选中文本后，点击空白，输入框文本不要清除，现在还没实现
原因：selectionDidClear 方法会清除以引号开头的 chatTextField 文本
修复：移除 selectionDidClear 中清除 chatTextField 的逻辑
实现：✅ 已修复（TextMeaningPracticeView.swift selectionDidClear）

（3）点击 menu item 翻译：翻译超时换谷歌
原因：sendChatMessageForAction 使用 LLM 翻译，无超时回退机制
修复：在 streamContent onError 中添加 Google Translate 降级逻辑

（4）有内容时 spinner 被 legend 挡住，需要上移 spinner 到 legend 上面。还没修复
原因：contentGenerationSpinner 约束相对 legendView 定位，层级被遮挡
修复：修改 spinner 约束到 chatInputBar 上方，调用 bringSubviewToFront
实现：✅ 已修复（TextMeaningPracticeView.swift updateLayouts）

（5）显示翻译后对话泡泡会有移动，这个移动能不能 animated
原因：updateChatBubblesPosition 中 setContentOffset 已使用 animated: true
修复：无需修复，已实现动画效果

（6）大模型请求失败也用泡泡显示提示消息。大模型最新对话泡泡下面加刷新按钮
原因：chatDidFail 直接删除 AI 泡泡，未显示错误信息和重试选项
修复：在 chatDidFail 中显示错误泡泡和刷新按钮，支持重试最后消息
实现：✅ 已修复（TextMeaningPracticeView.swift chatDidFail + retryLastMessage + Strings.chatErrorMessage）

（7）玩家泡泡和大模型泡泡下面加复制按钮。并且需要支持复制对话泡泡的任意内容
原因：makeBubble 未创建复制按钮，泡泡内容不可选择
修复：在每个泡泡行添加复制按钮，将 UILabel 改为 UITextView 支持选择复制
实现：✅ 已修复（TextMeaningPracticeView.swift makeBubble，UILabel → UITextView + doc.on.doc 复制按钮）

3. 其他
（1）Article edit vc 将 source 做成 url 样式（颜色+下划线），点击后用内置浏览器 navigate 到页面，类似 iOS 记事本效果
原因：source textField 未配置链接样式和点击交互
修复：source 添加 dataDetectorTypes = .link，配置 textView delegate 打开链接

（2）081118 报错报告，报错原因？

**原因（一句话）**：多个 `NSManagedObjectContext` 私有队列并发对全局无保护字典 `word2langForAccentAnalysis` 执行读写，触发 Swift Dictionary 内存损坏，以 `EXC_BAD_ACCESS (SIGSEGV)` 崩溃。

**修复（一句话）**：用串行 `word2langQueue` 将 `word2langForAccentAnalysis` 的所有读写串行化，消除竞态条件（已在 5.5 节修复）。

**崩溃日志**：`Polyglot-2026-08-11-181618.ips`，时间 2026-08-11 18:16:18 +0800，设备 iPhone XS（iPhone11,2），iOS 17.0。

**Exception Type**：`EXC_BAD_ACCESS (SIGSEGV)`，子类型 `KERN_INVALID_ADDRESS at 0x0000000000000010`（即 nil + 16，访问已释放对象的偏移字段）。

**崩溃线程**：Thread 8，队列 `NSManagedObjectContext 0x285cc41a0`，关键崩溃帧：
```
objc_msgSend                              ← 访问地址 0x10，已释放内存
Dictionary._Variant.setValue(_:forKey:)
Dictionary.subscript.setter
analyzeAccents(for:completion:)           ← AccentAnalyzerProtocol.swift
closure #5 in WordPracticeProducer.makeAndCachePractices(for:skipDuplicates:)
```

**触发路径**：`PhraseReviewWordSelectionViewController.viewDidLoad()` → `generatePracticesForAvailableWords()` → `makeAndCachePractices()` → `analyzeAccents(for:)` 回调中对 `word2langForAccentAnalysis` 字典执行并发写入。

**根本原因**：`word2langForAccentAnalysis` 是定义在 `AccentAnalyzerProtocol.swift` 第 26 行的全局 `[String: LangCode]` 字典，没有任何线程保护。日志中同时存在至少四个不同的 `NSManagedObjectContext`（`0x285cc41a0`、`0x285cef4d0`、`0x285cef5a0`、`0x285cef670`）并发运行，多个线程同时对该字典执行写入（第 34 行）和读取（第 37 行），Swift `Dictionary` 不是线程安全的，并发访问触发内存损坏，最终以 `SIGSEGV` 崩溃。

**修复状态**：已在 5.5 节修复——用串行 `word2langQueue` 保护所有读写，消除竞态条件。

（3）Global settings 删除 machine translation 字段
原因：Global settings 中保留了已废弃的 machine translation 设置项
修复：从 GlobalSettingsViewController 移除 machine translation 相关 UI 和逻辑

# 新需求 2

1. Phrase review
（1）选择列表，没 meaning 的单词不允许选择练习。只有（1）到达练习时间（2）重音标注完成（3）语法标注完成（4）有meaning 全部满足，才可以选择练习
原因：isReadyToPractice 只检查 isAvailable 和 isAnnotationReady，未检查 meaning 是否存在
修复：isReadyToPractice 增加 !meaning.isEmpty 条件
实现：✅ 已修复（PhraseReviewWordSelectionViewController.swift isReadyToPractice）
（2）Home view vc 显示满足练习条件的单词数（注意除了时间还有上述其他条件。现在显示的数量和可选择的单词的数量不一致）
原因：ebbinghausSchedule 包含 isCompleted 的条目（已完成所有复习轮次），isAvailable 只检查日期不排除已完成，Home 计数将这些也算进去
修复：先过滤掉 isCompleted 的条目，total 和 available 都只统计活跃条目
实现：✅ 已修复（HomeViewController.swift phraseReviewItems）
（3）List 标题右侧显示选择的单词数，如 (6) 这样子。选择/取消选择需要动态更新
原因：title 固定为 Strings.phraseReview，选择状态变化时不更新
修复：updateStartButton() 同时更新 title，0 个选中时显示原标题，有选中时追加 (N)
实现：✅ 已修复（PhraseReviewWordSelectionViewController.swift updateStartButton）

（4）补标注：每次点开列表只标注 10 个轮数最少的，已到达练习时间的单词
原因：每次打开列表时对所有单词补标注，无优先级，效率低
修复：backgroundRefresh() 按 periodIndex 升序遍历 active+available 单词，逐词串行检查并补充：（1）缺练习 → makeAndCachePractices；（2）缺标注 → annotateExistingPractices（用 DispatchSemaphore 等待完成后再处理下一个词）；（3）缺 meaning → translator 翻译。annotateExistingPractices 新增 completion 参数，在 analyzeAccents 回调末尾调用 completion?()
实现：✅ 已修复（WordPracticeProducer.swift annotateExistingPractices；PhraseReviewWordSelectionViewController.swift backgroundRefresh）

（5）正在补标注/meaning的单词，需要有字体颜色变化（呼吸效果，浅灰深灰切换）。此外，补标注/meaning时，meaning 字段显示正在补标注的内容，类似：正在标注重音;语法;含义（可同时显示多个标注内容）。点击标注中的单词的cell时，meaning 字段内容在标注说明和meaning（如已有）间切换。默认显示标注说明
原因：补标注/meaning 期间 cell 无状态反馈，用户无法知道后台进度
修复：WordSelectionEntry 添加 annotatingItems: [String] 字段；annotateExistingPractices/meaning 翻译前后分别 post wordAnnotationStatusChanged 通知（annotatingItems 非空=进行中，空=完成）；VC 监听通知更新 entry 并 reloadRows；cellForRowAt 当 annotatingItems 非空且未切换时显示状态文本（如"Annotating accents; grammar"）；didSelectRowAt tap 时切换 meaningDisplayKeys；不使用呼吸动画
实现：✅ 已修复（PhraseReviewWordSelectionViewController.swift；Strings.swift annotatingAccent/annotatingGrammar/annotatingMeaning）
（6）目前显示标注完成（数字加粗）的练习，有些还是没重音，比如说 prompt 或者 context 没重音。
原因：isAccentAnnotationCompleted 标记"已尝试标注"而非"标注实际生效"；addAccents 使用 replacingOccurrences 精确子串匹配，当 query/context 里词形与原词不一致（变格、变位）时替换静默失败，但 flag 仍置 true
修复：（暂不修复，待评估）

（7）Reordering 的练习，需要练习的单词会有表示重音的单引号（但应该用加粗标注）
原因：addAccents 将 practice.key 替换为带 ' 的 accentedWord 后，reorderingWordList 从 practice.key.split 生成，split 出的每个词保留了 accentSymbol
修复：split 后 map 去掉每个词里的 Token.accentSymbol
实现：✅ 已修复（WordPracticeProducer.swift addAccents）
（8）目前发现选择单词练习完之后，这些单词会有一个副本出现在第一轮，而且在重音处被切分，变成两个部份，如 за пуске。而实际的单词在下一轮的列表能看见。也就是说练习完的单词在列表出现了两次，一个是正常的已经进入下一轮的单词，一个是异常副本
原因：addAccents 修改了 practice.word 为带重音+空格的形式（如 "за' пуске"），normalizedKey 后变成 "за пуске"，写入 schedule 成为新 key，loadEntries 从 cachedEntries 和 schedule 合并 allKeys 导致副本显示
修复：addAccents 不再修改 practice.word；loadEntries 只用 schedule.keys 作为 allKeys；开头清除 schedule 里含空格的旧 key

（9）列表的每一轮，先显示可练习的单词，再选择还不能练习的单词。可练习的单词/不能练习的单词不要用字典序，使用创建该练习单词的时间
原因：loadEntries 当前对每轮的单词没有排序，显示顺序不确定
修复：在 loadEntries 构建 allEntries 后，每个 section 内按 isReadyToPractice 降序、再按练习创建时间升序排序

（10）默认选择的单词数量支持在 lang settings 设置，默认 5
原因：defaultSelectionCount 硬编码为 6，无法在 lang settings 配置
修复：在 LangCode configs 添加 phraseReviewDefaultSelectionCount 字段默认值 5，lang settings 添加对应设置项，PhraseReviewWordSelectionViewController 读取该值

（11）重音标注有错误：有些练习在 meaning 标了重音，如俄语 meaning selection 把选项的英语文本（meaning）标注了重音
原因：addAccents 对 meaningSelection 练习替换 choices 时，英语 meaning 文本中恰好包含与俄语单词相同的子串，被错误替换加上重音符号
修复：addAccents 对 choices 的替换加语言检查，只替换与当前语言匹配的选项，跳过 meaning 方向的选项

（12）进度条右侧，目前是空白，改成：显示进度标签（即将目前的进度标签放到右上角）
原因：删除 toggleButton 后进度条右侧空白，progressLabel 目前显示在 promptLabel 旁边
修复：将 progressLabel 移到导航栏右侧，作为 navigationItem.rightBarButtonItem 的自定义 view
实现：✅ 已修复（WordsPracticeViewController.swift updateViews）

（13）选择词语练习点 Start 闪退
原因：updateViews() 中 phrase review 分支调用 progressLabel.removeFromSuperview()，之后 super.updateLayouts() 仍对其激活 SnapKit 约束，两个 anchor 没有共同祖先触发 NSGenericException
修复：PracticeViewController.updateLayouts() 中对 progressLabel 设约束前加 superview != nil 保护，phrase review 模式下跳过该约束
实现：✅ 已修复（PracticeViewController.swift updateLayouts）

2. Text meaning practice view
（1）Spinner 被挡住，我感觉是你 layout constraint 设置有问题。你试试 spinner.top = 生成完毕后将显示的对话泡泡.top, spinner.leading = 生成完毕后将显示的对话泡泡.leading
原因：spinner 约束固定在 chatInputBar 上方，与 chatBubblesStack 位置无关，legend 可能遮挡
修复：将 spinner 约束改为 top/leading 对齐 chatBubblesStack，使其出现在 AI 泡泡将显示的位置

（2）对话泡泡下面的复制和刷新的按钮再小一点
原因：按钮尺寸偏大，视觉上占据过多空间
修复：复制按钮改为 24×20，刷新按钮改为 18×18

（3）点击对话泡泡下面的复制按钮，不需要全选文本。但是，需要有反馈看出来已复制
原因：复制动作调用 selectAll 会高亮文本，且无复制成功的视觉反馈
修复：移除 selectAll，复制后将图标切换为 checkmark 持续 1.5s 再还原

# 新需求 3

1. Phrase review
（1）列表 cell：长单词导致 cell 右上角单词类型/数量显示不完整
原因：WordSelectionCell（PhraseReviewWordSelectionViewController.swift 内联类）里 wordLabel 和 countsLabel 水平压缩阻力优先级都是默认的 750，两者相同；两者之间只有一条 required 的 wordLabel.trailing == countsLabel.leading - 8 约束，countsLabel 没有独立 leading 约束，只有"最多不超过 35% 宽度"的上限约束，没有下限保护。单词很长时 wordLabel 挤占空间，countsLabel 被压缩到低于文字所需宽度，加上默认 numberOfLines=1 + .byTruncatingTail 就被截断。同 cell 下面一行 meaningLabel/dateLabel 已经用了"左边 .defaultLow、右边 .required"的正确模式，只是没有同步套用到这一行。
修复：给 wordLabel 设置 .defaultLow 水平压缩阻力，countsLabel 设置 .required 压缩阻力 + hugging 优先级。

（2）不可练习的单词也需要支持删除
原因：两层拦截叠加。trailingSwipeActionsConfigurationForRowAt 里 guard entry.isAvailable else { return nil }，把"是否到复习时间"当成能否滑出删除按钮的前提，冷却期内直接不显示任何滑动菜单；cellForRowAt 里 cell.isUserInteractionEnabled = entry.isReadyToPractice，未就绪时整个 cell 手势响应链被禁用，即使放开第一层，滑动手势也会被吞掉。
修复：删除操作的可用性要和"是否可练习"解耦——去掉 swipe action 里的 isAvailable 判断，isUserInteractionEnabled 的禁用范围收窄为只影响点击进入练习的 tap 逻辑（比如挪到 didSelectRowAt 里判断），不要连累滑动删除手势。

（3）俄语 meaning selection：prompt 是俄语词，selection stack 是英语词（meaning），英语 meaning 的字母被重音标注加粗了
原因：生成端（WordPracticeProducer.swift 的 addAccents）本身是对的，已经用 choicesAreTargetLanguage 判断只给俄语/日语目标语言词加重音符号，不会碰英语 meaning。真正的 bug 在渲染端：GrammarAnnotationLegendView.swift 的 applyAccentBold 无差别扫描任意字符串里的 '（Token.accentSymbol 就是普通单引号字符），发现就删掉并给前一个字母加粗，不判断语言或文本来源。英语 meaning 里天然存在的 '（如 don't、cat's）被当成重音符号误处理，ThreeButtonSelectionStack.swift 对每个选项文案都无条件调用了这个方法。
修复：不能靠"文本里有没有 '"判断是否加重音，需要在调用 applyAccentBold 时按语言/文本来源做门槛（只对目标语言原词调用，不对 meaning/英语文本调用），或者给真正的重音标记换一个不会跟自然文本冲突的符号（如非打印 Unicode 占位符）。

（4）列表，有单词但没有可练习单词：能点击进入；无单词：不可点击且 inactive 颜色
原因：HomeViewController.swift 里 isWordPracticeEnabled 用的是 ebbinghausSchedule.values.contains { isAvailable }，即"是否存在至少一条已到复习时间的记录"，粒度用错了——对应的是"有没有可练习单词"，而需求要的是"有没有单词"。且 createListCellRegistration 里根本没有对 phraseReviewSection 计算 isEnabled，导致这个入口 cell 永远显示可用色，从不置灰。
修复：跳转前的判断改成 !ebbinghausSchedule.isEmpty（有单词就能点，不管是否可练习），并在 createListCellRegistration 里给 phraseReviewSection 补上 isEnabled = !ebbinghausSchedule.isEmpty 的置灰逻辑。

（5）Cell 右上角显示 "000"（该词当轮所有练习类型均未生成任何练习）时，不允许选择该词进入练习
原因：PhraseReviewWordSelectionViewController.swift 第 161 行 isReadyToPractice 只检查 isAvailable && isAnnotationReady && !meaning.isEmpty，未检查 practiceCounts 是否全为 0。isAnnotationReady 的计算（loadEntries() 第 298 行）把"某类型 matching 为空"直接视为"该类型已标注"（matching.isEmpty || matching.allSatisfy { ... }），本意是"空类型不该拦住可选性"，但副作用是全部类型都是 0 条练习时 isAnnotationReady 恒为 true，导致显示 000 的 cell 仍满足 isReadyToPractice。
修复：isReadyToPractice 增加条件，要求 practiceCounts 至少有一项 > 0，即 practiceCounts.contains(where: { $0 > 0 })，全 0 时视为未就绪，不可选择。

2. Speaking practice（选择文章进入）
（1）底部没进度，应该和 reading practice 一样有进度
原因：进度标签约束只在 PracticeViewController.updateLayouts() 里添加，但 TextMeaningPracticeViewController.updateLayouts() 完全重写且没有调用 super.updateLayouts()，导致基类给共享 progressLabel 加约束的代码永远不会执行。Reading 之所以能显示，是因为它绕开了共享 progressLabel，自己定义了独立的 paragraphProgressLabel 并在子类里补了约束；Speaking（实际类名 TranslationPracticeViewController）虽然设置了 progressLabel.text/isHidden，却从没补约束，frame 始终为 .zero 不可见。此问题只在文章模式（selectedArticle != nil）下会被用户感知，因为非文章模式下该 label 本就 isHidden = true。
修复：在 TranslationPracticeViewController.updateLayouts() 里参照 ReadingPracticeViewController 的做法，显式给 progressLabel 补上 SnapKit 约束。

（2）对于 speaking，可以点击翻译按钮更换翻译语言的应该是译文，不是原文
原因：TextMeaningPracticeView 父类默认语义是 upperString = 原文, lowerString = 译文，并在 isTextMachineTranslated 时把 lowerIcon = translatorIcon（对应译文行）。SpeakingPracticeView.swift 里 TranslationPracticeView.init 把 upper/lower 对调为 upperString = 译文, lowerString = 原文，同时新增 upperIcon = translatorIcon，但没有清空父类已经设置好的 lowerIcon = translatorIcon。结果 upperIcon 和 lowerIcon 同时等于 translatorIcon；提交后 displayLower() 命中 lowerIcon == translatorIcon 分支，把翻译追踪区间从"译文（upper）"覆盖成了"原文（lower）"。此 bug 不限文章模式，只要该句译文来自机器翻译（isTextMachineTranslated == true）且非 ChatGPT 来源就会触发。
修复：在 SpeakingPracticeView.swift 对调 upper/lower 语义后，显式把 lowerIcon 重置为 nil，只保留新设的 upperIcon = translatorIcon。

（3）点击 next 之后会很卡，无法显示下一句的练习（reading practice 不会）
原因：SpeakingPracticeProducer.next() 在文章模式下，practiceList 为空时会在按钮点击所在的主线程同步调用 make()。make() 的文章分支只为第一段生成 1 条 practice（firstPractice），用 Thread.sleep(0.05) 忙等翻译网络请求，还有 accentSemaphore.wait(timeout: 10s)；其余段落靠后台任务异步补，每段也只产 1 条。由于 speaking 每段仅产出 1 条练习，后台补充节奏经常跟不上用户点击 next 的速度，practiceList 容易被耗尽,从而频繁命中同步阻塞路径。Reading 的 make() 结构类似（同样是"list 空则同步 make()"），但每次为整个段落的所有句子一次性生成 practice（远多于 1 条），practiceList 消耗更慢，很少触发同步兜底路径，所以感觉不卡。
修复：让 speaking 也像 reading 一样一次性把整段的所有句子都转成 practice（配合下面第 4 点的修复），减少同步兜底触发频率；同时在 next() 检测到 practiceList 即将耗尽 / 已耗尽时，参考 ReadingPracticeViewController.updatePracticeView() 的模式用 loading indicator + DispatchQueue.global 包裹加载，避免在按钮回调线程里同步阻塞。

（4）文本加载，需要确认是否按顺序一段一段，一句一句加载？感觉现在会跳过一些句子
原因：SpeakingPracticeProducer.makePractice(fromArticle:atParaIndex:) 是文章模式下生成练习的唯一入口，但只取 sentences.first ?? para.text，其余句子被完全丢弃；make() 里段落推进机制是"访问一次这个段落就推进到下一段"，不管这段有几句。对比 ReadingPracticeProducer.make() 用 for (sentenceId, sentence) in sentences.enumerated() 遍历段落内全部句子，句子用完才换下一段。也就是说 speaking 不是过滤或 off-by-one，而是在段落粒度上直接丢弃了除首句外的所有句子。
修复：把 makePractice(fromArticle:atParaIndex:) 改成和 ReadingPracticeProducer 一致的逐句遍历 + 句内计数（记录 sentenceIndex，句子用完才推进 paraIndex），而不是每段只固定取第一句。

# 新需求 4

1. Phrase review 标注复用方案（细化并取代 新需求1(2) 的实现方式）

现象：单词进入 phrase review 后频繁触发后台标注（analyzeAccents），按设计本应在 reinforce 时存好标注，生成练习时直接复用。

原因：`ReinforcementWordEntry`（ReinforcementWords.swift 12-18 行）目前只存 `contextSentence: String` 纯文本，没存任何标注结果（Token 数组）。`WordPracticeProducer.makeAndCachePractices`/`annotateExistingPractices`（WordPracticeProducer.swift 355-424、429-514 行）不管 context 来源如何，都无条件对 `practice.context` 重新调用 `analyzeAccents`，导致"存了句子=省了重新标注"的设计意图完全没有落地。

修复方向（存 tokens，不存算好的 annotation 数组）：

- `Token`（Models/Word.swift）已是 Codable，且 `calculateVerbAspectAnnotations`/`calculateNounCaseAnnotations`/`calculateShortAdjectiveAnnotations`/`calculateAccentLocs`（AccentAnalyzerProtocol.swift）都是纯函数：`(text, tokens) -> annotations`，不碰 CoreData。存 `(contextSentence, contextTokens)` 这一对，比存"某几种已算好的 annotation 数组"更根本——以后任何练习类型需要什么标注维度，都能从同一份 `(text, tokens)` 现算，不用重新走 analyzeAccents，也不用为每种练习额外多存一份数据。
- `ReinforcementWordEntry` 新增字段 `contextTokens: [Token] = []`（Codable，`init(from decoder:)` 里用 `do { ... } catch { contextTokens = [] }` 兼容旧 JSON，参照 WordPractice.swift 176-190 行的模式）。

**数据流三个阶段：**

a. **reinforce 点击时**（WordMarkingTextView.swift 720-756 行 `reinforceMenuItemTapped()`）：只做"抄现有数据"，不触发任何新标注调用。检查该单词所在的 practice（如 ReadingPractice）此刻的 `verbAspectAnnotations`/`textAccentLocs` 等是否已算好（即该段落标注是否已完成）。已完成 → 需要能拿到对应的 tokens（当前 TextMeaningPractice 只存了算好的 annotation 数组，没存 tokens 本身，需要给 TextMeaningPractice 也补一个 `tokens: [Token]` 字段，在 TextMeaningPracticeProducer.calculateAccentLocsForText 里一并存下），裁出 contextSentence 范围内的 tokens 存入 WordInfo/ReinforcementWordEntry。未完成 → contextTokens 留空，不等待、不补标注，直接存空。

b. **打开 phrase review 列表时**（PhraseReviewWordSelectionViewController.backgroundRefresh()，404-498 行）：这是唯一允许触发"补标注"的地方。在现有"(2) 补充缺失标注"步骤基础上扩展：扫描 reinforcementStore，对 `contextTokens` 为空的词，调一次 `analyzeAccents(for: contextSentence)`，写回 `ReinforcementWordEntry.contextTokens`。

c. **生成练习时**（WordPracticeProducer.makeContextSelectionPractice / makeAndCachePractices / annotateExistingPractices）：`contextTokens` 非空 → 直接 `calculateVerbAspectAnnotations(for: contextSentence, with: contextTokens)` 等现算所需字段，赋值给 `practice.contextVerbAspectAnnotations` 等，`isGrammarAnnotationCompleted`/`isAccentAnnotationCompleted` 直接置 true，不调用 analyzeAccents。仍为空（backgroundRefresh 还没跑到）→ fallback 到现有的临时 analyzeAccents 逻辑，保正确性。meaningSelection 等只需要"单词本身"标注的练习，从 contextTokens 里按 word 匹配对应 token 现算即可，同样不用重新分析。

**已知需要处理的细节**（实施时展开，非阻塞）：
- 遮空替换：`makeContextSelectionPractice` 会把 context 里的目标词替换成 `Strings.underscoreToken`（6 字符占位符），现算的 annotation position 需要按替换前后长度差做偏移修正。
- contextSentence 在整段 practice.text 中的 offset 定位：裁剪 tokens 时用 `practice.text.range(of: contextSentence)` 找起始位置，减去 offset 得到相对 contextSentence 自身的 position。

**验证计划**：利用现有日志 `[makeAndCachePractices]`（WordPracticeProducer.swift 291 行）、`[backgroundRefresh]`（PhraseReviewWordSelectionViewController.swift 439/452/475 行），reinforce 几个单词后打开 phrase review 列表，确认 `annotateExistingPractices` 只在 contextTokens 缺失的词上触发一次，生成练习阶段不再对已有 contextTokens 的词调用 analyzeAccents。

# 新需求 5

1. "двигаться дальше" 标注颜色错位（掐头且多咬一口）

**现象**：短语中"двигаться"的 aspect 颜色只覆盖"вигаться д"（丢了首字母"д"，且多咬了下一个词"дальше"的首字母）。

**原因**：`WordPracticeProducer.swift` `shiftForAccentInsertions()` 中，重音插入点落在 annotation 区间**内部**（`loc < position + length`）时，错误地同时执行了 `shift += 1` 和 `length += 1`。内部命中本应只让区间变宽（`length += 1`），不该移动起点；但多余的 `shift += 1` 把 `position` 也错误右移了一位，导致整个高亮窗口整体右移，掐掉开头一个字符，同时在末尾多纳入一个不属于该词的字符。

**修复**：删掉内部命中分支里多余的 `shift += 1`，只保留 `length += 1`。

实现：✅ 已修复（WordPracticeProducer.swift `shiftForAccentInsertions`）

---

2. GPT 翻译带说明文字，`<output>`/`</output>` 方案未生效

**原因**：`GPTTranslator.swift` 的 prompt 示例（Format 说明 + 两条 Examples）从未展示过闭合标签 `</output>` 该怎么写，模型学的是"单行、不闭合"格式。当模型想附加说明时，因为没有闭合边界，说明文字会跟在 `<output>` 后面（通常另起一行），而解析代码找不到 `</output>` 时会退化为"从 `<output>` 到字符串末尾"，把说明也纳入了。

**修复**：把 prompt 格式从 `<input>`/`<output>` 标签风格改为纯文本 `input:`/`output:` 风格（systemPrompt/userPrompt 统一格式），解析逻辑改为提取 `output:` 之后的内容，再按换行取第一行作为兜底（应对模型仍在翻译后附加说明的情况）。

实现：✅ 已修复（GPTTranslator.swift systemPrompt/userPrompt/translate）

---

3. TextMeaningPracticeView 双击选中会覆盖用户手动输入的内容

**原因**：`textViewDidChangeSelection()` 双击选中文本后无条件把结果写入 `chatTextField.text`，没有区分"文本是选中填入的"还是"用户手动输入的"，导致用户手动编辑后再双击别处文字，输入框内容被意外覆盖。

**修复**：新增 `textFieldValueSetBySelection: String?` 属性记录上次由选中逻辑写入的值。双击填入前先判断当前文本是否为空或等于该值，只有满足才允许覆盖并更新该属性；`chatTextFieldChanged()`（绑定 `.editingChanged`）检测到文本不等于该值时清空它（代表用户手动改过）；`chatSendButtonTapped()`、`chatDidSendMessage()` 两处清空 `chatTextField.text` 时同步清空该属性。

实现：✅ 已修复（TextMeaningPracticeView.swift textViewDidChangeSelection/chatTextFieldChanged/chatSendButtonTapped/chatDidSendMessage）

---

4. Reordering 拼词练习中，含逗号短语丢失逗号

**现象**："правда в том, что" 这类含逗号短语，reordering 练习的 key 和用户能拖拽拼出的答案都不含逗号，导致永远无法拼出正确答案。

**原因（两处叠加）**：
- `Text.swift` `syllabifyPhrase()` 用 `CharacterSet(charactersIn: " -,")` 做分隔符，逗号被直接当分隔符丢弃，而不是保留为独立 token。下游 `joinTokensPreservingPunctuation()` 的"跳过标点前分隔符"逻辑因为逗号已经不存在而完全无效。
- `ReorderingPracticeView.swift` 的 `answer` 计算属性用普通 `joined(separator:)` 拼接用户拖拽结果，没有用 `joinTokensPreservingPunctuation`，即使 token 里有逗号也会在逗号前插入多余空格。

**修复**：
- `syllabifyPhrase()` 改为先按空格/连字符分割，再对每个分割结果内部按逗号切分，把逗号保留为独立 token（例如"том,"→"том"、","两个 token）。
- `ReorderingPracticeView.answer` 改用 `WordPracticeProducer.joinTokensPreservingPunctuation` 拼接，和 key 的生成方式保持一致。

实现：✅ 已修复（Text.swift syllabifyPhrase；ReorderingPracticeView.swift answer）

# 新需求 6

1. 当轮练习数量被"补"回去（消耗后又被重新生成）

**现象**：某单词当轮某类型练习已生成够目标数量（如 2 条，显示 "222"），练习消耗掉一条后剩 1 条（显示变成 "122"），但下次进列表/后台补齐时，又被重新生成回 2 条（变回 "222"）。

**原因**：目前"是否需要补生成"完全靠**实时计数比较**，没有任何"本轮该类型已生成完毕"的持久化标记：

- `WordPracticeProducer.swift`（`makeAndCachePractices` 内 `neededCount(for:)`，约 286–292 行）：`needed = max(0, nRepetitions - existing)`，`existing` 是磁盘上现存的该 (word, periodIndex, type) 记录数。
- `PhraseReviewWordSelectionViewController.swift`（`backgroundRefresh()`，约 435–447 行）：`missingTypes = typesForPeriod.filter { existing count < repetitions }`，同样只看实时计数。
- 单条练习被正确完成后（`WordPracticeProducer.next()`，约 44–59 行），只从内存 `practiceList` 移除，并不会立刻从磁盘 `cachedWordPractices.<lang>.json` 里删除该条；真正的磁盘同步发生在整批 `cache()`/`save()` 重写时（如 `stopPracticing()` 调 `cache()`）,重写后磁盘计数才会跟着掉到 1。掉到 1 之后，`existing(1) < nRepetitions(2)` 为真，两处补齐逻辑都会误判为"这轮还没生成够"，把消耗掉的那条重新补出来。
- 全字段搜索确认：`WordReviewEntry`（`EbbinghausSchedule.swift` 11–15 行：`wordKey`/`periodIndex`/`nextReviewDate`）、`ReinforcementWordEntry`（`ReinforcementWords.swift` 12–18 行）、`WordSelectionEntry`（view 层，非持久化）均没有任何"某类型本轮已生成完毕"的字段。

**修复方向**：

在 `WordReviewEntry`（`EbbinghausSchedule.swift`）新增持久化字段，按当前 `periodIndex` 记录"哪些练习类型本轮已经生成够目标数量"：

```swift
struct WordReviewEntry: Codable {
    var wordKey: String
    var periodIndex: Int
    var nextReviewDate: Date
    var completedGenerationTypes: [String] = []  // 新增：本轮已生成够数量的 practiceType.rawValue 集合
}
```

（`init(from decoder:)` 用 try? / do-catch 兼容旧 JSON，默认空数组。）

- **写入时机**：`WordPracticeProducer.makeAndCachePractices()` 生成完某个 type 后，若 `existing + 本次新生成数量 >= nRepetitions`，将该 type 的 rawValue 加入对应 `WordReviewEntry.completedGenerationTypes`，通过 `EbbinghausSchedule.update(for:)` 持久化。
- **读取/拦截时机**：
  - `neededCount(for:)`：若该 type 已在 `completedGenerationTypes` 中，直接返回 0（不管磁盘现存数量是多少，不再补）。
  - `backgroundRefresh()` 的 `missingTypes` 过滤：同样先排除已标记 completed 的 type，只对未标记的 type 按现有计数判断是否需要补。
- **清除时机**：`advanceEbbinghausSchedule()`（`WordPracticeProducer.swift` 约 213–224 行）里 `periodIndex` 推进到下一轮时，同步把该 entry 的 `completedGenerationTypes` 清空（新一轮重新开始生成、重新允许标记完成）。

**处理已有练习（迁移/兼容）**：上线时磁盘上可能已经存在部分已生成够数量、甚至已被消耗过的练习记录，而 `completedGenerationTypes` 字段全部是空的（因为是新加的字段，旧 JSON 解出来默认空数组）。若不处理，第一次触发 `neededCount`/`backgroundRefresh` 检查时会把这些"看起来缺一条"的 type 当成真缺口再补一次，等于旧数据引发一次性的误补，之后才会稳定。

修复：在 `EbbinghausSchedule` 加载完成的入口（`load(for:)` 或首次调用 `update(for:)` 之前）跑一次一次性迁移：对每个 `WordReviewEntry`，用现有的磁盘 `cachedWordPractices` 按 `(wordKey, periodIndex, type)` 统计实际数量，若某 type 现存数量 `>= nRepetitions`（说明本轮该类型本来就已经生成够，不管是否被消耗过），直接把该 type 加入 `completedGenerationTypes` 并落盘。这一步只做"回填标记"，不改变任何现有练习数据本身，跑一次后旧数据和新数据在补齐逻辑下表现一致。

原因：补齐逻辑只按磁盘现存数量与目标值比较，无法区分"从未生成够"和"生成够后被消耗"，导致已消耗的练习被误当作缺口重新生成。
修复：在 WordReviewEntry 增加 completedGenerationTypes 字段，标记本轮各类型是否已生成够目标数量，生成/补齐逻辑改为先查该标记再决定是否生成，periodIndex 前进时清空标记；上线时对现有数据跑一次性迁移回填标记，避免旧数据触发一次性误补。

2. 列表删除单词后，回到 home 界面单词计数没更新

**现象**：在 phrase review 单词列表（`PhraseReviewWordSelectionViewController`）里删除一个单词后，返回 Home 界面，phrase review 卡片上的计数（"n/total"）没有更新，还是删除前的旧值。

**原因**：

- 删除逻辑在 `PhraseReviewWordSelectionViewController.swift`（`trailingSwipeActionsConfigurationForRowAt` 里的删除 alert action，约 693–699 行）：依次调用 `WordPracticeProducer.deleteWordPractices(forKey:lang:)`、`EbbinghausSchedule.update(for:) { schedule.removeValue(forKey:) }`、`ReinforcementWords.remove(word:for:)`，只更新磁盘和自身 `sections`/`tableView`，**没有发出任何通知**。
- `HomeViewController.swift` 里 `wordPracticeCounter`/`ebbinghausSchedule`（约 109–110 行）是**加载一次后缓存在内存里的实例变量**，`phraseReviewItems`（约 142–155 行）计算计数时读的是这两个缓存变量，不是实时读磁盘。
- `HomeViewController` 里唯一会重新加载这两个缓存变量并刷新 UI（`applySnapShots()`）的地方：
  - `.wordPracticeCounterUpdated` 通知观察者（约 360–379 行），但只在 `notification.userInfo["wordPracticeCounter"]` 存在时才刷新；
  - `appMovedToForeground()`（约 414–419 行），只在 app 从后台回到前台（`UIApplication.willEnterForegroundNotification`）时触发。
- `PhraseReviewWordSelectionViewController` 是以 modal 形式 present 出来的（`HomeViewController.swift` 约 1133–1137 行），dismiss 关闭 modal 并不会触发上面两条路径中的任何一条：不发通知、不进入后台。`viewWillAppear`/`viewDidAppear`（约 321–334 行）目前也完全没有重新加载 `ebbinghausSchedule`/`wordPracticeCounter` 的逻辑。所以从删除单词返回 Home 后，缓存的计数一直是旧值，直到下次 app 切后台再回前台，或者碰巧收到一个带 `wordPracticeCounter` payload 的 `.wordPracticeCounterUpdated` 通知。

**修复方向**：在 `HomeViewController.viewWillAppear(_:)` 里增加一次 `wordPracticeCounter`/`ebbinghausSchedule` 的重新加载并调用 `applySnapShots()`（做法与现有 `appMovedToForeground()` 一致），这样无论是从 modal 关闭返回、还是其它任何方式回到 Home，都会用磁盘最新状态刷新计数，不依赖具体是谁触发了变化、也不需要在每个可能修改数据的地方都记得发通知。

# 新需求 7

1. `makeAndCachePractices` 整词 `skipDuplicates` gate 导致缺失类型（如 imageSelection）永远补不上

**现象**：`backgroundRefresh()` 正确识别出某单词缺 `imageSelection` 练习（日志打印 `generating missing practices for types [...imageSelection]`），紧接着调用 `producer.makeAndCachePractices(for: [key], skipDuplicates: true)`，但 `[generateImage]` 日志从未出现，图片练习始终没生成。

**原因**：`WordPracticeProducer.swift`（`makeAndCachePractices`，约 257–263 行）在按类型精细生成逻辑（`neededCount`/`completedGenerationTypes`，新需求 6 引入）之前，仍保留了一个更早版本的整词粒度短路：

```swift
if skipDuplicates && wordPracticeCounter.keys.contains(Self.normalizedKey(from: word)) {
    continue
}
```

`backgroundRefresh()`/`generateWordPractices()` 每次调用都会 `WordPracticeProducer(words:articles:)` 新建一个 producer 实例，其 `wordPracticeCounter` 在 `init()` 里从磁盘全部缓存练习预填充（`countWordPractices(from:)`）。只要该单词**任意一种类型**已有缓存练习（几乎所有非全新单词都满足），`wordPracticeCounter.keys.contains(key)` 就为真，直接 `continue` 跳过该单词的整个处理体——包括后面本该执行的按类型 `neededCount`/`generateImage`/`makeAndCachePractices` 内部逐类型生成逻辑。也就是说，只有从未生成过任何练习的全新单词才能进入循环体；一旦某单词已有第一种类型的练习，其余类型（比如 imageSelection）永远补不上。

紧邻的注释（约 250–254 行）写道"用 `onDiskPractices`/`existingForWord` 精细判断代替 `skipDuplicates` 的整词跳过"，说明这一整词 `continue` 本应在引入按类型判断时被删除，但实际代码里从未删掉，导致注释与代码自相矛盾、按类型逻辑形同虚设。

**修复**：
- 删除 `makeAndCachePractices` 里整词 `skipDuplicates` 的 `continue` 短路，完全交给已存在的 `neededCount(for:)`/`completedGenerationTypes` 按类型判断决定是否需要生成（该机制已经能正确处理"部分类型已生成够/部分未生成够"的情况，不需要整词粒度的重复保护）。
- `wordPracticeCounter[key] = 0` 改为只在 key 不存在时才初始化为 0（`if wordPracticeCounter[key] == nil { wordPracticeCounter[key] = 0 }`），避免对已有内存计数的单词（该计数被 `next()` 用于判断何时推进 Ebbinghaus 轮次）造成重置。
- `skipDuplicates` 参数因此不再被使用，一并从函数签名和两处调用点（`PhraseReviewWordSelectionViewController.backgroundRefresh()`、隐含默认值的 `TextMeaningPracticeViewController.generateWordPractices`）移除。

# 新需求 8（新需求 4 的实现）

1. Reinforcement 单词标注/翻译复用：reinforce 时存 tokens，生成/补标注时直接复用，不重新调用 `analyzeAccents`/`translate`

**现象/需求**：新需求 4 已描述目标（reinforce 时存已标注的 `contextSentence` 对应 tokens 和翻译好的 meaning，生成练习/补标注时直接复用，避免重复调用 `analyzeAccents`/翻译接口），但截至新需求 6 完成时仍未落地——`ReinforcementWordEntry` 只存了纯文本 `contextSentence`/`meaning`，没有 tokens 字段，`WordPracticeProducer` 的生成和补标注逻辑仍无条件重新调用 `analyzeAccents`。

**修复（分步，已实现 (1)(2)(3)，(4) 待实现）**：

1. `ReinforcementWords.swift`：`ReinforcementWordEntry` 新增 `contextTokens: [Token]?` 字段（Codable，nil 表示尚未分析完成），`add()` 增加 `contextTokens` 参数。
2. `WordMarkingTextView.swift`：`WordInfo` 新增 `contextTokens: [Token]? = nil`；`reinforceMenuItemTapped()` 在现有翻译请求之外，额外后台调用 `analyzeAccents(for: contextSentence)`，结果写入对应 `reinforcementWordsInfo[index].contextTokens`。
3. `TextMeaningPracticeViewController.swift`：`generateWordPractices(from:)` 调用 `ReinforcementWords.add(...)` 时传入 `contextTokens: reinforcementWordInfo.contextTokens`。
4. **待实现**：`WordPracticeProducer.swift`
   - 意思相关练习生成（`neededMeaningSelection`/`neededMeaningFilling` 分支，约 349–387 行）：调用 `machineTranslator.translate(query: word)` 前先查 `ReinforcementWords.load(for: self.lang)[key]?.meaning`，非空则直接使用，跳过翻译请求。
   - `makeContextSelectionPractice` 已经复用了 `contextSentence` 纯文本（3.1 节之外新增，非本次需求），但其上下文标注仍会重新触发 `analyzeAccents`；以及 `annotateExistingPractices`（约 536–619 行）：两处对 context 调用 `analyzeAccents(for: context)` 前，先查 `ReinforcementWords.load(for: self.lang)[key]?.contextTokens`，若非空且对应 `contextSentence` 与当前 context 文本一致，则直接用存好的 tokens 现算标注（`calculateVerbAspectAnnotations`/`calculateNounCaseAnnotations`/`calculateShortAdjectiveAnnotations`/`calculateAccentLocs`），不再调用 `analyzeAccents`。

原因：`analyzeAccents`（日语走网络请求、俄语走 Core Data 查询）和翻译接口都是昂贵调用，reinforce 时已经拿到了同一份 `contextSentence` 的分析结果，生成/补标注阶段应直接复用而非重算。
修复：`ReinforcementWordEntry` 增加 `contextTokens` 存储分析结果，reinforce 时后台分析并存入，生成练习/补标注时优先查询复用，缺失时才回退到现有的 `analyzeAccents`/翻译逻辑。

**实施范围限定**：`makeContextSelectionPractice` 构造 `practice.context` 时已经把目标词替换成 `Strings.underscoreToken`（占位符），如果直接把 `contextTokens`（针对未替换的原始 `contextSentence` 分析出的 tokens）喂给 `calculateVerbAspectAnnotations(for: context, with: contextTokens)`，会因为 `context` 文本里已经没有目标词的原文而匹配失败/错位（`calculateVerbAspectAnnotations`/`calculateNounCaseAnnotations` 都是按 token.text 在 text 里顺序查找子串定位，查不到会导致该 token 之后的标注整体丢失）。这正是本节前面"已知需要处理的细节"里提到的遮空替换偏移问题，标注为"非阻塞、实施时展开"，本次不处理。

# 新需求 9

1. Phrase review 列表数字状态在生成图片期间反复横跳（如 220 ↔ 222）

**现象**：phrase review 列表里第三位数字（imageSelection 已生成数量）在图片批量生成期间，会在正确值和回退值之间来回跳动，而不是单调递增到目标值。

**原因**：`WordPracticeProducer` 的 `wordPracticeCounter: [String: Int]`（`WordPracticeProducer.swift:17`）和继承的 `practiceList`（`BasePracticeProducer.swift:17`）都是普通、无锁保护的可变属性。`makeAndCachePractices(for:)`（约 244 行起）里 `for word in words` 主循环（259 行）对每个单词会触发多个**互相独立、互不等待**的异步分支：意思翻译回调（361–404 行）、组词练习回调（423–434 行）、**图片生成回调**（438–461 行，走 `ContentCreator.generateImage`/`pollImageTask`，是耗时最长的异步轮询）、accent selection 回调（484–555 行）。每个回调各自对 `wordPracticeCounter[key]! += 1` 做读改写、对 `practiceList.append(...)` 做追加，多个回调并发执行时构成经典的 lost-update 竟态（字典/数组本身也不是线程安全的，并发写属于未定义行为）。

更严重的是：`PhraseReviewWordSelectionViewController.backgroundRefresh()`、`TextMeaningPracticeViewController.generateWordPractices()`、`WordsPracticeViewController` 各自独立 `WordPracticeProducer(words:articles:)` 创建自己的 producer 实例，每个实例 `init()` 时各自从磁盘加载一份 `practiceList`/`wordPracticeCounter` 快照（`loadCachedPractices`）。`cache()`（61–70 行）每次都是把**当前实例内存中的整份 `practiceList` 快照**覆盖写入磁盘文件（`save`→`saveUnlocked`，走 `IO.swift:31` 的文件锁——锁只保证单次写入的字节不损坏，不能防止一个 producer 用较旧的快照覆盖另一个 producer 刚写入的更新状态）。图片生成是所有异步分支里耗时最长的，因此最容易在其它分支/其它 producer 实例已经把计数刷新到磁盘之后，被自己持有的旧快照 `cache()` 覆盖回去，表现为数字先涨到 222 又跌回 220，如此反复直到所有分支都结束。

**修复**：
- `WordPracticeProducer` 内所有对 `wordPracticeCounter`/`practiceList` 的读改写以及紧随其后的 `cache()` 调用，统一通过一个串行队列（或锁）保护，避免并发的 `+= 1`/`append`/整体覆盖写交错。
- 更彻底的修复：把 `cache()` 改成同 `EbbinghausSchedule.update(for:)`/`WordPracticeProducer.update`（`EbbinghausSchedule.swift:140–150`、`WordPracticeProducer.swift:1191–1202`）一样的"文件锁下 load-mutate-save"模式——每次写入前先重新读一次磁盘最新状态、把本次新增的练习合并进去再写回，而不是无条件覆盖整份内存快照，这样即使多个 producer 实例并发运行，也不会互相覆盖对方已经落盘的新增练习。

2. Phrase review 列表单词文本在两种大小写/标点变体间反复横跳

**现象**：同一个单词的显示文本会在 `"двигаться дальше,и"`（全小写、逗号两侧无空格）和 `"Двигаться дальше, и"`（首字母大写、逗号后有空格）之间交替出现。

**原因**：与 `analyzeAccents`/`fixedText` 无关（俄语 `fixedText` 只处理 е→ё 替换，不改变大小写和标点空格，见 `RussianAccentAnalyzer.fixJeJo`，`RussianAccentAnalyzer.swift:177–209`）。真正原因是两处不同调用把不同的字符串当作"单词显示文本"写入了 `WordPractice.word`：

- 原始大小写版本（如 `"Двигаться дальше, и"`）：来自用户在 `WordMarkingTextView.reinforceMenuItemTapped()`（`WordMarkingTextView.swift:727`，`let word = text(in: selectedTextRange)`）选中的原文，经 `TextMeaningPracticeViewController.generateWordPractices()`（`TextMeaningPracticeViewController.swift:268`）原样传入 `makeAndCachePractices(for:)`。
- 归一化 key 版本（如 `"двигаться дальше,и"`）：`PhraseReviewWordSelectionViewController.backgroundRefresh()` 检测到某单词缺练习类型时，调用 `producer.makeAndCachePractices(for: [key])`（约 469 行），这里的 `key` 是 `EbbinghausSchedule` 字典的 key，本身就是 `WordPracticeProducer.normalizedKey(from:)`（`WordPracticeProducer.swift:1251–1254`：全小写 + 去除标点两侧空格）的输出——**把归一化 key 误当作显示用单词文本传了进去**。该字符串随后原样进入 `makeAccentSelectionPractice`/`makeImageSelectionPractice` 等构造函数的 `word` 参数，新生成的 `WordPractice.word` 就是丑化后的归一化字符串，和该单词此前已有的原始大小写记录混在同一份缓存里。

`PhraseReviewWordSelectionViewController.loadEntries()`（约 285–292 行）构建 `displayWordByKey` 时按磁盘数组顺序"谁先出现就用谁"：
```swift
if displayWordByKey[k] == nil {
    displayWordByKey[k] = p.word.replacingOccurrences(of: String(Token.accentSymbol), with: "")
}
```
而数组顺序取决于原始 reinforce 生成批次和后续 `backgroundRefresh` 补齐批次的写入时机交错，每次 `.wordPracticeCounterUpdated` 通知触发重新 `loadEntries()`（这个通知因上一条竟态问题触发得很频繁）时，两个变体谁先出现在数组里是不确定的，导致显示文本随之交替横跳。

**修复**：`backgroundRefresh()` 第 469 行不应直接传归一化 key，应改为查询该 key 对应的原始显示文本（如已构建好的 `displayWordByKey[key]`，或 `ReinforcementWords.load(for: lang)[key]?.word`）传给 `makeAndCachePractices(for:)`，从源头上避免把归一化字符串写入 `WordPractice.word`。（若磁盘上已存在被污染的归一化版本记录，需要额外一次性清理/合并，本次先阻断新增污染，历史脏数据清理视情况再定。）

**已修复 ✅**（两条都已实施）：
1. `WordPracticeProducer.swift`：新增私有 `stateQueue`（`DispatchQueue(label:)`）和 `mutate(_:)` 辅助方法，把 `wordPracticeCounter`/`practiceList` 所有读改写操作（`next()`、`cache()`、`resetWordPracticeCounter()`、`makeAndCachePractices` 内所有 `practiceList.append`/`wordPracticeCounter[...] += 1`/`markTypeCompletedIfQuotaMet` 的计数读取）统一收进 `mutate { ... }` 闭包，用 `stateQueue.sync` 串行化，消除并发读改写竟态。`cache()` 单独调用 `mutate` 取出快照后立即返回，不在 `mutate` 内部嵌套调用自身或其它 `mutate`，避免死锁。跨 producer 实例之间的整体覆盖写竟态（多个 producer 各自 `cache()` 互相覆盖）未处理，留作后续更彻底的"文件锁下 load-mutate-save"改造（已在原因分析中说明）。
2. `PhraseReviewWordSelectionViewController.swift`（`backgroundRefresh()` 约 467–477 行）：不再直接传 `key`，改为 `wordPractices.first?.word ?? ReinforcementWords.load(for: lang)[key]?.word ?? key` 解析出原始显示文本后传给 `makeAndCachePractices(for:)`。历史已污染的归一化版本记录未清理，仅阻断新增污染。

本次先落地风险可控、收益明确的一步：`makeAndCachePractices`/`annotateExistingPractices` 里对**主词本身**的 `analyzeAccents(for: word)` 调用，改为先查 `ReinforcementWords[key].contextTokens`，若非空则从里面按 `token.text` 与 `word` 做规范化匹配抠出对应的 token（一般是 1 个，含前后缀变化时可能需要模糊匹配 baseForm），命中则直接用，跳过 `analyzeAccents(for: word)`；未命中或 tokens 为空则照旧调用 `analyzeAccents`。`context`/`choices` 的标注逻辑本次不改，仍调用 `analyzeAccents(for: context)`/`analyzeAccents(for: choice)`。
