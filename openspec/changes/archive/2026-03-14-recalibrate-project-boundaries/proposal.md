## Why

仓库当前对“什么算正式支持、什么只是实验状态、什么复杂度值得继续承担”缺少统一口径。`Article.categoryId` 去规范化收益的判断标准已经在两份 benchmark 中分叉，平台支持声明与实际发布准备度不一致，README 与归档后的 OpenSpec 基线也出现了明显漂移，继续在这种前提下演进会放大误判和维护成本。

## What Changes

- 为项目建立统一的边界声明：明确哪些平台属于正式支持、预览支持或未支持，并用可验证的发布/构建条件约束这些声明。
- 为高维护成本优化建立统一的保留标准，明确基准测试的度量口径、阈值表达和“收益不足时应如何处理”的决策路径。
- 校正文档与规范基线，使 README、性能基准说明、发布配置说明和 OpenSpec 归档规格不再互相冲突或保留占位内容。
- 将尚未产品化的平台或尚未定案的优化显式标记为后续工作，而不是继续让仓库默认暗示其已准备就绪。

## Capabilities

### New Capabilities
- `project-boundary-contract`: 规定项目如何声明支持平台、发布准备度、复杂优化的保留标准，以及 README/OpenSpec 等基线文档必须保持一致的要求。

### Modified Capabilities
None.

## Impact

- 受影响内容主要位于 [README.md](/Users/yun/Workspace/Fleur/README.md)、[android/app/build.gradle.kts](/Users/yun/Workspace/Fleur/android/app/build.gradle.kts)、[test/performance/category_query_benchmark_test.dart](/Users/yun/Workspace/Fleur/test/performance/category_query_benchmark_test.dart)、[integration_test/category_query_benchmark_test.dart](/Users/yun/Workspace/Fleur/integration_test/category_query_benchmark_test.dart)、[CLAUDE.md](/Users/yun/Workspace/Fleur/CLAUDE.md) 与 `openspec/` 规格文档。
- 不引入新的运行时依赖，但可能调整文档、构建说明、基准测试文案以及少量发布配置注释/状态声明。
- 本次 change 不直接要求实现 Android 发布链路产品化，也不直接要求移除 `Article.categoryId`；它先建立后续决策应遵循的边界和标准。
