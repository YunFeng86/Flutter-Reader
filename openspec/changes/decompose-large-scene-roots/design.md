## Context

Fleur 已经完成主题、自适应布局、阅读器场景和动效基线的系统化重构，但对应的高层场景根组件也因此持续吸收了更多职责。当前 `ReaderView` 同时承担文章/翻译监听、自动标记已读、阅读进度恢复、长文分块渲染、搜索导航、桌面上下文菜单、自动滚屏、图片预览和设置弹层；`Sidebar` 同时承担导航树渲染、选择命令、订阅与分类管理、导入导出和桌面/移动弹层差异；`HomeScreen` 同时承担命令编排、快捷键绑定、三套布局分支和 reader/list/sidebar 嵌入策略。

这类复杂度并不是错误实现的结果，而是上一轮 UI 系统化改造后自然形成的集成点。但如果继续在这些场景根上直接叠加功能，后续工作会越来越依赖少数巨型文件，重构风险会持续升高。当前仓库已经具备较完整的 analyze / test 基线，因此现在适合在行为仍稳定时主动收紧职责边界。

约束条件：

- 不改变现有路由路径、页面信息架构和主要用户可见行为。
- 不引入新的业务数据模型、存储格式或同步协议变更。
- 不把所有局部状态一律提升到 Riverpod；仅在跨组件共享或可测试性明确受益时上提。
- 重构后必须保持阅读器、侧栏和首页关键交互仍能通过既有和新增测试验证。

## Goals / Non-Goals

**Goals:**

- 让 `ReaderView`、`Sidebar` 和 `HomeScreen` 回到清晰的场景装配职责，而不是继续承担所有状态与工作流。
- 为 Reader 建立按责任分离的子系统边界，使阅读进度、长文分块、搜索跳转和桌面选择交互能够独立演进。
- 为 Sidebar 建立“树渲染 vs 选择命令 vs 管理动作”的分层，让桌面菜单和移动底部弹层复用同一动作层。
- 为 HomeScreen 建立共享场景命令与快捷键绑定，减少不同布局分支中的重复 orchestration。
- 保持现有测试可继续覆盖关键行为，并为新增边界补足更聚焦的回归验证。

**Non-Goals:**

- 不在本次变更中引入新的阅读器功能、导航目的地或设置项。
- 不重新设计主题 token、视觉样式或断点策略。
- 不把 Reader、Sidebar、Home 的所有逻辑统一迁移为全局 provider 网络。
- 不进行业务域模型重命名、数据库迁移或同步层协议调整。

## Decisions

### Decision 1: 采用“场景根装配层 + 协调器/动作层 + 展示子组件”的分层模式

本次重构以场景为单位建立三层结构：

- 场景根：负责依赖装配、生命周期挂接、布局分支选择和高层命令接线
- 协调器/动作层：负责非纯渲染职责，例如 Reader 的进度恢复或 Sidebar 的订阅管理动作
- 展示子组件：负责 tree、pane、header、overlay、dialog 等具体 UI

这样做的核心目标不是“拆文件”，而是让复杂度按责任归位。场景根仍然保留装配权，但不再直接承载所有子系统细节。

**Alternatives considered**

- 继续沿用大文件 + helper method：文件会更碎，但状态和耦合不会真正下降。
- 把所有逻辑都提升到 Riverpod：会把巨型 widget 问题转移为巨型 provider 图，且不适合承载强 widget lifecycle 语义的滚动与选择状态。

### Decision 2: Reader 优先拆为局部生命周期拥有的多个子系统，而不是立即全局化

`ReaderView` 的复杂度主要来自多个强耦合、强生命周期的局部子系统。设计上优先拆为若干由 Reader 场景拥有的协作对象或局部模块，例如：

- article / translation session coordination
- progress persistence and restoration
- chunked body viewport anchoring
- search navigation
- desktop selection and context actions
- scene scaffold / dialogs / media presentation

这些边界中的很多状态天然依赖 `ScrollController`、`GlobalKey`、`SelectionAreaState`、`OverlayEntry` 或当前 article id，因此默认保持在 Reader 场景局部 ownership 下，而不是先抽成全局 provider。

**Alternatives considered**

- 一次性把 Reader 行为全部抽成 provider/notifier：可测试性表面上提高，但会模糊 widget lifecycle 与 platform interaction 的所有权。
- 保持 Reader 单文件不动，只补测试：能延后风险，但无法阻止复杂度继续累积。

### Decision 3: Sidebar 引入共享动作 facade，并让桌面/移动弹层仅作为 presenter

Sidebar 中真正需要复用的不是 widget，而是动作流程。设计上将分类为：

- tree rendering and section composition
- selection commands (`all` / `feed` / `category` / `tag`)
- management actions (rename, move, delete, refresh, offline cache, import/export)
- platform-specific presenters (desktop menu, mobile sheet, dialogs)

桌面 `MenuAnchor` 和移动端 `ModalBottomSheetRoute` 继续保留，但它们只负责呈现入口，不再各自持有一套业务分支。这样可以减少未来新增动作时在多个 UI 分支重复接线。

**Alternatives considered**

- 按视觉区域拆 Sidebar 文件，但保留每个区域自己调用 repo/service：重复的流程仍会继续存在。
- 把所有 Sidebar 动作直接并入现有通用 `SubscriptionActions`：会让该文件继续膨胀，并模糊 Sidebar 特有的选择与展示语义。

### Decision 4: HomeScreen 抽离共享命令与快捷键绑定，让布局分支只关心 pane 组合

`HomeScreen` 的问题不是状态面最重，而是命令和快捷键在不同布局分支里重复出现。设计上将：

- 抽离共享的 home scene commands，例如 refresh all、mark all read、next/prev article、toggle unread、toggle read、toggle star、jump to search
- 抽离共享 shortcut/action wiring
- 将 desktop / multi-column / compact 布局分支改为消费同一套 commands，而不是重复编排 repo/service 调用

这样做可以让布局修改不再隐式复制业务命令逻辑。

**Alternatives considered**

- 仅提取私有函数并保留在 `HomeScreen`：能降低一点视觉噪音，但不能解决布局分支之间的重复 orchestration。
- 先重写整个 home scene 信息结构：风险过大，也超出本次“职责分解”的目标。

### Decision 5: 重构以“行为保持”为前提推进，并用现有关键测试作为护栏

本次变更是结构性重构，不追求用户可见行为变化。实现顺序以“先建立新边界，再逐步迁移使用方”为原则，并要求验证以下关键行为不退化：

- Reader 的自动标记已读、翻译与搜索同步、阅读进度恢复、长文渲染与桌面选择菜单
- Sidebar 的 feed/category/tag 选择、桌面/移动管理动作、导入导出入口
- HomeScreen 的 refresh、mark all read、keyboard shortcuts、pane 切换和 reader 嵌入策略

**Alternatives considered**

- 一次性大改三个场景并顺手调整行为：风险过高，出问题时难以定位。
- 只做结构拆分不补回归测试：会让后续重构失去可信护栏。

## Risks / Trade-offs

- [Reader 重构过程中丢失隐式行为] → 先围绕当前关键工作流补齐或收紧测试，再迁移子系统。
- [新抽象过多导致认知负担转移] → 只引入高内聚边界，避免为了“纯粹”而过度拆分成过多小对象。
- [Sidebar 动作层与现有通用 action 工具重复] → 明确 Sidebar action facade 只承载导航选择与订阅管理流，不复制跨场景通用基础能力。
- [Home 命令抽离后布局和命令仍相互牵制] → 以 command object / callback bundle 的形式共享，而不是让布局组件直接读 repo/service。
- [迁移期间文件数量增加但质量没有提升] → 每一阶段都要求旧入口的职责明显收缩，否则不视为完成。

## Migration Plan

1. 先定义新的场景层次和文件布局，建立 Home commands、Sidebar actions、Reader subsystem 的目标边界，但不改变路由和外部入口。
2. 优先迁移 `HomeScreen` 的共享命令与快捷键绑定，使布局分支先停止复制 orchestration。
3. 迁移 `Sidebar` 的选择命令与管理动作，让桌面菜单和移动底部弹层消费同一动作层。
4. 以增量方式迁移 `ReaderView`：先拆 session / progress，再拆 chunked body / selection actions / dialogs，避免一次性打散所有交互。
5. 完成后运行 `flutter analyze`、相关 widget/provider tests，并对关键 reader/sidebar/home 流程做手工回归。

回滚策略：

- 新边界保持与现有路由和调用入口兼容，出现问题时可按场景逐块回退，不需要伴随数据迁移或 public API 回滚。
- Reader、Sidebar、Home 的重构分阶段提交时，可在单个场景范围内撤销，而不影响其他场景已完成的结构收敛。

## Open Questions

- Reader 子系统的最终文件归属更适合落在 `lib/widgets/reader_*` 还是 `lib/ui/reader/` 目录族中？
- Sidebar action facade 是否应在首轮就抽出可测试接口，还是先保留为场景私有实现并在第二轮再稳定 API？
