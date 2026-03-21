## 1. 语言身份基础层

- [x] 1.1 在语言工具层引入统一的语言身份模型，明确 raw tag、normalized tag、compare key、display key 与 provider 映射入口
- [x] 1.2 实现 canonicalization 规则，覆盖简体中文、繁体中文、英语及当前已暴露目标语言的地区/脚本变体
- [x] 1.3 为语言名展示增加 canonical name 映射，避免在 Reader 和设置页直接显示 raw locale tag

## 2. 运行时与设置接入

- [x] 2.1 将 `AppSettings.localeTag`、`TranslationAiSettings.targetLanguageTag` 与禁用提醒语言列表切换到统一 canonicalization 流程
- [x] 2.2 为历史设置中的等价语言标签增加兼容读取与 best-effort 持久化修正逻辑
- [x] 2.3 重构 `ArticleAiController` 的目标语言推导、语言不匹配提醒和自动翻译触发逻辑，改为比较 canonical language identity
- [x] 2.4 为跟随系统语言场景增加受支持 UI locale fallback，避免 Reader AI 流程对未支持 locale 直接做本地化 lookup
- [x] 2.5 统一跟随软件语言的默认目标语言推导入口，确保设置页与 Reader 在不受支持系统 locale 下保留同一 canonical target identity

## 3. 源语言检测与翻译提供方映射

- [x] 3.1 将源语言检测升级为分层管线，优先保留日文、韩文、俄文的脚本级判定，并为中文输出 `zh-Hans`、`zh-Hant` 或 `unknown`
- [x] 3.2 为中文增加基于简繁专属字信号的 script-aware 判定，并在低置信度或短文本场景下返回 `unknown`
- [x] 3.3 将翻译 provider 的目标语言映射统一改为消费 canonical target identity，并验证 Google、Bing、DeepL、Baidu 的中文目标码契约
- [x] 3.4 将低置信度源语言检测结果显式收口为 `unknown`，避免以 `null` 表达业务上的未知身份

## 4. 回归验证

- [x] 4.1 为 canonicalization、显示名称与 provider 目标码映射补充单元测试，覆盖 `zh-Hans-CN`、`zh-TW`、`en-GB` 等等价标签
- [x] 4.2 为源语言检测补充测试，覆盖简体中文、繁体中文、脚本明确语言、混合文本与低置信度 `unknown` 场景
- [x] 4.3 为 `ArticleAiController` 增加回归测试，验证语言不匹配提醒和自动翻译不会被等价标签误触发
- [x] 4.4 为 Reader 或设置页增加交互测试，验证目标语言展示不再泄漏 raw tag，且跟随系统语言时行为稳定
- [x] 4.5 为跟随软件语言在系统 locale 回退场景下的设置页展示与 `unknown` 抑制提醒/自动翻译行为补充回归测试
