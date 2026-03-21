## Why

Fleur 的主题基础设施已经完成归一，但设置页仍然混用多套局部样式：部分 tab 依赖手写 `Container + surfaceContainerLow`，订阅设置又走另一套 `ListTile`/状态色写法，导致同一设置场景在分组标题、表面层级、选中态、危险操作和窄宽度布局上缺少一致的产品语气。这个问题现在需要被单独收口，否则后续继续扩展设置项时会放大样式分叉和维护成本。

## What Changes

- 为设置页建立统一的 scene-level 视觉 contract，覆盖 section 标题、设置卡片、值展示、动作项、表单项和危险操作的呈现规则。
- 将现有设置 tab 从重复的 widget 局部样式迁移到共享的 settings primitives，优先消费全局主题和共享 token，而不是继续手写局部颜色、圆角和密度。
- 收口订阅设置与其他设置 tab 的视觉差异，使其在列表、详情、三态配置项和输入区上与统一设置场景保持一致，同时保留其层级和信息密度。
- 校准设置页在 stacked / split / multi-pane 场景下的布局与标题行为，避免不同宽度下出现双标题、局部过密或动作区挤压的问题。

## Capabilities

### New Capabilities
- `settings-scene-presentation`: 定义 Fleur 设置页的统一视觉层级、共享组件模式和不同布局模式下的设置场景呈现规则

### Modified Capabilities

None.

## Impact

- 受影响代码主要位于 `lib/screens/settings_screen.dart`、`lib/ui/settings/`、`lib/theme/` 以及与订阅设置相关的 `lib/ui/settings/subscriptions/`。
- 需要新增或重构设置页共享 primitives，并迁移现有 tab 与订阅设置详情面板的消费方式。
- 不引入新的服务端 API 或数据模型，但会影响设置页的 UI 结构、主题消费方式和跨平台视觉表现。
