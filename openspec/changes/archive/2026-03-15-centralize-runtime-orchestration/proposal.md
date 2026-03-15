## Why

应用启动期的副作用当前分散在 `main()`、`AccountGate`、`App.build()` 和后台 `Workmanager` 入口之间，导致渲染层承担了通知初始化、权限请求、语言桥同步和 controller 激活等生命周期职责。与此同时，前台与后台各自维护一套同步依赖装配和 best-effort 吞错策略，已经出现配置漂移与失效不可观测的风险，继续演进会让“重建即副作用”和“前后台行为不一致”成为隐性常态。

## What Changes

- 建立统一的运行时编排契约，要求应用启动副作用由稳定的生命周期边界承接，而不是继续依附在 `App.build()` 之类的渲染路径上。
- 建立统一的同步服务装配契约，要求前台 Riverpod provider 图与后台 `BackgroundSyncRunner` 共享同一套依赖构建规则，而不是各自手工 new `Dio`、缓存、提取器、通知等服务。
- 明确 best-effort 副作用的错误处理与可观测性要求，避免通知、后台调度或启动桥接失败时继续以静默吞错的方式退化。
- 为后续实现界定范围：本次 change 聚焦运行时边界和装配一致性，不改变现有通知 payload 语义、同步业务规则或账户/数据库模型。

## Capabilities

### New Capabilities
- `runtime-orchestration`: 规定应用启动副作用的归属边界、前后台共享装配规则，以及 best-effort 运行时失败的最小可观测性要求。

### Modified Capabilities
None.

## Impact

- 受影响代码主要位于 [lib/main.dart](/Users/yun/Workspace/Fleur/lib/main.dart)、[lib/app/app.dart](/Users/yun/Workspace/Fleur/lib/app/app.dart)、[lib/app/account_gate.dart](/Users/yun/Workspace/Fleur/lib/app/account_gate.dart)、[lib/providers/service_providers.dart](/Users/yun/Workspace/Fleur/lib/providers/service_providers.dart)、[lib/providers/auto_refresh_providers.dart](/Users/yun/Workspace/Fleur/lib/providers/auto_refresh_providers.dart)、[lib/providers/background_sync_providers.dart](/Users/yun/Workspace/Fleur/lib/providers/background_sync_providers.dart)、[lib/providers/outbox_flush_providers.dart](/Users/yun/Workspace/Fleur/lib/providers/outbox_flush_providers.dart)、[lib/services/background/background_sync_service.dart](/Users/yun/Workspace/Fleur/lib/services/background/background_sync_service.dart)、[lib/services/notifications/notification_service.dart](/Users/yun/Workspace/Fleur/lib/services/notifications/notification_service.dart) 与相关测试。
- 不要求引入新的第三方依赖，但预计会新增或重组少量 runtime/bootstrap 工厂、provider 或测试缝。
- 本次 change 会新增 OpenSpec capability 规格，并推动实现阶段补齐生命周期与装配一致性的回归测试。
