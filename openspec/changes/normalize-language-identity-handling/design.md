## Context

当前 Reader 的语言相关流程跨越多个模块，但没有统一的语言身份契约：

- `language_detector.dart` 返回的是粗粒度语言标签，例如 `zh`、`en`、`ja`、`ko`、`ru`。
- `language_utils.dart` 负责语言标签的语法规范化与显示名称映射，但没有把规范化结果与“语义等价”区分开。
- `article_ai_providers.dart` 用规范化后的字符串直接决定语言不匹配提醒和自动翻译触发。
- `translation_service.dart` 为不同提供方分别映射目标语言代码，但其输入可能来自 raw locale、设置值或跟随系统语言的运行时 locale。
- `translation_ai_settings.dart` 与 `app_settings.dart` 当前仅保留原始字符串，历史配置中的 `zh-CN`、`zh-Hans-CN`、`en-GB` 等标签会直接参与后续运行时判断。

这导致系统同时混用了四种不同语义层次的数据：

```text
原始 locale/tag         语法规范化 tag         语义比较键         提供方目标码
zh-Hans-CN      ->      zh-Hans-CN     ->     zh-Hans     ->    zh-CN / zh-Hans / ZH-HANS
en-GB           ->      en-GB          ->     en          ->    en
zh-TW           ->      zh-TW          ->     zh-Hant     ->    zh-TW / zh-Hant / ZH-HANT
```

当前问题并不局限于中文误报。任何“检测结果较粗、目标语言较细”的场景都可能错误触发语言不匹配提醒或自动翻译，包括 `en` vs `en-GB`、`zh` vs `zh-Hans-CN` 等。与此同时，语言名展示也会在遇到未列入映射表的 tag 时把 raw tag 直接暴露给用户。

## Goals / Non-Goals

**Goals:**

- 建立一套统一的语言身份模型，明确 raw tag、规范化 tag、语义比较键和 provider code 的职责边界。
- 消除 Reader 中因等价语言标签导致的误报、误自动翻译和原始 tag 泄漏到 UI 的问题。
- 让中文在业务判断层面支持简体/繁体区分，并对英文及其他已暴露的目标语言提供稳定兼容路径。
- 让跟随系统语言、用户显式配置与历史持久化设置都通过同一套 canonicalization 规则进入运行时。
- 为语言归一化、源语言检测、Reader 提醒与 provider 目标码映射建立完整测试矩阵。

**Non-Goals:**

- 不把应用本地化语言范围从 `en`、`zh`、`zh-Hant` 扩展到新的 UI 语言。
- 不引入新的翻译提供方或修改现有提供方的网络协议。
- 不追求通用 NLP 级别的全语言精确检测；对低置信度或未覆盖语言允许返回 `unknown`。
- 不在本次变更中引入云端语言识别服务。

## Decisions

### Decision 1: 引入统一的语言身份模型

新增一套面向业务的语言身份契约，至少包含以下概念：

- `rawTag`: 外部输入或历史设置中的原始语言标签。
- `normalizedTag`: BCP-47 语法层面规范化后的标签，保留 script/region 信息。
- `compareKey`: 用于业务比较的 canonical key。
- `displayKey`: 用于 UI 名称展示的 canonical key，可与 `compareKey` 复用。
- `providerCode`: 针对具体翻译提供方的目标语言编码。

语义比较不再直接依赖 `normalizeLanguageTag()` 的字符串结果，而统一依赖 `compareKey`。

选择原因：

- 能显式隔离“存什么”“比什么”“显示什么”“发给 provider 什么”的边界。
- 避免未来继续在业务逻辑中散落 `zh-Hans-CN`、`zh-CN`、`zh` 的多种等价写法。

备选方案：

- 继续在现有调用点追加特判，例如只处理 `zh-Hans-CN`。
  这个方案过于脆弱，无法覆盖 `en-GB`、`zh-TW`、历史设置兼容和 UI 显示问题。

### Decision 2: compareKey 采用“业务语义优先”的 canonicalization 规则

比较层使用如下归一化规则：

- `zh`、`zh-CN`、`zh-SG`、`zh-Hans`、`zh-Hans-CN` → `zh-Hans`
- `zh-TW`、`zh-HK`、`zh-MO`、`zh-Hant`、`zh-Hant-HK` → `zh-Hant`
- `en-*` → `en`
- `ja-*` → `ja`
- `ko-*` → `ko`
- `ru-*` → `ru`
- `fr-*` → `fr`
- `de-*` → `de`
- `es-*` → `es`
- 无法确定 → `unknown`

其中中文是唯一必须在比较层保留 script 差异的语言，因为简繁体在本产品的翻译语义中属于不同目标语言。其他当前暴露的语言先按主语言折叠，后续如果未来引入像塞尔维亚语这类脚本决定书写系统的语言，再扩展相同机制。

选择原因：

- 与 Flutter/CLDR 的中文 script 语义一致。
- 能消除当前最核心的误判来源，又不会让 compareKey 过细导致不必要的误报。

备选方案：

- 所有语言都只比较主语言。
  这会丢失中文简繁差异，无法满足现有目标语言选择中的 `zh` 与 `zh-Hant` 语义。

### Decision 3: 源语言检测改为分层管线，并允许返回 unknown

源语言检测采用分层策略：

1. 先做脚本级快速判定：
   - 平假名/片假名 → `ja`
   - Hangul → `ko`
   - Cyrillic → `ru`
   - CJK dominant → 进入中文 script 细分
   - Latin dominant → 进入拉丁语言判定
2. 中文 script 细分使用简繁专属字计分，输出 `zh-Hans`、`zh-Hant` 或 `unknown`
3. 拉丁语言分支面向当前目标语言范围给出轻量判定，优先识别 `en`，并为 `fr`、`de`、`es` 保留可扩展入口
4. 文本过短、信号冲突或置信度不足时返回 `unknown`

选择原因：

- 业务最关心的是“是否该提醒/自动翻译”，而不是通用语言学精度。
- `unknown` 比误判更安全，尤其适用于短文本、混排正文和引用较多的文章。

备选方案：

- 继续维持当前启发式检测器，只输出粗粒度标签。
  无法区分中文简繁，也无法为等价标签比较提供稳定输入。
- 引入重量级外部语言识别服务。
  成本和复杂度过高，不符合当前离线/本地判断诉求。

### Decision 4: 设置持久化和跟随系统语言统一走 canonicalization

下列入口都要通过统一 canonicalization 流程：

- `AppSettings.localeTag`
- `TranslationAiSettings.targetLanguageTag`
- `disabledTranslationReminderLanguages`
- 跟随系统语言时由 `PlatformDispatcher.instance.locale` 推导出的运行时目标语言

存储层允许保留兼容输入，但运行时读出后必须转换为统一 canonical key，并在安全时回写修正后的设置，避免历史标签长期污染运行时。

选择原因：

- 如果只在 Reader 逻辑里补救，历史设置和其他模块仍会持续产出不一致语言标签。
- 统一入口后，UI、翻译提供方映射和提醒判断可以共享同一套数据契约。

### Decision 5: 语言展示和 provider 映射从 compareKey 派生

显示名称不再直接基于 raw tag 查表，而是基于 canonical key 显示：

- `zh-Hans*` → 简体中文
- `zh-Hant*` → 繁體中文
- `en-*` → English
- `ja-*` → Japanese
- `ko-*` → Korean
- `ru-*` → Russian
- `fr-*` → French
- `de-*` → German
- `es-*` → Spanish

provider 目标码统一从 canonical key 映射：

- Google: `zh-Hans` → `zh-CN`, `zh-Hant` → `zh-TW`
- Bing: `zh-Hans` → `zh-Hans`, `zh-Hant` → `zh-Hant`
- DeepL: `zh-Hans` → `ZH-HANS`, `zh-Hant` → `ZH-HANT`
- Baidu: `zh-Hans` → `zh`, `zh-Hant` → `cht`
- 其他语言默认映射为其主语言代码

选择原因：

- 既保证 UI 不再暴露技术性 raw tag，也保证 provider 输入稳定。
- provider 层继续保留差异化映射，但其上游输入改为统一、可预测的 canonical key。

## Risks / Trade-offs

- [中文 script 检测在短文本上仍可能不稳定] → 对短文本或低置信度场景返回 `unknown`，并禁止基于 `unknown` 弹提醒或触发自动翻译。
- [拉丁语言轻量检测容易把 `fr/de/es` 误判成 `en`] → 第一阶段先保证中文与已覆盖脚本语言正确，拉丁语言分支采用保守策略，不足以确认时返回 `unknown`。
- [设置自动回写可能影响历史配置兼容] → 仅在 canonicalization 无损或与既有语义完全等价时回写，并保留对旧 tag 的读取兼容。
- [多个模块各自维护 locale 解析逻辑] → 本次统一抽取语言身份工具，Reader、设置、provider 映射与通知/运行时 locale 处理尽量复用同一入口。
- [应用本身只支持有限 UI locale] → Reader AI 子系统需要为跟随系统语言增加支持集 fallback，避免未支持 locale 直接进入本地化 lookup。

## Migration Plan

1. 新增语言身份工具层与 compareKey 规则，并保持旧 tag 输入兼容。
2. 将设置读取、目标语言推导、语言提醒判断、自动翻译触发和语言名展示切换到 compareKey。
3. 为翻译 provider 映射改用 canonical key 输入，验证现有 provider 兼容性。
4. 对历史设置执行无损 canonicalization，并在成功加载后做 best-effort 持久化修正。
5. 增补回归测试后再开启完整 Reader 行为验证。

回滚策略：

- 如果上线后发现 compareKey 规则存在误杀，可回退到旧版本实现；由于本次 canonicalization 仅做语义等价折叠，不涉及不可逆的数据结构迁移，回滚风险可控。

## Open Questions

- 拉丁语言分支是否在本次一次性覆盖 `fr/de/es` 的轻量检测，还是先以 `unknown` 保守处理并仅保证现有脚本语言稳定？
- 是否需要把同一套语言身份工具同时下沉到通知 locale 处理与 App 根级 locale fallback，进一步消除仓库内重复的 locale 解析逻辑？
