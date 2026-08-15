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
（2）Home view vc 显示满足练习条件的单词数（注意除了时间还有上述其他条件。现在显示的数量和可选择的单词的数量不一致）
（3）List 标题右侧显示选择的单词数，如 (6) 这样子。选择/取消选择需要动态更新
（4）补标注：每次点开列表只标注 10 个轮数最少的，已到达练习时间的单词
（5）正在补标注/meaning的单词，需要有字体颜色变化（呼吸效果，浅灰深灰切换）。此外，补标注/meaning时，meaning 字段显示正在补标注的内容，类似：正在标注重音;语法;含义（可同时显示多个标注内容）。点击标注中的单词的cell时，meaning 字段内容在标注说明和meaning（如已有）间切换。默认显示标注说明
（6）目前显示标注完成（数字加粗）的练习，有些还是没重音，比如说 prompt 或者 context 没重音。
（7）Reordering 的练习，需要练习的单词会有表示重音的单引号（但应该用加粗标注）
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

3. Phrase review（续）
（3）List 标题右侧显示选择的单词数，如 (6) 这样子。选择/取消选择需要动态更新
原因：title 固定为 Strings.phraseReview，选择状态变化时不更新
修复：updateStartButton() 同时更新 title，0 个选中时显示原标题，有选中时追加 (N)

（6）目前显示标注完成（数字加粗）的练习，有些还是没重音，比如 prompt 或 context 没重音
原因：isAccentAnnotationCompleted 标记"已尝试标注"而非"标注实际生效"；addAccents 使用 replacingOccurrences 精确子串匹配，当 query/context 里词形与原词不一致（变格、变位）时替换静默失败，但 flag 仍置 true
修复：（暂不修复，待评估）

（7）Reordering 练习的单词包含重音单引号
原因：addAccents 将 practice.key 替换为带 ' 的 accentedWord 后，reorderingWordList 从 practice.key.split 生成，split 出的每个词保留了 accentSymbol
修复：split 后 map 去掉每个词里的 Token.accentSymbol

4. 崩溃与计数修复
（1）选择词语练习点 Start 闪退
原因：updateViews() 中 phrase review 分支调用 progressLabel.removeFromSuperview()，之后 super.updateLayouts() 仍对其激活 SnapKit 约束，两个 anchor 没有共同祖先触发 NSGenericException
修复：PracticeViewController.updateLayouts() 中对 progressLabel 设约束前加 superview != nil 保护，phrase review 模式下跳过该约束

（2）Home view phrase review 数量显示虚高
原因：ebbinghausSchedule 包含 isCompleted 的条目（已完成所有复习轮次），isAvailable 只检查日期不排除已完成，Home 计数将这些也算进去
修复：先过滤掉 isCompleted 的条目，total 和 available 都只统计活跃条目
