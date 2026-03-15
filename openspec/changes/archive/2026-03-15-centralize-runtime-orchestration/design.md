## Context

当前应用运行时职责被拆散在多个边界上：`main()` 负责 logger 和后台调度初始化，[AccountGate](/Users/yun/Workspace/Fleur/lib/app/account_gate.dart) 负责账号级 `ProviderScope` 与 Isar 打开，[App.build()](/Users/yun/Workspace/Fleur/lib/app/app.dart#L79) 又直接触发通知点击回调注册、通知初始化、权限请求、语言桥同步，以及多个 `AutoDisposeNotifier` controller 的激活。这样虽然短期可运行，但会把“是否执行副作用”与“是否发生 rebuild”耦合在一起，后续只要主题、语言、路由或账号切换触发重建，就容易让启动行为悄悄重放。

后台同步路径也没有复用前台的组合根。[service_providers.dart](/Users/yun/Workspace/Fleur/lib/providers/service_providers.dart) 通过 Riverpod provider 图组装 `Dio`、缓存、提取器、通知与同步服务；[BackgroundSyncRunner](/Users/yun/Workspace/Fleur/lib/services/background/background_sync_service.dart#L262) 则自己 new 出另一套 `Dio`、`CredentialStore`、`ArticleCacheService`、`NotificationService`、`ArticleExtractor` 与 sync service。两边现在的超时、缓存和通知行为恰好相近，但这只是偶然一致，没有机制保证后续改动不会漂移。

错误处理也呈现同样的边界缺口。项目已有 [AppLogger](/Users/yun/Workspace/Fleur/lib/services/logging/app_logger.dart)，但运行时关键链路里仍存在多处 `catch (_) {}`，尤其集中在通知初始化、权限请求、后台调度初始化与 iOS gating 等 best-effort 分支。结果不是“更稳健”，而是“出问题时更难定位”。

## Goals / Non-Goals

**Goals:**
- 建立一个明确的运行时编排层，让启动期和持续性副作用脱离 `build()` 渲染路径。
- 让前台 provider 图与后台 runner 复用同一套同步依赖构建规则，避免服务装配继续分叉。
- 为 best-effort 运行时失败建立一致的处理策略：不影响主流程，但必须具备最小可观测性。
- 在不改变通知 payload、同步业务语义和账号/数据库模型的前提下，为后续实现提供清晰切分与测试边界。

**Non-Goals:**
- 不在本次 change 中重写 sync service 的业务逻辑或通知展示文案。
- 不把全部服务改成全局 singleton，也不引入新的 service locator 框架。
- 不要求后台 isolate 直接复用完整 Riverpod `ProviderContainer`。
- 不在本次 change 中改变“通知权限何时向用户请求”的产品策略；若需要延后到用户动作触发，可作为后续体验优化单独讨论。

## Decisions

### 1. 引入独立的 runtime orchestration 层，而不是继续依赖 `App.build()` 触发副作用

实现阶段将新增一个不承担 UI 呈现的 runtime host/bootstrap 边界，用生命周期方法或 provider 监听来接住以下职责：
- 通知点击回调绑定与冷启动 tap 分发。
- 通知初始化与权限请求。
- `MacOSLocaleBridge` 与设置变更的同步。
- `autoRefresh`、`outboxFlush`、`backgroundSync` 这类 controller 的激活与保活。

核心要求不是“把代码搬个文件”，而是把副作用从“每次 build 都可能重放”改成“由显式生命周期驱动”。这层可以包裹 `MaterialApp.router` 或位于 `AccountGate` 与 `App` 之间，但 `build()` 本身只负责声明结构，不直接执行运行时动作。

替代方案：
- 方案 A：继续留在 `App.build()`，仅依靠 `NotificationService` 的幂等标记兜底。
  放弃原因：这只能保护单个 service 实例，无法覆盖账号切换后的新实例、controller 激活与未来新增副作用。
- 方案 B：把所有启动动作都挪进 `main()`。
  放弃原因：`router`、账号作用域和用户设置都在 app 运行后才稳定，全部前置到 `main()` 会失去响应式能力。

### 2. 区分 runtime-scope 与 account-scope，对长生命周期服务重新定边界

通知点击分发、启动桥接和类似“应用级”副作用不应绑定在账号级 `ProviderScope` 上，因为 [AccountGate](/Users/yun/Workspace/Fleur/lib/app/account_gate.dart#L162) 会在切换账号时重建整棵 account scope。实现阶段将把这些运行时服务放到更稳定的 runtime scope，或通过专门 host 在账号切换时安全重绑，而不是让它们随着 account scope 被动销毁重建。

这里的关键是“生命周期边界稳定”，不是强行做进程级单例。后台 isolate 仍然会拥有自己的服务实例，但它与前台实例应遵循同样的装配规则，而不是共享同一个对象。

替代方案：
- 方案 A：保留 account-scoped `notificationServiceProvider`，改用更多静态字段保证全局幂等。
  放弃原因：会把生命周期问题继续藏进 service 内部，既难测也难解释。

### 3. 提取共享装配工厂，前台 provider 与后台 runner 都委托给同一套组合根

实现阶段将把当前重复出现的依赖构造逻辑下沉为纯 Dart 工厂/构造函数，例如：
- 共享 HTTP client 构造规则（timeouts、redirect、debug logging）。
- 共享缓存/提取器/通知相关装配。
- 共享 sync service 选择逻辑（local / miniflux / fever）。

Riverpod provider 保留，但变成这些工厂的薄包装；`BackgroundSyncRunner` 不再自己复制 `Dio`、缓存和通知构造，而是调用同样的 builder。这样可以在不把后台路径绑进 UI 容器的前提下，获得“同一配置只有一个事实来源”的效果。

替代方案：
- 方案 A：在后台 isolate 里直接创建一套 Riverpod `ProviderContainer` 复用前台 provider 图。
  放弃原因：会把 UI/前台作用域的 provider 生命周期和后台任务执行耦合，复杂度偏高，且不利于明确平台边界。
- 方案 B：只去重 `Dio`，其余服务继续手工 new。
  放弃原因：真正的风险是装配规则整体漂移，不只是 HTTP timeout 一项。

### 4. 为 best-effort 分支定义“可跳过，但不可静默失明”的错误策略

运行时层会把 best-effort 失败分成两类：
- 明确预期的不可用分支，例如 `MissingPluginException`、平台不支持、后台调度不可用。
- 非预期但可降级的失败，例如通知初始化失败、权限请求异常、调度注册失败、桥接调用异常。

前者可以走显式跳过分支，不中断主流程；后者也不应拖垮启动或同步，但必须记录带上下文的 warning/error，而不是继续泛化为 `catch (_) {}`。这能保持现有“失败不炸 app”的体验，同时让运行时退化变得可诊断。

替代方案：
- 方案 A：把所有 best-effort 失败都提升成 hard failure。
  放弃原因：通知或平台调度失败不值得阻塞主阅读流程。
- 方案 B：继续大量静默吞错。
  放弃原因：已经无法支撑后续排障和行为一致性验证。

### 5. 保留现有 controller/runner 的测试缝，优先做重连线而不是重写业务

仓库已经有 `BackgroundSyncRunner` 的注入 seam 和 sync controller 的 provider 级测试。实现阶段应尽量复用这些基础，把工作重点放在“装配改为共享”和“副作用改为生命周期驱动”，而不是顺势把 controller 或 sync service 全部重写。这样可以把变更风险控制在编排层，而不是扩散到业务规则本身。

替代方案：
- 方案 A：顺手把 auto refresh、background sync、outbox flush 全改成新的统一 runtime manager。
  放弃原因：虽然听起来更整齐，但会把一次边界整理升级成业务重构，范围过大。

## Risks / Trade-offs

- [新增 runtime host 让启动结构看起来更复杂] → 保持 host 职责单一，只做编排，不承载业务逻辑与 UI。
- [将通知等服务从 account scope 抬升后，账号切换时绑定关系更难理解] → 明确区分“应用级副作用服务”和“账号/数据库相关服务”，并通过测试覆盖重绑行为。
- [共享工厂抽象过度，导致 provider 可读性下降] → provider 仍保留语义化命名，只把重复构造逻辑下沉到少量纯函数/工厂对象。
- [补日志后暴露出大量已有平台噪音] → 对明确预期的 unsupported 分支做分类处理，避免误报；只对真正异常的降级失败打 warning/error。
- [实现阶段边做边想把权限请求时机一起优化] → 将权限时机优化标记为后续 UX 决策，本 change 先只处理“不要在 build 里做”。

## Migration Plan

1. 先为 `runtime-orchestration` 建立规格，锁定启动副作用、共享装配和 best-effort 可观测性的验收边界。
2. 增加共享装配工厂，并让前台 provider 与后台 runner 都通过这些工厂构建依赖，同时保持现有业务 API 不变。
3. 引入 runtime host/bootstrap 层，把通知、语言桥和 controller 激活从 `App.build()` 挪走。
4. 清理关键路径中的泛化吞错，将 unsupported 分支和异常降级分支分别改为显式处理与日志记录。
5. 补充/更新测试，覆盖重建不重复触发副作用、前后台共享配置、以及 best-effort 失败可观测这几类回归点。

回退策略：
- 若 runtime host 或共享工厂引入不可接受的集成风险，可先保留新的工厂/日志策略，仅回退 host 接线方式；由于 provider 和 runner 的对外接口保持不变，回退可以局部进行。

## Open Questions

- 通知权限请求是否需要继续保留在冷启动生命周期中，还是后续应该改为设置页/用户显式开启时再请求。
- runtime host 最终更适合放在 `AccountGate` 外层，还是由 `App` 拆成“纯渲染壳 + 生命周期宿主”两部分，这需要结合实现时的 router 依赖再做一次最小化选择。
- 共享装配工厂是按“按服务拆分的小 builder”组织，还是引入一个聚合的 `SyncCompositionContext`/`RuntimeAssembly` 对象，哪种更贴近现有代码风格。
