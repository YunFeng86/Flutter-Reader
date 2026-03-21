## Why

Fleur 在完成自适应 UI、阅读器场景和动效基线重构后，`ReaderView`、`Sidebar` 和 `HomeScreen` 已经演变为高耦合场景根组件，分别同时承担渲染、命令编排、状态协调、平台交互和管理流程。继续在这些文件上直接叠加功能会放大回归风险、降低可维护性，并让后续的 UI、状态和交互演进越来越依赖少数巨型文件。

## What Changes

- 为阅读器、侧栏和首页建立明确的场景根职责边界，让场景根组件回到“装配层”，把非渲染职责下沉到专门的协调器、动作层或子场景组件。
- 重构 `ReaderView`，将文章/翻译监听、阅读进度恢复与持久化、长文分块渲染、搜索跳转、桌面选择与上下文菜单、媒体与设置弹层拆分为独立子系统。
- 重构 `Sidebar`，将导航树渲染、选择命令、订阅/分类管理动作、导入导出流程和平台差异化弹层表达分离。
- 重构 `HomeScreen`，抽离场景命令、键盘快捷键绑定和桌面/平板/移动布局编排，减少不同布局分支中的重复 orchestration。
- 在保持现有用户可见行为、路由语义和主要测试覆盖不退化的前提下，为后续功能迭代提供稳定扩展点。

## Capabilities

### New Capabilities
- `scene-root-composition`: 定义高层场景根组件的职责边界、装配责任和可接受的协调范围。
- `reader-subsystem-orchestration`: 定义阅读器场景中进度、搜索、长文分块、选择菜单和媒体交互等子系统的边界与协作方式。
- `subscription-navigation-actions`: 定义侧栏导航树、选择状态命令和订阅管理动作的分层方式。

### Modified Capabilities

None.

## Impact

- 受影响代码主要位于 `lib/widgets/reader_view.dart`、`lib/widgets/sidebar.dart`、`lib/screens/home_screen.dart`，以及相关的 `lib/ui/`、`lib/providers/`、`lib/widgets/` 辅助模块。
- 可能新增场景协调器、动作 facade、布局子组件或局部状态封装，但不应改变既有业务数据模型、路由路径或存储格式。
- 需要更新与补充阅读器、侧栏和首页的 widget / provider 测试，确保重构后关键交互仍保持当前行为。
