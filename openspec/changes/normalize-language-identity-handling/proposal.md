## Why

Reader 的语言检测、目标语言跟随系统语言、语言名展示、自动翻译触发目前混用了原始 locale tag、规范化 tag 和翻译提供方目标码，导致语义等价的语言标签会被错误判定为不一致。这个问题已经在中文场景中暴露为 `zh` 与 `zh-Hans-CN` 的误报，也会影响带地区或脚本子标签的其他语言兼容性，因此需要尽快建立统一的语言身份处理契约。

## What Changes

- 引入统一的语言身份模型，明确区分原始语言标签、语法规范化结果、语义比较键和提供方目标码。
- 为 Reader 的源语言检测增加面向业务的语言身份输出，优先支持当前翻译功能涉及的中文、英文、日文、韩文、俄文及已暴露的目标语言兼容路径。
- 统一语言不匹配提醒、自动翻译触发、目标语言显示文案的比较与展示逻辑，避免将等价标签错误地显示为不同语言。
- 为跟随系统语言和已持久化设置建立兼容迁移规则，确保历史设置中的 `zh-CN`、`zh-Hans-CN`、`en-GB` 等标签不会继续污染运行时判断。
- 为语言身份归一化和 Reader 翻译提示行为补充回归测试矩阵，覆盖中文简繁、英语地区标签、未知语言与低置信度场景。

## Capabilities

### New Capabilities
- `language-identity-normalization`: 定义应用如何对语言标签、源语言检测结果、显示名称和翻译提供方目标码进行统一归一化与比较。

### Modified Capabilities

## Impact

- 受影响代码主要位于 `lib/utils/language_utils.dart`、`lib/utils/language_detector.dart`、`lib/providers/article_ai_providers.dart`、`lib/services/translation/translation_service.dart`、`lib/services/settings/translation_ai_settings.dart`、`lib/providers/app_settings_providers.dart`、`lib/widgets/reader_view.dart` 及相关测试。
- 影响 Reader 的语言不匹配提醒、自动翻译触发、目标语言展示、翻译设置持久化与兼容迁移路径。
- 不引入新的外部翻译提供方，但会收紧现有语言标签到提供方目标码的映射契约。
