## Context

当前测试结构以单元测试和少量 widget 测试为主，缺少面向关键用户链路的高层验证。现有 [app_smoke_test](/Users/yun/Workspace/Fleur/test/app_smoke_test.dart) 仅验证应用外壳可以构建，现有 [category_query_benchmark_test](/Users/yun/Workspace/Fleur/integration_test/category_query_benchmark_test.dart) 聚焦性能基准，不覆盖真实交互流程。与此同时，阅读页、AI 状态机、后台同步与 outbox、AI 服务设置页、订阅详情面板都跨越 UI、Provider、存储与网络边界，是最容易在重构时出现连锁回归的区域。

这些模块的可测试性并不完全一致。`ReaderView`、`TranslationAiServicesTab`、`SettingsDetailPanel` 已经建立在 Riverpod provider 上，可以通过 override 注入假数据和 fake service；`ArticleAiController` 依赖也较清晰，适合做 provider 级状态机验证；`BackgroundSyncRunner` 则直接创建 `OutboxStore`、`Dio`、`CredentialStore`、`ArticleExtractor` 等对象，可测试性最弱，需要补最小必要的 seam。

## Goals / Non-Goals

**Goals:**
- 为高风险链路建立一套稳定、可重复、执行成本可控的测试保护网。
- 用最合适的层次覆盖每类风险：UI 编排用 widget test，状态机用 provider/service test，少量真实链路用 integration test。
- 明确关键回归点，并让后续 UI、同步、AI 流程重构能通过测试快速暴露问题。
- 为后台同步链路补充必要的依赖注入边界，使关键分支可被验证而不依赖真实平台环境。

**Non-Goals:**
- 不追求把所有现有模块都补齐端到端测试。
- 不把所有高层测试都放进 `integration_test/`，避免引入执行慢、易波动的测试套件。
- 不改动产品功能定义；本次 change 聚焦测试保护与最小必要的可测试性增强。

## Decisions

### 1. 采用“分层保护网”而不是“全量端到端”策略

选择按风险类型分层补测试：
- `ReaderView`、`TranslationAiServicesTab`、`SettingsDetailPanel` 以 widget test 为主，验证真实交互编排。
- `ArticleAiController`、`OutboxFlushController`、`BackgroundSyncController` 以 provider/service test 为主，验证状态机、调度与退避逻辑。
- `integration_test/` 只保留少量必须经过真实运行时验证的链路，而不是承载主要覆盖职责。

这样做的原因是当前问题核心不是“没有大而全的 E2E”，而是“最危险的跨层逻辑没有稳定回归点”。相比全堆到 integration test，分层测试运行更快、失败定位更准，也更容易在 CI 中长期维持稳定。

替代方案：
- 方案 A：主要补 integration test。
  放弃原因：真实依赖太多，构造成本高，运行慢，排障困难，且无法高效覆盖 AI 状态机与同步退避等细颗粒状态。

### 2. 把关键链路拆成五组测试目标

本次 change 将高风险区域拆为五组明确目标：
- 阅读页核心交互：自动已读、全文提取错误提示、翻译与搜索联动、进度保存与恢复。
- AI 摘要/翻译状态机：缓存命中、未配置错误、语言不匹配提醒、内容变化后的失效与重算。
- outbox 刷新：空队列、flush 失败、flush 成功但无进展、flush 成功且有进展、stall/backoff。
- 后台同步调度：启停条件、频率计算、仅 outbox 待发送时的启用，以及 `BackgroundSyncRunner` 的刷新/flush 分支。
- 设置页交互：AI 服务选择、凭证配置、Prompt 重置、目标语言选择、订阅详情面板的全局/分类/订阅继承逻辑。

这样拆分后，每一组都能映射到独立测试文件和清晰的验收结果，而不是形成一个模糊的“多加点测试”目标。

替代方案：
- 方案 A：按文件逐个补测试。
  放弃原因：文件边界和风险边界不一致，容易补成“测了很多但没测到关键用户路径”。

### 3. 先利用现有 Riverpod override，最小化新增测试基建

优先复用当前 provider 架构提供的注入能力：
- query provider 直接 override 数据流。
- service provider 替换为 fake/stub 实现。
- Reader/AI/设置页相关 store 和 service 尽可能通过现有 provider 注入。

仅在 `BackgroundSyncRunner` 等难测点上增加最小必要 seam，例如把直接创建的依赖包装为可覆盖的工厂或构造参数，而不是大规模重写实现。

替代方案：
- 方案 A：先统一引入一整套测试容器或 mock 框架改造。
  放弃原因：改造面过大，容易把“补保护网”拖成“重搭测试框架”。

### 4. 保留现有 smoke/benchmark，但重新定义其角色

现有 `app_smoke_test.dart` 和 `category_query_benchmark_test.dart` 继续保留，用于最低限度的可构建验证与性能回归观察；但它们不再被当作关键链路保护的主力测试。新的高层测试将承担回归兜底职责。

替代方案：
- 方案 A：删除现有 smoke/benchmark。
  放弃原因：它们仍有价值，只是不能替代关键流程测试。

## Risks / Trade-offs

- [测试范围过大导致落地拖延] → 先锁定五组最高风险链路，避免把 change 扩展成全仓库补测。
- [widget test 过度耦合 UI 文案或布局] → 优先断言关键状态、控件存在与交互结果，减少对脆弱呈现细节的依赖。
- [后台同步链路难以 fake 平台环境] → 先为调度逻辑与 runner 的依赖注入补 seam，再测试平台分支。
- [AI 相关测试容易受异步与节流影响变脆] → 使用可控 fake queue/client/cache，避免真实时间和真实网络。
- [新增测试带来执行时间上升] → 主体放在 widget/provider 层，只把少量必须的真实链路放进 integration test。

## Migration Plan

1. 先新增 `critical-workflow-test-coverage` 规格，固定验收边界。
2. 按“AI 状态机 -> 设置页 -> 阅读页 -> outbox/background sync”的顺序逐步补测试。
3. 在补后台同步测试前加入最小必要的依赖注入 seam。
4. 维持现有 smoke/benchmark 测试并将其与新高层测试一起纳入常规验证。
5. 如果某条新增测试暴露真实缺陷，优先修复缺陷后再稳定测试。

回退策略：
- 如某类高层测试短期内过于脆弱，可先降回更低层级的 provider/service 验证，保留需求目标不变。

## Open Questions

- `BackgroundSyncRunner` 的 seam 是通过构造参数下沉依赖，还是通过 provider/工厂统一接管，哪种更贴合现有代码风格。
- 是否需要补 1 条真正的跨页面 integration flow 来串起“打开文章 -> AI/搜索 -> 返回列表”，还是 widget 级覆盖已经足够。
