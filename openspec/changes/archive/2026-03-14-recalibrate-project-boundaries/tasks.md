## 1. Boundary Audit And Canonical Criteria

- [x] 1.1 盘点 README、发布配置、benchmark 注释、CLAUDE.md 与 OpenSpec 基线中涉及平台支持、发布准备度和 `Article.categoryId` 去规范化收益判断的现有表述
- [x] 1.2 为各目标平台确定正式支持、预览支持、未支持的统一分层，并确定仓库后续统一使用的 benchmark 主度量、阈值表达和低于阈值时的处理动作

## 2. Repository-Facing Boundary Alignment

- [x] 2.1 更新 README 的平台矩阵、支持说明以及运行/构建命令分组，使支持状态与当前真实构建/发布准备度一致
- [x] 2.2 统一 `test/performance/category_query_benchmark_test.dart`、`integration_test/category_query_benchmark_test.dart` 及相关说明中的 benchmark 口径、阈值语言和复盘提示
- [x] 2.3 校正会误导支持边界的配置注释或辅助文档表述，例如 Android release signing 现状与 Web 当前阻塞原因

## 3. OpenSpec Baseline Cleanup

- [x] 3.1 修复当前受影响的 OpenSpec 基线文档中的占位文本和冲突表述，包括归档规格中的 `Purpose` 等必填元信息
- [x] 3.2 将仍未产品化的平台和仍待复盘的优化明确记录为后续工作或预览状态，避免 change 完成后再次形成隐性承诺

## 4. Verification And Closure

- [x] 4.1 重新执行必要的事实核验，确认平台支持声明、benchmark 解释和基线文档在仓库内只剩一种表述
- [x] 4.2 运行 `openspec status --change recalibrate-project-boundaries` 并检查最终 diff，确认实现所需 artifacts 完整且不存在残留占位或自相矛盾的边界声明
