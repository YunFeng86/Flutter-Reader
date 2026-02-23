# Fleur

一款使用 Flutter 构建的跨平台 RSS 阅读器应用，采用 Clean Architecture 架构和 Riverpod 状态管理。

## ✨ 功能特性

- 📰 **RSS/Atom 订阅** - 支持 RSS 和 Atom 格式的订阅源
- 📂 **分类管理** - 自定义分类整理你的订阅
- 📖 **全文提取** - 智能提取文章完整内容（支持 WordPress、Hexo、Hugo、Halo 等）
- 🌓 **Material You** - 支持 Dynamic Color 动态主题
- 🌍 **多语言支持** - 支持简体中文、繁体中文、英文
- 📱 **响应式布局** - 适配手机、平板和桌面端
- 🔔 **本地通知** - 新文章推送提醒
- 💾 **离线阅读** - 本地缓存文章内容

## 📱 支持平台

| Android | iOS | Windows | macOS | Linux | Web |
|:-------:|:---:|:-------:|:-----:|:-----:|:---:|
| 🔄 | 🔄 | ✅ | 🔄 | 🔄 | ❌ |

### ✅ 正式支持（已测试）

- **Windows 10/11 (x64)** - 经过充分测试，稳定可用

### 🔄 理论支持（未经测试）

- **Android** - 代码理论上支持，但未在真机测试
- **iOS** - 代码理论上支持，但未在真机测试
- **macOS 11+** - 依赖 `window_manager`，窗口行为未验证
- **Linux (x64)** - 依赖 GTK 3.0+，通知系统可能需要额外配置

**如果你在这些平台上成功运行，请在 [Issues](https://github.com/YunFeng86/Fleur/issues) 报告你的系统信息和遇到的问题。**

### ❌ 暂不支持

- **Web** - Isar 数据库不支持 Web 平台

## 🚀 快速开始

### 环境要求

- Flutter SDK >= 3.10.0
- Dart SDK >= 3.10.0

### 安装依赖

```bash
flutter pub get
```

### 生成代码

项目使用 Isar 数据库，需要生成模型代码：

```bash
dart run build_runner build
```

如果遇到冲突，可以使用：

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 运行应用

```bash
# 开发模式运行
flutter run

# 指定设备运行
flutter run -d windows
flutter run -d macos
flutter run -d chrome
```

### 构建发布版本

```bash
# Android APK
flutter build apk

# iOS
flutter build ios

# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux

# Web
flutter build web
```

## 🏗️ 项目架构

项目采用 **Clean Architecture** 分层架构：

```
lib/
├── app/          # 应用入口、路由配置 (go_router)
├── models/       # Isar 数据模型
├── repositories/ # 数据访问层
├── providers/    # Riverpod 状态管理
├── services/     # 业务逻辑层
├── screens/      # 页面
├── widgets/      # 可复用组件
├── theme/        # 主题配置
├── l10n/         # 国际化
├── utils/        # 工具函数
└── db/           # 数据库初始化
```

## 🛠️ 技术栈

| 类别 | 技术 |
|------|------|
| 状态管理 | [Riverpod](https://riverpod.dev/) |
| 本地数据库 | [Isar](https://isar.dev/) |
| 路由 | [go_router](https://pub.dev/packages/go_router) |
| 网络请求 | [Dio](https://pub.dev/packages/dio) |
| RSS 解析 | [rss_dart](https://pub.dev/packages/rss_dart) |
| HTML 渲染 | [flutter_widget_from_html](https://pub.dev/packages/flutter_widget_from_html) |
| 窗口管理 | [window_manager](https://pub.dev/packages/window_manager) |
| 本地通知 | [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) |

## 🧪 测试

```bash
# 运行单元测试
flutter test

# 运行集成测试
flutter test integration_test
```

## 📄 License

本项目采用 MIT 许可证。
