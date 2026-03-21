## 1. Settings Scene Foundation

- [x] 1.1 盘点并抽取设置页共享 primitives，包括页面容器、section、card、通用 tile 和必要的详情头部组件
- [x] 1.2 让共享 primitives 优先消费现有 `ThemeData` 组件主题与 settings scene token，移除重复的局部颜色、圆角和密度定义
- [x] 1.3 收口设置入口导航在 stacked / split 模式下的选中态、密度和标题行为，使其遵循统一 settings contract

## 2. Migrate Standard Settings Tabs

- [x] 2.1 迁移 `AppPreferencesTab` 与 `GroupingSortingTab` 到共享 settings primitives，统一 section、表单区和 slider 呈现
- [x] 2.2 迁移 `ServicesTab` 与 `TranslationAiServicesTab` 到共享 settings primitives，统一动作项、值展示项和卡片分组
- [x] 2.3 迁移 `AboutTab` 到共享 settings primitives，并校准信息区、按钮区和只读内容的层级表现

## 3. Normalize Subscription Settings

- [x] 3.1 重构订阅设置详情面板，使 global/category/feed 详情统一进入共享 settings scene 的 section、card、field 和 destructive action 模式
- [x] 3.2 收口分类列表、Feed 列表和树视图的选中态、悬停态和空态，使其改读共享列表或 settings scene 样式而不是局部颜色覆盖
- [x] 3.3 校准订阅设置在 stacked / split / multi-pane 模式下的标题、返回和动作区行为，避免双标题与窄宽度挤压

## 4. Verification

- [x] 4.1 补充或更新与设置页 primitives、标题行为和响应式动作区相关的 widget tests
- [x] 4.2 运行 `flutter analyze` 与相关测试，修复设置页迁移引入的问题
- [x] 4.3 对设置页主要路径进行桌面/移动布局手工巡检，确认常规 tab 与订阅设置都已归一且无明显溢出
