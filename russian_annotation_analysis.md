# 俄语语法标注功能 — 问题分析与开发计划

> 待你逐条批注确认，我再开始开发。

## 背景：数据链路

三个词库 JSON（`russian_verb_aspects.json` / `russian_noun_cases.json` / `russian_word_forms.json`）在 build 时打进 App bundle。`russian_word_forms.json` 先导入 Core Data（`RussianAccentEntity`，通过 `RussianAccentAnalyzer.addRussianAccentEntitiesToCoreDataModel()` 手动跑一次生成）。运行时 `RussianAccentAnalyzer.getTokens()` 查 Core Data 拿 `baseForm`，再用 `baseForm` 去查 `verbAspects` / `nounCases` 字典（`RussianAccentAnalyzer.swift:107-151`）。

`russian_noun_cases.json` 是用桌面上的 `generate_noun_cases.py` 从某个 `words_forms.csv`（形态标注表，带 `form_type` 字段，如 `ru_noun_sg_gen`）生成的。这份 CSV 本机没找到——如果后续要扩展词库（短尾形容词、分词），大概率还得靠这份 CSV 或类似数据源。

> **批注：** 数据来源：@/Volumes/Windows/Users/Neko/OneDrive/Repos/polyglot-backend/russian_word_analyses/resources

---

## 需求 1：部分动词/名词没被标色

### 动词部分（已用实际数据验证根因）

`addRussianAccentEntitiesToCoreDataModel()`（`RussianAccentAnalyzer.swift:242-278`）里，当同一个词形在 `russian_word_forms.json` 里对应**多个不同 base** 时，代码显式把 `entity.base_form = nil`：

```swift
let accentPosSet = Set(d.compactMap { d in d.accent_pos })
if accentPosSet.count == 1 {
    ...
} else {
    // Do nothing.  <- base_form 保持 nil
}
```

之后 `verbAspects[baseForm ?? query]` 退化成查原始词形，但体态词库只收录动词原形，查不到，于是不上色。实测验证：

| 词形 | word_forms 候选 base | 结果 |
|---|---|---|
| `добьётесь` | `добиться` / `добыться`（2个）| base_form=nil → 查不到 aspect |
| `упоминаем` | `упоминать` / `упоминаемый`（2个）| 同上 |
| `соревнуйтесь` | word_forms 里完全没有这个词形 | 连 accent 都查不到 |
| `провел` | 经 je2jo 转换后能查到 `провести`→perfective | **验证是正常链路**，可能是 Core Data 没用最新 json 重新生成，需要实机复测 |

> **批注：** 对于动词，当同一个词形在 `russian_word_forms.json` 里对应多个不同 base 时，如果多个 base 的 aspect 相同，则也可以标注颜色，否则才标注 ambiguous。

### 名词部分

`обучения`/`чтения`/`прослушивания`/`книги` 在词库里的值是 `ambiguous_nom_gen_acc`。走到消歧分支（`AccentAnalyzerProtocol.swift:192-204`）时，三条规则（量词前置、-ого/-его结尾、前一词也是名词）都不满足，前一词也不是已知前置词，于是**保持 `ambiguous_*` 标签**——这其实有渲染（灰色 "?"），不是完全没上色。需要确认你说的"没有标注颜色"是指完全没上色，还是显示成灰色而非具体格颜色，看起来像没标。

> **批注：**   
> 1. основным средством *обучения* 这里的 средством 不是名词吗  
> 2. с *чтения* и *прослушивания* историй 这里的名词前面是 с，支配 gen/inst（还有没有其他格）？但是 чтения 不是 inst，所以是 gen。=> 可以这样判定吗。

### 分词（participle）

完全未实现，代码和词库都没有这个概念，6 种形动词/副动词形式没有专门数据源或规则。

> **批注：**你从数据源抽取所需数据，塞进 russian_verb_aspects（注意 {主动|被动}{现在|过去} 涉及很多形容词变化，都需要考虑）

### 开发计划
- **动词 base_form 冲突**：改 `addRussianAccentEntitiesToCoreDataModel` 或 `getTokens`，当多个候选 base 存在时不要直接放弃，改成保留候选列表、查 aspect 词库时按候选逐个尝试（任一命中即可）。低风险，纯代码修复。
- **名词 ambiguous**：先确认预期行为是否可接受灰色标注；如需更精确，需要扩充消歧规则或更细粒度词库（当前 CSV 源缺失，短期只能加规则不能大幅提升准确率）。
- **分词识别**：需要新数据源。纯词尾规则（如 -щий/-вший/-нный/-в/-я）误报率高（很多形动词已固化为形容词）。建议用 pymorphy2/pymystem3 等俄语形态分析库离线生成词表（类似 `generate_noun_cases.py` 的做法），或找回原始 CSV 补充 participle 的 form_type。工作量较大，建议单独排期。

> **批注：**这部分不使用你的开发计划，先看看我的批注

---

## 需求 2：в/на + acc 斜体化「实现了但没效果」

**根因已确认，是明确的代码 bug（判断条件写窄了）。**

`TextMeaningPracticeView.swift:714-722` 的渲染逻辑本身没问题：

```swift
case "nom", "acc", "nom_acc":
    if !annotation.isItalic { continue }
    textView.textStorage.addAttributes(attrs, range: range)
    continue
```

问题在生成 annotation 的地方，`AccentAnalyzerProtocol.swift:206`：

```swift
} else if nounCase == "acc" && (prevText == "в" || prevText == "на") {
```

这个分支只在 `nounCase` **精确等于** `"acc"` 时触发。但实测词库数据，比如例句「в годы Второй мировой войны」里的 `годы`，在 `russian_noun_cases.json` 里的值是 `"nom_acc"`，不是 `"acc"`！所以分支根本没进去，annotation 没生成，斜体自然不会出现。

> **批注：**

### 开发计划
把判断改成 `(nounCase == "acc" || nounCase == "nom_acc")`；并且对 ambiguous 消歧后结果为 acc 的情况也要覆盖到 —— 目前消歧逻辑（第192-204行）和 в/на+acc 特殊判断是互斥的 `if/else if`，消歧完之后不会再检查是否需要斜体，需要重构判断顺序（先做消歧，再统一检查是否需要 в/на+acc 斜体）。纯代码修复，低风险。

> **批注：**ok

---

## 需求 3：名词前有形容词时，前置词判断被挡住

**根因已确认**，跟你猜的一致。`AccentAnalyzerProtocol.swift:190`：

```swift
let prevText = i > 0 ? tokens[i - 1].text.lowercased() : ""
```

只看紧邻的前一个 token。如果前一个 token 是形容词（如「первые недели」中 `недель` 前面是 `первые`），`prepToCase["первые"]` 查不到，消歧失败。

> **批注：**

### 开发计划
改成向前扫描，跳过"看起来像形容词"的 token 去找前置词。俄语形容词长尾变格词尾相对规律（`-ый/-ий/-ой/-ая/-яя/-ое/-ее/-ые/-ие/-ого/-его/-ому/-ему/-ым/-им/-ом/-ей` 等），写一个轻量启发式函数 `looksLikeAdjective(_ text: String) -> Bool`：向前扫描时遇到符合形容词词尾的 token 就跳过继续找上一个，遇到不符合的就停止（可能是前置词也可能不是，找到即用，找不到退回空字符串保持现状）。建议限制最多跳过 2-3 个 token，避免误判连续形容词或形容词其实是名词的情况。纯代码新增逻辑，低风险，但词尾规则需要跟你过一遍确保覆盖全。

> **批注：**ok

---

## 需求 4：短尾形容词斜体化

**现状：完全没有实现，也没有可用数据源。**

桌面上的 `russian_adjectives.json`（52万条）实际内容是括号包裹的长尾工具格形式（如 `(аароновскою)`），跟短尾形容词无关，用不上。

短尾形容词（如 `хорош`, `красива`, `важны`）词形跟很多名词格/其他词性有词尾重叠，没有专门词库几乎无法准确识别（比如 `весел` 也可能被误判成别的）。

> **批注：**

### 开发计划
需要专门的短尾形容词词表（词形 → 是否短尾形容词，或直接给出对应长尾 base）。数据来源两个选项：
1. 如果还留有当年生成 `russian_noun_cases.json` 用的那份 `words_forms.csv`（带 `form_type` 字段），可以照 `generate_noun_cases.py` 的模式写新脚本筛出 `ru_adj_short_*` 类型的行，生成 `russian_short_adjectives.json`。
2. 如果 CSV 找不到了，需要用 pymorphy2 等库离线生成词表。

Swift 侧代码（加载词库 + 判断 + 斜体渲染）复用 nounCase 现有模式即可，不复杂。**需要先确认数据源才能评估工作量和排期。**

> **批注：**数据源：@/Volumes/Windows/Users/Neko/OneDrive/Repos/polyglot-backend/russian_word_analyses/resources

---

## 需求 5：代词和 тот/который 的 case 标注

**现状**：Token 已能带 `nounCase`，如果代词本身在词库里就会被标注，但没有专门代词逻辑，也没有根据先行词消歧 `который` 这类相对代词的 case。

> **批注：**

### 开发计划
- **简单人称代词**（他/她/它/我/你等，形态固定无歧义）：如果词库里已有条目应该已经能工作，需要先确认要覆盖哪些代词，我再去查词库是否已收录。
- **`тот`/`который` 等指示/关系代词**：格取决于句法角色。规则消歧（复用需求3的前置词回溯逻辑）能处理"代词前有前置词"的情况，但处理不了"关系代词的格由从句内部动词/名词决定"（如「человека, которого...」中 `который` 应为 acc）这种更深层句法关系——简单规则做不到高准确率，建议只做前置词消歧能覆盖的部分，句法层面消歧作为已知局限说明清楚，不承诺完全解决。

> **批注：**。
> 1. 简单人称代词即可。  
> 2. 规则消歧（复用需求3的前置词回溯逻辑）能处理"代词前有前置词"的情况，但处理不了"关系代词的格由从句内部动词/名词决定"（如「человека, которого...」中 `который` 应为 acc）这种更深层句法关系——简单规则做不到高准确率，建议只做前置词消歧能覆盖的部分 => 同意。无法消歧则 ambiguous（灰色）。如果能确定是 gen/dat/inst/prep，颜色和名词标注相同

---

## 需求 6：Legend 分两行

**现状**：`TextMeaningPracticeView.swift:281-288`，`legendView` 是横向 `UIStackView`，包 `nounCaseLegendView`（5格横向）和 `aspectLegendView`（3体横向），两者当前横向并排。

> **批注：**

### 开发计划
把最外层 `legendView` 的 `axis` 从 `.horizontal` 改成 `.vertical`，内部两个子 stack 各自保持横向不变，自然分两行（名词格一行，动词体一行）。纯 UI 改动，低风险，改完跑 Practice 界面确认排版没溢出。

> **批注：**ok

---

## 优先级与风险小结

| 需求 | 类型 | 风险 | 是否需要额外数据 |
|---|---|---|---|
| 2. в/на+acc 斜体 | bug 修复 | 低 | 否 |
| 3. 前置词跳过形容词 | 新逻辑 | 低 | 否（词尾启发式） |
| 6. legend 分两行 | UI | 低 | 否 |
| 1(动词部分). base_form 冲突 | bug 修复 | 低 | 否 |
| 1(名词ambiguous). 消歧规则 | 待确认预期 | 低 | 否 |
| 5(前置词部分). 代词消歧 | 新逻辑（复用需求3） | 低 | 否，但需先查词库覆盖情况 |
| 1(分词). 6种形动词/副动词 | 新功能 | 中高 | **是**，需定数据源 |
| 4. 短尾形容词斜体 | 新功能 | 中 | **是**，需定数据源 |
| 5(句法部分). 关系代词句法消歧 | 新功能 | 高，准确率有限 | 视方案 |

**建议**：先做 2、3、6、1(动词bug) 这几个低风险高确定性的修复一起提交一版；4、5、1(分词) 涉及数据源的部分需要先确定 CSV/词库方案后再排期。

> **总批注：**同时开发。你先重新制定计划

---

## 重新制定的开发计划（v2）

### 数据源确认

在 `/Volumes/Windows/Users/Neko/OneDrive/Repos/polyglot-backend/russian_word_analyses/resources/words_forms.csv` 找到了原始形态标注表（171万行），已确认包含：
- `ru_verb_participle_active_present` / `ru_verb_participle_active_past` / `ru_verb_participle_passive_present` / `ru_verb_participle_passive_past` / `ru_verb_gerund_present` / `ru_verb_gerund_past` —— 需求1的6种分词/副动词，每种都带 `word_id`，可关联回 `verbs.csv` 拿到该动词的 aspect。
- `ru_adj_short_m` / `ru_adj_short_f` / `ru_adj_short_n` / `ru_adj_short_pl` —— 需求4的短尾形容词，`_form_bare` 直接给出具体词形。
- `тот`（word_id=8）、`который`（word_id=31）在 `words.csv` 里 type=adjective，在 `words_forms.csv` 里当长尾形容词一样有完整的 `ru_adj_{m,f,n,pl}_{nom,gen,dat,acc,inst,prep}` 变格表，可以直接复用名词格的解析/消歧逻辑。
- 简单人称代词（я/ты/он/она/оно/мы/вы/они，以及их/его/её/тебя/меня/нам/вам/им 等格式变化）在 `words.csv` 里 type 多为 `other`，需要单独在 `words_forms.csv`/`words.csv` 里按 word_id 收集所有格式变化，构造代词专用格标注词表。

用户确认：**分词/副动词的着色直接复用现有 aspect 颜色（imp./p./bi.），因为它们是动词变位的一部分**，不新增 legend 条目。

### 任务分解（全部同步开发）

**A. 数据脚本（Python，仿照 `generate_noun_cases.py` 的模式）**
1. `generate_participle_aspects.py`：从 `words_forms.csv` 筛出 6 种 participle/gerund 的 form_type 行，按 `word_id` 关联 `verbs.csv` 拿到 `aspect`，输出 `{_form_bare: aspect}`，合并进（或新建同结构文件后在 Swift 侧一并加载）`russian_verb_aspects.json`。
2. `generate_short_adjectives.json`：筛出 `ru_adj_short_*` 的行，输出词形集合（Set），供 Swift 侧判断"是否短尾形容词"并统一斜体化。
3. `generate_pronoun_cases.py`：
   - 指示/关系代词（`тот`、`который`）：从 `words_forms.csv` 里 `ru_adj_*` 变格表生成 `{_form_bare: case}`（复用 `generate_noun_cases.py` 的 ambiguous 合并逻辑），合并进名词 case 词库或新建 `russian_pronoun_cases.json`。
   - 简单人称代词：手动/半自动列出 я/ты/он/она/оно/мы/вы/они 的全部格形（词表较小，直接在 `words_forms.csv`/`words.csv` 里按 word_id 查出后手工核对补全），输出同结构 `{form: case}`。

**B. Swift 侧代码改动**

1. **需求1 - 动词 base_form 冲突**（`RussianAccentAnalyzer.swift:242-278`，**已按批注修正**）：当 `accentPosSet.count != 1`（多个候选 base）时不再直接丢弃，改为：
   - 保留全部候选 base（Core Data 需要能存多个 base，或改为存"候选 base 列表"字符串，用分隔符拼接，`getTokens` 里再拆开逐个查 `verbAspects`）。
   - 查询时：把所有候选 base 各自的 `verbAspects[candidate]` 取出来，若结果去重后只剩 1 种 aspect（包括只有一个候选有值、其余为 nil 的情况）→ 用这个 aspect 正常标色；若结果去重后有 ≥2 种不同 aspect → 标记为"ambiguous"。
   - **已确认**：新增第 4 种状态"ambiguous"（灰色 "?"，视觉上跟名词 ambiguous 一致）。改动范围：`calculateVerbAspectAnnotations` 增加 `"ambiguous"` → `label = "(?)"` 映射；`markVerbAspects` 增加灰色渲染分支；`aspectLegendView` 增加一个灰色 "?" legend 条目（跟 `ambiguousCaseLegendLabel` 类似样式）。

2. **需求1 - 分词/副动词 aspect 标注**：新增/合并词库后，Swift 侧无需新逻辑——只要 `verbAspects` 字典里能查到分词词形对应的 aspect，现有 `calculateVerbAspectAnnotations` 会自动生效（因为它只认 `token.aspect`，不关心词性）。

3. **需求1 - 名词 ambiguous 消歧（已按批注修正，新增两条规则）**：
   - **规则A（前一词是名词，按格排除）**：`средством обучения` 例子里，`средством` 本身 case=inst，是名词。现有代码 `AccentAnalyzerProtocol.swift:197` 其实已经有 `prevIsNoun` 判断（"前一个词也是名词则倾向判 gen"），按理这个例子应该已经命中现有规则。**需要先实机核实这条规则当前是否真的生效**——如果生效说明这个例子本来就该被正确标注，最初的问题描述可能不准；如果不生效（比如被 «» 引号打断了 token 相邻关系、或 tokenize 时 средством 前后有干扰），那是一个需要修的 bug，不是新增规则。开发时会先跑一次实机验证再确定是修 bug 还是加规则。
   - **规则B（前置词歧义 + 名词自身候选格排除法，新增）**：`с чтения` 例子里，`с` 本身支配两种格（gen 表示"从…"、inst 表示"与…一起"），是有歧义的前置词；但 `чтения` 自身的候选格集合是 `ambiguous_nom_gen_acc`，根本不包含 inst。用交集排除法：前置词候选格 {gen, inst} ∩ 名词自身候选格 {nom, gen, acc} = {gen}，唯一解，可以判定为 gen。这是一条通用规则：**把 `prepToCase` 扩展成支持"一个前置词对应多个候选格"（如 `с`→{gen,inst}，`за`/`под`→{acc,inst}，`между`→{gen,inst} 等），消歧时用前置词候选格集合和名词自身候选格集合做交集，交集恰好剩一个格就采用它**。这条规则要新增到 `calculateNounCaseAnnotations` 的消歧分支里。

4. **需求2 - в/на+acc 斜体判断**（`AccentAnalyzerProtocol.swift:206`）：
   - 判断条件从 `nounCase == "acc"` 扩到 `nounCase == "acc" || nounCase == "nom_acc"`。
   - 重构判断顺序：先跑 ambiguous 消歧（199-204行），消歧结果如果是 acc，也要继续检查是否在 в/на 之后从而追加斜体；即把 в/на+acc 检查从 `else if` 改成消歧完成之后再统一判断的独立步骤。
5. **需求3 - 跳过形容词找前置词**（`AccentAnalyzerProtocol.swift:190`）：新增 `looksLikeAdjective(_ text: String) -> Bool` 词尾启发式（覆盖长尾形容词全部格词尾），向前扫描最多2-3个token跳过形容词找前置词，取代当前只看 `tokens[i-1]` 的写法。此函数同时会被需求5的代词消歧复用。
6. **需求4 - 短尾形容词斜体化**：`RussianAccentAnalyzer` 加载新词表（Set<String>），`Word.swift`/`Token` 加 `isShortAdjective: Bool` 字段，`getTokens` 查表赋值；新增 `calculateShortAdjectiveAnnotations`（类似 `calculateVerbAspectAnnotations` 结构）；`TextMeaningPracticeView.markShortAdjectives` 只加斜体不加颜色（比照现有 acc 斜体逻辑）。
7. **需求5 - 代词 case 标注**：
   - 简单人称代词：加载代词格词表，`Token.nounCase` 复用（或新字段 `pronounCase`，视是否需要跟名词区分开渲染逻辑，颜色上用户要求跟名词一致，所以直接复用 `nounCase` 字段和现有渲染管线即可）。
   - `тот`/`который`：接入需求3新增的前置词回溯消歧逻辑，能确定 gen/dat/inst/prep 时用名词同色，无法确定时标 ambiguous（灰色）。
8. **需求6 - legend 分两行**（`TextMeaningPracticeView.swift:281-288`）：`legendView` 的 `axis` 从 `.horizontal` 改 `.vertical`。

**C. 验证**
- 用文档开头列出的所有例句（добьётесь / соревнуйтесь / упоминаем / провел / переводите / говорящий等6种分词各挑一例 / обучения / чтения / поищите книги / годы / первые недели / медной кружке / короткие形容词例句 / который例句）手动跑一遍 `RussianAccentAnalyzer`，确认颜色和斜体符合预期。
- 跑一次 Practice 界面（TextMeaningPractice）目测 legend 两行排版、颜色、斜体渲染是否正常，没有回归。
- 如涉及 Core Data 模型改动（需求1 base_form 候选列表），需要重新生成 Core Data 数据（`addRussianAccentEntitiesToCoreDataModel`）并确认迁移安全（这是本机一次性数据操作，不涉及生产多端同步，风险低但需要手动触发跑一次）。

### 已确认的实现细节
1. 代词 case 标注结果直接复用 `Token.nounCase` 字段，不新开字段。
2. 分词/副动词词表合并进现有 `russian_verb_aspects.json`；短尾形容词单独新建 `russian_short_adjectives.json`；代词 case 单独新建 `russian_pronoun_cases.json`。

### 最终文件改动清单
- `generate_participle_aspects.py`（新建脚本）→ 更新 `russian_verb_aspects.json`（合并分词/副动词词形）
- `generate_short_adjectives.py`（新建脚本）→ 新建 `russian_short_adjectives.json`
- `generate_pronoun_cases.py`（新建脚本）→ 新建 `russian_pronoun_cases.json`
- `RussianAccentAnalyzer.swift`：
  - `addRussianAccentEntitiesToCoreDataModel` 修复 base_form 多候选丢弃问题
  - 新增加载 `russian_short_adjectives.json`、`russian_pronoun_cases.json`
  - `getTokens` 增加短尾形容词判断（`isShortAdjective`）、代词 case 查询（写入 `nounCase`）
- `Word.swift`（Token 模型）：新增 `isShortAdjective: Bool` 字段
- `AccentAnalyzerProtocol.swift`：
  - `calculateNounCaseAnnotations`：重构 в/на+acc 判断（含 nom_acc、消歧后二次检查）；新增前置词回溯跳过形容词逻辑 `looksLikeAdjective`
  - 新增 `calculateShortAdjectiveAnnotations`
- `TextMeaningPracticeView.swift`：
  - `legendView` axis 改 `.vertical`
  - 新增 `markShortAdjectives`（只加斜体）
  - `markNounCases` 沿用现有管线即可覆盖代词（因为复用 `nounCase`）

计划已确认，可以开始开发。
