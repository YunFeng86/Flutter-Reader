## 1. Theme Foundation

- [x] 1.1 重构 `lib/theme/`，引入基础主题装配层、平台 profile 与 `ThemeExtension` 类型，保持 `AppTheme.light/dark` 入口兼容
- [x] 1.2 为导航、卡片、列表、输入框、滚动条、Tooltip、按钮、Dialog 建立统一的 `ThemeData` 组件主题配置
- [x] 1.3 将动态取色、seed preset、主题模式与新主题装配结构接线，明确语义 surface/state token 的 light/dark 默认值

## 2. Shell And Adaptive Layout

- [x] 2.1 更新 `AppShell`、`GlobalNavRail`、`GlobalNavBar` 与桌面标题栏，使导航与窗口 chrome 消费统一的 shell token 和平台密度策略
- [x] 2.2 重构侧栏、账号 footer、未读 badge、同步状态胶囊与空态容器，使其改用共享 surface/state token
- [x] 2.3 重构文章列表容器和文章列表项的信息层级、选中态、未读态和收藏态，使其匹配新的场景语义

## 3. Reader Scene

- [x] 3.1 为 Reader 引入局部 scene theme，并迁移标题区、元信息、摘要卡与正文容器去消费 `FleurReaderTheme`
- [x] 3.2 重构 Reader 搜索条、底部工具条和相关浮层，使其在嵌入式与独立路由模式下共享统一的对齐和 surface 语义
- [x] 3.3 校准阅读宽度、内边距、空态和辅助控件布局，确保不同 pane 模式下都保持稳定的阅读 measure

## 4. Motion And Interaction Baseline

- [x] 4.1 建立共享 motion token 与辅助封装，定义短时、标准和强调型过渡的 duration/curve 以及 reduced-motion 降级策略
- [x] 4.2 将列表显现、同步状态胶囊、Reader 浮层和场景切换中的现有动画迁移到统一 motion 基线
- [x] 4.3 校验桌面 hover、Tooltip、滚动条、右键相关 affordance 与移动端触控交互不会相互冲突

## 5. Verification

- [x] 5.1 补充或更新 widget tests，覆盖主题 token 消费、导航/侧栏/列表的自适应呈现与主要状态反馈
- [x] 5.2 补充或更新 Reader 相关测试，覆盖阅读场景主题、搜索浮层、底部工具条与关键阅读工作流
- [x] 5.3 运行 `flutter analyze`、目标测试集和多平台手工巡检，确认 Windows 主支持路径和预览平台路径未出现明显 UI 回归
