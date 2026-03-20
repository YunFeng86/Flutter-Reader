## Context

Fleur 当前已经具备跨平台运行入口、基础自适应布局和部分桌面交互能力，包括桌面标题栏、三栏到单栏的渐进式 pane 布局、桌面滚动条、阅读器文本选择以及若干局部显现动画。但这些能力主要分散在 `lib/theme/`, `lib/ui/`, `lib/widgets/` 和 `lib/screens/` 中，视觉系统仍然依赖 `ColorScheme.fromSeed(...)`、局部 `surfaceContainer*` 选色和 widget 内联样式，导致以下问题：

- 同一产品在导航、侧栏、列表、阅读器之间缺少统一但有区分度的场景语义。
- 桌面与移动端虽然共享布局逻辑，但在密度、hover、tooltip、状态反馈等输入模型差异上没有形成稳定的设计 contract。
- 阅读器承担产品核心价值，却仍然主要作为“HTML 内容容器”存在，而不是独立的阅读场景。
- 动效存在于若干局部组件中，但尚未形成统一的 duration、curve、触发条件与可访问性降级策略。

该改造需要覆盖主题系统、布局结构、阅读器场景和动效策略，属于明确的跨模块设计变更，适合在编码前先固化技术决策。

## Goals / Non-Goals

**Goals:**

- 建立一套 Fleur 专属但跨平台统一的主题装配结构，覆盖语义 surface、状态 token、组件主题归一化和阅读器场景主题。
- 保持单一产品身份，不为 Windows、macOS、Linux、Android、iOS 分别复制整套视觉皮肤，而是在统一骨架上做平台级微调。
- 让首页导航、侧栏、文章列表和阅读器共享同一套视觉 contract，同时保留各自明确的场景语气。
- 为列表显现、状态胶囊、悬浮工具条、搜索浮层和阅读场景切换建立一套可复用的动效基线。
- 在不引入新的服务端依赖和数据模型变更的前提下，为后续 `/opsx:apply` 的实现任务建立可分阶段落地的结构。

**Non-Goals:**

- 不在本次设计中引入全新品牌命名、Logo、插画体系或营销页面视觉语言。
- 不为每个平台实现完全不同的布局结构、导航信息架构或独立设置模型。
- 不在本次设计中新增在线字体依赖、主题 marketplace、用户自定义排版编辑器或复杂的个性化系统。
- 不修改已有的业务域模型、同步协议、AI 任务编排或账户数据结构。

## Decisions

### Decision 1: 主题系统采用“标准组件主题 + ThemeExtension + 场景局部 Theme”的三层结构

`AppTheme` 将继续作为对外入口，但内部拆分为：

- 基础 `ColorScheme` 与平台字体回退生成层
- 标准 Material 组件主题层，如 `NavigationRailThemeData`、`NavigationBarThemeData`、`CardThemeData`、`ListTileThemeData`、`ScrollbarThemeData`、`TooltipThemeData`
- 产品语义扩展层，通过 `ThemeExtension` 提供 `FleurSurfaceTheme`、`FleurStateTheme`、`FleurReaderTheme`
- 场景局部覆盖层，通过 `Theme(data: base.copyWith(...))` 为 Reader 提供独立 scene theme

这样做的原因是：

- 标准组件样式由 `ThemeData` 统一承接，可以减少 widget 内联样式扩散。
- `ThemeExtension` 适合承载 Material 默认语义之外的产品概念，例如 `chrome/nav/sidebar/list/reader/floating` 等 surface。
- Reader 作为强场景，需要在不污染全局控件外观的前提下获得独立 typography 和 surface 语义。

**Alternatives considered**

- 仅继续扩写现有 `app_theme.dart`：实现门槛最低，但会继续放大文件耦合，难以为 Reader 和状态语义建立清晰边界。
- 全部使用 `ThemeExtension`：会让标准 Material 组件失去 `ThemeData` 自带的统一能力，增加消费复杂度。
- 全部使用 widget 局部 `copyWith`：短期灵活，长期会导致样式继续碎片化。

### Decision 2: 采用“统一品牌骨架 + 平台 profile 微调”，而不是每个平台一套皮肤

主题和布局将以统一品牌骨架为主，只在以下维度按平台 profile 做微调：

- `visualDensity` 与组件间距
- hover、tooltip、右键与常显滚动条等桌面输入模型能力
- 标题栏与窗口 chrome 的表现
- 对话框按钮顺序、聚焦反馈和少量控件细节

平台 profile 先分为两组：

- `desktop`: Windows、macOS、Linux
- `mobile`: Android、iOS

如有必要，桌面内部仅对标题栏和少数控件顺序再做平台差异化，不额外复制整套主题。

**Alternatives considered**

- 为每个平台设计独立视觉皮肤：本地体验可能更像原生应用，但维护成本、回归成本和品牌分裂风险过高。
- 完全不做平台微调：会让桌面端显得像放大的移动应用，也无法匹配 hover、右键、滚动条等桌面预期。

### Decision 3: 继续沿用现有自适应 pane 模式，但重构“视觉壳层”和消费 token 的方式

当前 `layout.dart` 和 `LayoutSpec` 已经定义了桌面三栏、两栏、单栏和非桌面多列逻辑。此次改造不推倒这些宽度策略，而是在其上重构以下内容：

- `AppShell` 的导航表面语义
- 侧栏、列表、阅读器之间的 scene surface 分层
- list/reader 空态与选择态的统一表达
- 与 pane 结构匹配的场景边距、标题栏与浮层视觉壳层

这样可以在保留现有路由和 pane 逻辑的同时，获得更稳定的视觉系统。

**Alternatives considered**

- 直接重写导航与 layout 断点：风险较高，容易把视觉优化变成信息架构重写。
- 只改颜色不改视觉壳层：无法解决场景层级不清、空态和阅读器气质不足的问题。

### Decision 4: Reader 作为独立场景主题实现，而不是继续沿用全局表单/设置页语气

Reader 将拥有自己的场景 token 和局部 Theme，包括：

- 标题、日期、摘要卡、正文、引用、代码块的 typography
- 阅读容器、摘要卡、搜索条、底部工具条、选区高亮的 surface/state 语义
- 不同 pane 模式下保持一致的阅读 measure 和浮层对齐

Reader 的设置仍由现有 `ReaderSettings` 承载字体大小、行高和内边距等用户可调项，但这些设置将基于 `FleurReaderTheme` 的默认 contract 运行，而不是直接塑造全局 UI。

**Alternatives considered**

- 继续由全局主题统一处理 Reader：实现简单，但阅读器会继续与设置页、列表项共享相同语气，难以建立核心产品价值感。
- 把 Reader 样式完全迁移到 `ReaderSettings`：会把“产品默认设计”与“用户可调偏好”混在一起，增加心智和实现复杂度。

### Decision 5: 动效采用“隐式优先、显式按需、可访问性降级”的基线

动效系统遵循以下原则：

- 简单属性变化优先使用隐式动画，如 `AnimatedSlide`、`AnimatedOpacity`、`AnimatedContainer`、`TweenAnimationBuilder`
- 只有跨区域协调或分段显现才使用显式控制器，例如列表分段显现、复杂切换或 Hero
- 为常见交互建立少量统一 motion token，例如 `short`, `medium`, `emphasized` 时长与对应 curve
- 当平台通过 `MediaQuery.disableAnimationsOf(context)` 请求禁用或降低动画时，非必要动画必须退化为立即切换或最小 motion

这能减少 ad-hoc 动画带来的风格漂移，也有利于桌面与移动端在性能与可访问性上的一致性。

**Alternatives considered**

- 所有动画都使用显式控制器：自由度高，但复杂度和维护成本过大，不适合作为全局基线。
- 完全不统一动画：短期迭代快，但很容易出现节奏不一致和重复实现。

### Decision 6: 实施顺序采用“基础主题 -> shell/layout -> reader -> motion polish”的渐进式落地

实现分四层推进：

1. 建立主题装配结构和语义 token，但保留现有设置入口和 `AppTheme.light/dark` API。
2. 迁移导航、侧栏、列表和空态消费方式，让它们改读语义 token。
3. 为 Reader 引入局部 scene theme，并统一搜索条、摘要卡、底部工具条等浮层。
4. 收口显现、切换和状态反馈动效，并补充回归测试与截图验证。

这样做可以降低一次性大改 UI 的风险，同时允许每一层都进行独立校验。

**Alternatives considered**

- 一次性重写所有页面：视觉收敛更快，但回归面过大，难以定位问题。
- 只做主题层不推进消费迁移：无法兑现 proposal 中对列表、Reader 和交互反馈的承诺。

## Risks / Trade-offs

- [大范围视觉 diff] → 通过渐进式任务拆分、桌面/移动端分阶段验证和截图回归减少风险。
- [动态取色与新语义 token 冲突] → 保持 `ColorScheme.fromSeed`/dynamic color 作为底层来源，由语义 token 统一转译，而不是直接在业务组件中消费原始 tone。
- [平台差异处理不当导致某一端显得别扭] → 限制 platform profile 仅调整密度、hover、chrome 等少数维度，不复制整套皮肤。
- [Reader 局部 Theme 与全局组件主题冲突] → 只在 Reader 子树局部覆盖必要字段，并明确 Reader 专属 token 的消费边界。
- [动效增加维护负担或影响性能] → 以隐式动画为默认策略，并要求所有显式动画都具备明确收益和 dispose 生命周期。
- [支持矩阵覆盖不足] → 优先验证当前正式支持的 Windows 路径，并对 Android、macOS、Linux 保持预览支持下的最小有效回归。

## Migration Plan

1. 新增主题模块与 `ThemeExtension`，保持 `AppTheme.light/dark` 入口不变。
2. 将现有导航、侧栏、列表、同步胶囊等组件从直接消费原始 `ColorScheme` 迁移为优先消费语义 token 与组件主题。
3. 在 Reader 子树引入局部 Theme，逐步迁移标题区、摘要卡、搜索条、底部工具条和正文容器。
4. 收拢现有动画到统一 motion token，并为禁用动画场景提供降级。
5. 通过 widget test、golden/screenshot 校验或手工多平台巡检完成视觉回归。

回滚策略：

- 主题入口与设置模型不改 public contract，必要时可以先移除新 token 消费点并退回旧样式实现。
- Reader scene theme 和 motion baseline 采用增量切换，出现问题时可逐块回退而不影响数据或路由结构。

## Open Questions

- 是否在本次实现中同时引入高对比主题接线，还是先只完成普通 light/dark 主题重构？
- 是否需要在首批落地中新增“减少动画”或“界面密度”设置，还是先完全跟随系统与 platform profile？
- Reader 的默认中文正文字体是否保持系统无衬线优先，还是为部分平台探索可选 serif 模式？
