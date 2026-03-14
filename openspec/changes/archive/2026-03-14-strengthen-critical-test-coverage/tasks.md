## 1. Test Seams And Shared Harnesses

- [x] 1.1 盘点阅读页、AI、设置页、同步链路现有 provider override 能力，并为缺失的高风险依赖补最小必要的 fake/seam 方案
- [x] 1.2 为 `BackgroundSyncRunner` 引入可测试的依赖注入边界，使其无需真实平台调度、网络和生产存储即可验证关键分支
- [x] 1.3 提炼新增测试共用的 fake store、fake service 与测试装配辅助方法，避免在多个测试文件中重复搭建环境

## 2. AI And Settings Regression Coverage

- [x] 2.1 为 `ArticleAiController` 新增 provider 级状态机测试，覆盖缓存命中、未配置错误、语言不匹配提醒、内容变化失效与重算
- [x] 2.2 为 `TranslationAiServicesTab` 新增 widget 测试，覆盖翻译提供方选择、目标语言切换、Prompt 重置、DeepLX URL 校验与凭证配置交互
- [x] 2.3 为 `SettingsDetailPanel` 新增 widget 测试，覆盖全局、分类、订阅三级详情分支以及继承/覆盖/回退交互

## 3. Reading And Sync Workflow Coverage

- [x] 3.1 为 `ReaderView` 新增高层 widget 测试，覆盖自动已读、全文提取失败提示、翻译与搜索联动、阅读进度保存与恢复
- [x] 3.2 为 `OutboxFlushController` 和 `BackgroundSyncController` 新增调度测试，覆盖空队列、成功有进展、成功无进展、失败退避与禁用分支
- [x] 3.3 为 `BackgroundSyncRunner` 新增 service 级测试，覆盖 refresh gating、仅 flush outbox、refresh+flush 组合路径与 early return 条件
- [x] 3.4 为 `ReaderView` 补充通过真实底部操作按钮触发的翻译/全文链路测试，避免仅通过直接调用 controller 覆盖
- [x] 3.5 为 `OutboxFlushController` 与 `BackgroundSyncController` 补充 controller/provider 层的真实 wiring 测试，避免仅验证纯决策函数

## 4. Validation

- [x] 4.1 运行新增的 provider/widget 测试并修正不稳定断言，确保关键链路测试可以稳定重复执行
- [x] 4.2 评估是否仍存在必须通过真实运行时验证的关键空白；若存在，则补充最少量的 integration flow 并纳入常规验证
