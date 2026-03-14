## Why

当前仓库虽然已经有一定数量的单元和 widget 测试，但高风险模块缺少覆盖真实用户流程的高层保护网。阅读页、AI 摘要与翻译状态机、后台同步与 outbox、AI 服务设置页、订阅详情面板都承载跨层逻辑，一旦后续重构 UI、同步流程或 AI 编排，很容易出现局部改动引发连锁回归而没有及时暴露。

## What Changes

- 为最复杂且最容易连锁回归的模块建立分层测试保护网，优先覆盖阅读页、AI 状态机、后台同步与 outbox、AI 服务设置页、订阅详情面板。
- 新增能够验证真实用户行为和关键状态迁移的高层测试，而不是仅保留应用可启动或性能基准类测试。
- 明确哪些链路应使用 widget test、provider/service 级测试与 integration test，以兼顾覆盖率、执行速度和稳定性。
- 为后台同步相关模块补齐可测试的依赖注入边界，避免关键链路因强耦合而长期无法验证。

## Capabilities

### New Capabilities
- `critical-workflow-test-coverage`: 为高风险用户流程定义必须具备的回归测试覆盖，包括阅读、AI 编排、后台同步、outbox 刷新与关键设置交互。

### Modified Capabilities
None.

## Impact

- 受影响代码主要位于 `test/`、`integration_test/`、`lib/widgets/reader_view.dart`、`lib/providers/article_ai_providers.dart`、`lib/providers/outbox_flush_providers.dart`、`lib/services/background/background_sync_service.dart`、`lib/ui/settings/tabs/translation_ai_services_tab.dart`、`lib/ui/settings/subscriptions/settings_detail_panel.dart` 及相关 provider/service 注入层。
- 不引入新的运行时外部依赖，但会扩大测试基建和 fake/stub 的使用范围。
- 现有 `test/app_smoke_test.dart` 与 `integration_test/category_query_benchmark_test.dart` 将继续保留，但不再被视为关键链路保护的主要手段。
