## Why

上一次边界校准 change 已经把平台支持、benchmark 口径和基线文档一致性写进规范，但仓库里仍残留少量未收口的事实漂移：`runtime-orchestration` 基线 spec 还保留 `Purpose: TBD`，`pubspec.yaml` 的仓库链接也与当前真实远端不一致。继续带着这些尾巴演进，会削弱 OpenSpec 作为“单一事实来源”的可信度。

## What Changes

- 补齐 `runtime-orchestration` 基线 spec 的正式 Purpose 文案，移除归档后遗留的占位文本。
- 统一仓库公开元数据中的 canonical 仓库与 issue 链接，使 `pubspec.yaml`、README 与当前 Git 远端表达同一事实。
- 明确项目边界契约也约束仓库级元数据一致性，而不仅是平台支持矩阵和 benchmark 文案。
- 将本次工作限定为规范与元数据收尾，不引入新的产品能力，也不改变运行时行为。

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `project-boundary-contract`: 扩展基线一致性要求，覆盖 canonical 仓库元数据链接与归档后规范元数据收尾的验收边界。

## Impact

- 受影响文件主要包括 [pubspec.yaml](/Users/yun/Workspace/Fleur/pubspec.yaml)、[README.md](/Users/yun/Workspace/Fleur/README.md) 与 [spec.md](/Users/yun/Workspace/Fleur/openspec/specs/runtime-orchestration/spec.md)。
- 不引入新的运行时依赖，也不修改应用路由、界面或同步逻辑。
- 该 change 会产出 `project-boundary-contract` 的 delta spec，并为后续实现提供明确的文档校正范围。
