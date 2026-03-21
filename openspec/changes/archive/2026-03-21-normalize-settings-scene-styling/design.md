## Context

Fleur 已经完成全局主题装配、组件主题归一化和基础自适应 shell 改造，但设置页消费层没有同步迁移，导致同一场景内部存在多套实现模式：

- 常规设置 tab 大量重复使用 `Container + BoxDecoration(surfaceContainerLow)` 和局部间距常量
- 设置入口导航手写 `ListTile` 密度、圆角和选中态，没有真正沿用平台 profile 与共享 `ListTileThemeData`
- 订阅设置使用独立的列表、详情和三态配置模式，并直接写入 `primaryContainer`、`secondaryContainer`、`Colors.red` 等局部视觉决策
- stacked / split / multi-pane 下的标题、返回和动作区在不同子页面中各自处理，容易继续分叉

这类问题横跨 `lib/screens/settings_screen.dart`、`lib/ui/settings/tabs/`、`lib/ui/settings/widgets/` 和 `lib/ui/settings/subscriptions/`，属于典型的跨模块 UI contract 收口工作，适合先固化技术设计，再进入实现。

## Goals / Non-Goals

**Goals:**

- 建立一套供所有设置内容复用的 scene-level primitives，统一 section、card、tile、field group 和 destructive action 的呈现方式
- 让设置页优先消费现有 `ThemeData` 组件主题和共享 token，减少 `Container + BoxDecoration + 局部颜色` 的重复实现
- 将订阅设置并入同一套设置场景视觉 contract，同时保留其多列布局和层级信息
- 明确设置页在 stacked / split / multi-pane 模式下的标题、返回、滚动和动作区规则，减少布局分叉

**Non-Goals:**

- 不重做全局导航信息架构，不改变设置项本身的业务语义和存储模型
- 不引入新的主题 marketplace、用户自定义样式系统或额外平台皮肤
- 不修改阅读器场景主题，也不将这次工作扩展为全站 UI 重构
- 不新增服务端依赖、账户协议或数据库 schema 变更

## Decisions

### Decision 1: 为设置页引入共享 primitives，而不是继续按 tab 局部拼装

实现上新增一组设置场景专用的共享组件，用于承载统一的视觉 contract，例如：

- `SettingsPageBody`：负责最大宽度、滚动容器和统一外边距
- `SettingsSection`：负责 section 标题、说明文案和段落间距
- `SettingsCard`：承接设置块的表面、边界、内边距和子项分隔
- `SettingsActionTile` / `SettingsValueTile` / `SettingsToggleTile`：承接常见的动作项、值展示项和开关项
- 必要时为订阅设置补充 `SettingsInlineGroup` 或 `SettingsDetailHeader`

这样可以让常规 tab 和订阅设置都复用同一层语义组件，而不是在每个页面继续手写 `Container`、`ListTile` 和状态色。

**Alternatives considered**

- 继续只做局部重构：改动最小，但会保留重复样式实现，后续新增设置项仍会继续分叉
- 直接把所有设置页面都塞进单一大 widget：短期看似统一，长期会让结构失控、难以维护

### Decision 2: 视觉 contract 以现有 ThemeData 和 token 为底座，settings primitives 只做薄封装

设置 primitives 不重新发明颜色和基础形状，而是优先消费已存在的：

- `CardThemeData`
- `ListTileThemeData`
- `InputDecorationThemeData`
- `FleurSurfaceTheme` / `FleurStateTheme`
- 平台 profile 的密度与滚动条策略

只有设置场景特有的层级关系，例如 section 间距、card 内 divider、destructive emphasis，才在 primitives 中做轻量约束。这样既能让设置页归一，也不会绕开已经建立好的主题基础设施。

**Alternatives considered**

- 为设置页单独再造一套颜色/圆角常量：会复制主题系统，和既有 UI foundation 方向冲突
- 完全裸用原生组件不加封装：虽能减少组件数，但无法表达设置场景的稳定布局和层级规则

### Decision 3: 订阅设置保留多 pane 结构，但视觉上并入同一 settings scene

订阅设置的信息密度和交互路径与普通 tab 不同，因此不推翻其 `tree/list/detail` 结构；改造重点是让其视觉壳层和常规设置页一致：

- global/category/feed 详情统一进入 `SettingsPageBody + SettingsSection + SettingsCard`
- 三态开关、过滤输入、User-Agent 输入和危险操作统一走共享 tile/field 模式
- 分类列表、Feed 列表和树视图的选中态、悬停态、空态优先继承共享列表主题，而不是直写 `primaryContainer`/`secondaryContainer`

这样可以保留订阅设置的效率和层级，同时消除它作为“第二套设置系统”的割裂感。

**Alternatives considered**

- 完全把订阅设置改成普通单栏表单：一致性更强，但会牺牲订阅管理的效率和层级信息
- 保持订阅设置完全独立：实现最省事，但正是当前样式未归一的主要来源

### Decision 4: 明确设置场景的自适应标题和动作区规则

设置页需要在窄宽度、嵌套详情和多列布局中共享一致的页面语义：

- stacked 模式下由外层或当前详情页负责唯一标题，避免双标题
- split / multi-pane 模式下保留左侧导航与右侧详情，但统一详情区的顶部留白、标题样式和内容容器
- 对横向动作区采用可换行、可折叠或 icon-only 降级策略，避免窄宽度下溢出

这些规则将作为 settings scene contract 的一部分固化下来，而不是由每个 tab 自行决定。

**Alternatives considered**

- 完全依赖当前每页各自判断 `showPageTitle`：能工作，但难以保证后续页面新增时的一致性
- 统一强制单栏：会降低桌面端效率，也与现有 pane 模式方向不符

## Risks / Trade-offs

- [设置页出现较大视觉 diff] → 通过先抽共享 primitives、再逐页迁移的方式控制回归面
- [抽象过度导致简单页面也变复杂] → primitives 仅覆盖高频模式，保留少量组合自由度，不做过深封装
- [订阅设置在并轨后损失信息密度] → 保持其多列结构不变，只统一表面、标题、状态和详情表达
- [窄宽度适配规则仍有遗漏] → 在实现阶段补充 widget test 和手工巡检，重点覆盖 stacked detail 与长文案动作区

## Migration Plan

1. 新增设置页共享 primitives，并让其消费现有主题与 token。
2. 迁移设置入口导航和常规 tab，去除重复的局部 `Container + BoxDecoration` 样式。
3. 迁移订阅设置详情面板、列表和树视图，使其进入统一的 settings scene contract。
4. 校准 stacked / split / multi-pane 下的标题与动作区规则，并补充验证。

回滚策略：

- 共享 primitives 以增量接入的方式替换现有页面，出现回归时可以逐页回退，不影响业务数据和设置模型。

## Open Questions

- 是否需要在本次实现中顺手把设置页常用 dropdown 统一迁移到更现代的 `DropdownMenu`/封装组件，还是先只收口视觉层？
- 订阅设置树视图在桌面端是否需要补充更明确的 hover affordance，还是仅依赖共享 `ListTileThemeData` 即可满足需求？
