## 1. Scene Root Scaffolding

- [x] 1.1 为 `HomeScreen`、`Sidebar`、`ReaderView` 确定新的场景分层与文件布局，建立装配层、动作/协调层和展示子组件的目标边界
- [x] 1.2 提取共享的场景命令或辅助契约，确保后续迁移时不需要直接在布局分支或巨型 state 中继续添加新流程

## 2. Home Scene Decomposition

- [x] 2.1 抽离 Home 场景的共享命令，覆盖 refresh、mark all read、next/prev article、toggle unread/read/star 和跳转 search 等工作流
- [x] 2.2 抽离 Home 的共享快捷键与 action wiring，让桌面、多栏和紧凑布局复用同一套命令接线
- [x] 2.3 将 Home 的桌面/平板/移动布局分支改为消费共享命令与 pane 组合组件，减少重复 orchestration

## 3. Sidebar Decomposition

- [x] 3.1 将 Sidebar 的搜索、树渲染和 section/item presenter 从单一 build 流程中拆出，形成更清晰的导航树结构
- [x] 3.2 引入 Sidebar 的选择命令与订阅管理动作层，统一处理 all/feed/category/tag 选择与 feed/category 管理流程
- [x] 3.3 让桌面菜单、移动底部弹层和对话框 presenter 复用同一 Sidebar 动作层，而不是各自维护业务分支

## 4. Reader Scene Decomposition

- [x] 4.1 提取 Reader 的 article/translation session coordination，减少 `ReaderView` 对监听与自动状态同步的直接承载
- [x] 4.2 提取 Reader 的 progress restore/persist 与 content-hash 协调逻辑，保留现有阅读进度语义
- [x] 4.3 提取 Reader 的 chunked body、search navigation 和 viewport anchoring 子系统，保持长文阅读与搜索跳转行为稳定
- [x] 4.4 提取 Reader 的 selection/context menu、desktop auto-scroll、media/dialog 等平台交互子系统
- [x] 4.5 将 Reader 场景 UI 组装收敛为 header/banner/body/bottom bar/dialog 的清晰装配结构
- [x] 4.6 将 Reader 的 session / viewport / interaction 状态从 `ReaderViewState` 下沉为显式协作者边界，避免继续通过 `part + extension on _ReaderViewState` 共享巨型 state

## 5. Verification

- [x] 5.1 更新或补充 Home、Sidebar、Reader 相关 widget/provider 测试，覆盖关键工作流和重构后的边界
- [x] 5.2 运行 `flutter analyze` 和相关测试集，确认重构未引入路由、状态或交互回归
- [x] 5.3 对首页多布局、Sidebar 管理动作和 Reader 关键阅读路径做手工回归检查
