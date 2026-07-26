# Phrase Review 及杂项问题 — 分析与开发计划

> 待你逐条批注确认，我再开始开发。

---

## 需求 1：Phrase review 选项优先从待复习词中选，"实现了但没效果"

**根因已确认**：`PhraseReviewWordSelectionViewController.swift:129` 用 `Word.load(for: lang)` 加载了**全量词库**去初始化 `WordPracticeProducer`，但 `practiceWordSet`（160行附近）只包含本次选中的几个待复习词（比如 6 个）。

`WordPracticeProducer.swift:185-187` 的 `candidateWords` 过滤逻辑是"`self.words` 里属于 `practiceWordSet` 的词"——但 `self.words` 是全量词库，`practiceWordSet` 只有几个词，两者交集几乎总是空。`choices()`（374-402行）里"优先从待复习词选"的 pool 一取就是空，直接落回随机选择，所以感觉不到效果。

> **批注：**

### 开发计划
把 `candidateWords` 的判定条件从"是否在本次 practiceWordSet 里"改成"是否在艾宾浩斯复习计划里、且到期需要复习"（`nextReviewDate <= Date()`），排除当前正在出题的目标词本身。这样候选池就不再依赖传进来的局部词表范围，而是覆盖整个语言的复习计划。纯逻辑修正，低风险。

> **批注：**ok

---

## 需求 2：Phrase review 词语标注动词 aspect / 名词 case（仅标注待复习词）

**现状**：`TextMeaningPracticeView.swift` 已有完整标注机制——`markVerbAspects()`(682行)、`markNounCases()`(708行)、图例管理 `updateLegendVisibility()`(779行)，数据来自 `TextMeaningPractice.swift` 的 `VerbAspectAnnotation`/`NounCaseAnnotation` 结构，由 `TextMeaningPracticeProducer` 生成。

Phrase review 用的 `WordPractice` 模型完全没有这两个标注字段，渲染用的 `SelectionPracticeView` 只是纯文本，没有任何标注能力。

> **批注：**

### 开发计划
- `WordPractice` 加 `verbAspectAnnotations` / `nounCaseAnnotations` 字段（结构复用 `TextMeaningPractice` 里的两个 struct）。
- `WordPracticeProducer` 生成 practice 时调用现有的 `calculateVerbAspectAnnotations()` / `calculateNounCaseAnnotations()`，但**只保留落在待复习目标词（query）范围内**的标注，不覆盖整句其它词。
- 把 `markVerbAspects`/`markNounCases`/图例渲染这部分逻辑抽成可复用的 helper（避免在两个 View 里各写一份），`SelectionPracticeView` 里接入这个 helper，并加上对应的图例视图。

> **批注：**ok

---

## 需求 3：TextMeaningPracticeView loading icon 被输入框遮住

**根因**：`updateViews()` 里 `contentGenerationSpinner` 在 431 行先被加进 `mainView`，`chatInputBar`（含输入框）在 436 行后加入，view 层级上输入框在上层。当 LLM 内容流式进入、聊天气泡撑高滚动区域或键盘弹出导致布局变化时，输入框会盖住 spinner 的位置。图例视图（498-501行）位置独立，不受这个问题影响。

> **批注：**

### 开发计划
在 LLM 开始生成的委托方法 `startedContentGeneration`（850行附近）里显式调用 `mainView.bringSubviewToFront(contentGenerationSpinner)`，保证 spinner 始终置顶，不需要改动图例和输入框的其它布局约束。纯 UI 修复，低风险。

> **批注：**ok

---

## 需求 4：有 LLM 内容时 timeout 不自动 dismiss，需手动点 next

**现状**：`TextMeaningPracticeViewController.swift` 的 `timingBarTimeUp()`（332-335行）无条件调用 `stopPracticing()` 触发 dismiss。是否有 LLM 内容可以在**超时触发的那一刻**用 `TextMeaningPracticeView.chatBubblesStack.arrangedSubviews.isEmpty` 判断（不能在计时器创建时判断一次，因为内容是异步到达的，超时时才是准确状态）。next button 已经走 `stopPracticing()`，不需要改。

> **批注：**

### 开发计划
`timingBarTimeUp()` 里加判断：若 `chatBubblesStack` 非空（有 LLM 内容）则不 dismiss，只有用户手动点 next 才 dismiss；若为空则维持现有的超时自动 dismiss。单点改动，低风险。

> **批注：**ok

---

## 需求 5：WordMarkingTextView 增加动词 aspect partner 查询（对话泡泡显示）

**数据源确认**：`verbs.csv`（15296行）有 `word_id, aspect, partner` 三列，`partner` 是分号分隔的搭档动词文本（如 говорить 对应 сказывать），需要 join `words.csv` 的 `id` 才能拿到具体动词原文；App 内目前只有 `russian_verb_aspects.json`（体态词库），没有 partner 数据。

**现有 UI 模式**：`WordMarkingTextView.swift` 已有类似菜单项（`wordTranslationMenuItem` / `grammarExplanationMenuItem`，640-649行），通过 `sendChatMessageForAction` 走 LLM 流式生成，再经委托回调让 `TextMeaningPracticeView` 用 `makeBubble()`（1091-1121行）渲染对话泡泡。

> **批注：**

### 开发计划
- 写一个预处理脚本（本机跑，不进 app 运行时），从 `verbs.csv` + `words.csv` join 出一份小体积 JSON（如 `russian_verb_partners.json`：`{动词文本: [搭档动词文本, ...]}`），按现有 `russian_verb_aspects.json` 的方式加进 Xcode 资源打包。
- `RussianAccentAnalyzer` 里加一个 `verbPartners` 字典加载（模式同现有 `verbAspects`）。
- `WordMarkingTextView` 新增一个菜单项（只在俄语、且选中词在 `verbPartners` 里有值时显示），点击后**不走 LLM**，直接把查到的搭档动词文本通过现有对话泡泡委托流程（`chatDidSendMessage`/`chatDidReceiveChunk`/`chatDidFinish`）展示出来，复用现成的气泡 UI，不用新写渲染代码。

> **批注：**ok，从 @/Volumes/Windows/Users/Neko/OneDrive/Repos/polyglot-backend/russian_word_analyses/resources 拿数据

---

## 优先级与风险小结

| 需求 | 类型 | 风险 | 是否需要额外数据 |
|---|---|---|---|
| 1. Phrase review 候选池 bug | bug 修复 | 低 | 否 |
| 3. loading icon 遮挡 | UI bug | 低 | 否 |
| 4. timeout 不自动 dismiss | 逻辑修复 | 低 | 否 |
| 2. Phrase review 标注 aspect/case | 新功能（复用现有渲染逻辑） | 中 | 否 |
| 5. 动词 aspect partner 查询 | 新功能 | 中 | **是**，需新生成 partner JSON |

**建议**：1、3、4 是独立的低风险修复，可以先并行改完验证；2、5 涉及新数据结构/新字段，工作量稍大但互相独立，可以同时开发。

> **总批注：**一起开发
