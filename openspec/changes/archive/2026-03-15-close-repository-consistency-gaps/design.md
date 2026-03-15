## Context

当前仓库已经通过 `project-boundary-contract` 约束平台支持声明、benchmark 解释口径和基线文档一致性，但一次归档后的收尾遗漏仍然存在：`openspec/specs/runtime-orchestration/spec.md` 留下了 `Purpose: TBD`，而 `pubspec.yaml` 的 `homepage`、`repository`、`issue_tracker` 仍指向旧的仓库所有者。由于这些文件都会被贡献者、包元数据读取方和后续 change 当作事实来源，残留漂移会让“规范要求已建立”与“仓库事实已收敛”之间继续脱节。

这次 design 不是在设计新架构，而是在定义一套足够小且可重复执行的收尾策略：如何识别 canonical 仓库事实、如何同步更新基线元数据，以及如何避免再次归档后留下占位文本。

## Goals / Non-Goals

**Goals:**
- 明确此次 change 的 canonical 事实来源，避免实现时再次凭感觉更新链接或 Purpose 文案。
- 把仓库元数据链接纳入 `project-boundary-contract` 的一致性覆盖范围。
- 将实现范围控制在文档、包元数据和 OpenSpec 基线收尾，不触碰运行时逻辑。

**Non-Goals:**
- 不在本次 change 中重新设计平台支持矩阵或 benchmark 阈值。
- 不修改 `runtime-orchestration` 的 requirement 行为，只补齐其基线元数据。
- 不引入新的自动化工具或发布流程来管理仓库 metadata。

## Decisions

### 1. 以当前 Git 远端 `origin` 作为 canonical 仓库端点

实现时将本地仓库当前配置的 `origin` 视为 canonical repository source of truth，用它校正文档和 `pubspec.yaml` 中的公开链接，而不是继续让 README 或历史 package metadata 彼此校验。

原因：
- `origin` 是当前工作副本实际连接的远端，最接近“本仓库当前归属”的事实。
- README 和 `pubspec.yaml` 都是消费者视角文档，适合作为同步目标，不适合作为事实源彼此反推。

替代方案：
- 方案 A：以 README 为准，再把其他文件向 README 对齐。
  放弃原因：README 本身就是这次需要校验的一部分，不能再同时充当校验基准。

### 2. 通过修改现有 `project-boundary-contract` requirement 承接本次范围

本次 change 不新建 capability，而是对已有 `project-boundary-contract` 做 requirement 级扩展，把“canonical 仓库链接一致性”明确纳入“基线工件完整且不冲突”的定义里。

原因：
- 问题本质仍然是“仓库边界表达一致性”，与现有 capability 完全同域。
- 新建 capability 会让后续贡献者误以为这是独立功能，而不是边界契约的细化。

替代方案：
- 方案 A：新增一个专门的 metadata capability。
  放弃原因：范围太窄，且会把同一类一致性约束拆散到多个 spec 中。

### 3. 将 runtime spec 的 Purpose 收尾视为基线修复，而非 requirement 变更

`runtime-orchestration` 这次只修 Purpose 文案，不调整 requirement 内容，也不新增运行时场景。实现阶段应把它视为文档基线修复，避免误改行为性规范。

原因：
- 当前问题是占位文本残留，不是运行时契约定义错误。
- 将其错误升级为 requirement 变更会扩大 change 范围，造成不必要的 specs 噪音。

替代方案：
- 方案 A：为 `runtime-orchestration` 再写一个 delta spec。
  放弃原因：不会带来新的行为约束，只会增加归档负担。

## Risks / Trade-offs

- [canonical 远端在后续再次迁移] → 仍以当次实现时的 `origin` 为准，并让 `project-boundary-contract` 要求后续变更同步更新 package/documentation 链接。
- [只修基线文件，遗漏其他零散引用] → 实现任务中显式检查 README、`pubspec.yaml` 与相关 OpenSpec 基线文件，至少覆盖当前对外可见的主入口。
- [把 metadata 收尾写成 spec 变更后显得“过重”] → 通过沿用现有 capability 控制 scope，避免把这类 change 演变成新的流程体系。

## Migration Plan

1. 确认当前 `origin` 指向的 canonical 仓库与 issue 地址。
2. 更新 `project-boundary-contract` delta spec，补入 canonical 仓库元数据一致性的 requirement 内容。
3. 在实现阶段同步修正 `pubspec.yaml` 仓库相关链接，并补齐 `runtime-orchestration` 的 Purpose 文案。
4. 复查 README、package metadata 和 OpenSpec 基线，确认已不存在旧仓库所有者链接或 `TBD` 占位文本。

回退策略：
- 如果实现时发现 canonical 仓库归属本身存在未决迁移，则保守暂停 metadata 改动，只保留 spec 与任务说明，不在事实未确认时落盘错误链接。

## Open Questions

- README 是否还需要显式增加“canonical repository”说明，还是保持现有 issue 链接即可。
- 除 `pubspec.yaml` 外，是否还有发布脚本、CI 配置或文档徽章引用了旧仓库地址，需要在实现时一并盘点。
