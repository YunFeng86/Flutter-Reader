## 1. Shared Sync Assembly

- [x] 1.1 盘点并抽取前台 provider 图与 `BackgroundSyncRunner` 共同使用的 `Dio`、缓存、提取器、通知与 sync service 构造逻辑，形成共享 builder/factory 边界
- [x] 1.2 重接 [lib/providers/service_providers.dart](/Users/yun/Workspace/Fleur/lib/providers/service_providers.dart) 使相关 providers 委托给共享装配工厂而不改变现有业务接口
- [x] 1.3 重接 [lib/services/background/background_sync_service.dart](/Users/yun/Workspace/Fleur/lib/services/background/background_sync_service.dart) 使后台 runner 使用同一套装配规则，并保留现有测试 seam

## 2. Runtime Lifecycle Orchestration

- [x] 2.1 引入独立的 runtime host/bootstrap 边界，承接通知 tap 注册、通知初始化、权限请求、locale bridge 同步与 controller 激活
- [x] 2.2 清理 [lib/app/app.dart](/Users/yun/Workspace/Fleur/lib/app/app.dart) 中直接执行的启动副作用，让 `build()` 只保留渲染声明与必要的数据传递
- [x] 2.3 调整 runtime-scope 与 account-scope 的服务边界，确保账号切换或重建不会仅因 scope 重建而重复触发启动副作用

## 3. Best-Effort Failure Policy

- [x] 3.1 识别通知、后台调度、bridge 与 gating 链路中的泛化 `catch (_) {}`，区分 unsupported 分支与异常降级分支
- [x] 3.2 为非致命但异常的 runtime 失败补充一致的 warning/error 日志上下文，同时保留主流程不中断
- [x] 3.3 收敛剩余关键路径中的静默吞错，确保“可跳过”不再等同于“不可观测”

## 4. Regression Protection And Verification

- [x] 4.1 为 runtime orchestration 新增或更新测试，覆盖 rebuild 不重复触发副作用、账号切换下的绑定重连，以及共享装配配置一致性
- [x] 4.2 扩展后台 runner / sync controller 相关测试，验证前后台共享装配后现有调度与刷新语义不回退
- [x] 4.3 运行必要的静态检查与测试，并执行 `openspec status --change centralize-runtime-orchestration` 确认 artifacts 完整、ready for apply
