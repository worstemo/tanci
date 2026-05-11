# 弹词 - Android 单词学习应用

一款创新的单词学习应用，通过弹窗复习和图片识别功能，帮助用户高效记忆单词。

## 功能特点

### 1. 弹窗复习
- 玩手机时随机弹出不熟单词
- 答对才能继续操作
- 可设置弹窗间隔和免打扰时段

### 2. 图片识别导入
- 拍照识别单词卡片
- 自动识别 ✓/X 标记
- 支持批量导入

### 3. 记忆辅助
- 内置趣味记忆梗
- 帮助联想记忆
- 提高学习效率

### 4. 词库管理
- 内置示例词库
- 支持手动添加
- 支持图片导入

---

## 环境要求

- Flutter SDK 3.0.0 或更高版本
- Android Studio (用于 Android 开发)
- Android SDK 21 或更高版本
- 一台 Android 设备或模拟器

---

## 安装步骤

### 1. 安装 Flutter

如果你还没有安装 Flutter，请按照官方指南安装：

**Windows:**
```bash
# 下载 Flutter SDK
# https://docs.flutter.dev/get-started/install/windows

# 添加到环境变量 PATH
# 例如: C:\flutter\bin
```

**macOS:**
```bash
brew install flutter
```

**Linux:**
```bash
sudo snap install flutter --classic
```

### 2. 验证安装

```bash
flutter doctor
```

确保所有项目都是绿色勾勾（✓）。

### 3. 克隆或下载项目

```bash
cd /workspace/word_master
```

### 4. 安装依赖

```bash
flutter pub get
```

### 5. 运行应用

连接 Android 设备或启动模拟器，然后运行：

```bash
flutter run
```

---

## 构建 APK

### 调试版 APK

```bash
flutter build apk --debug
```

生成的 APK 位于：`build/app/outputs/flutter-apk/app-debug.apk`

### 发布版 APK

```bash
flutter build apk --release
```

生成的 APK 位于：`build/app/outputs/flutter-apk/app-release.apk`

---

## 项目结构

```
word_master/
├── lib/
│   ├── main.dart                 # 应用入口
│   ├── models/                   # 数据模型
│   │   ├── word.dart            # 单词模型
│   │   └── word_book.dart       # 词书模型
│   ├── services/                 # 服务层
│   │   ├── database_service.dart # 数据库服务
│   │   ├── word_provider.dart   # 单词状态管理
│   │   ├── settings_provider.dart # 设置状态管理
│   │   ├── popup_service.dart   # 弹窗服务
│   │   └── ocr_service.dart     # OCR识别服务
│   ├── screens/                  # 页面
│   │   ├── home_screen.dart     # 首页
│   │   ├── word_list_screen.dart # 词库页
│   │   ├── study_screen.dart    # 学习页
│   │   └── settings_screen.dart # 设置页
│   └── widgets/                  # 组件
│       ├── word_card.dart       # 单词卡片
│       └── stats_card.dart      # 统计卡片
├── android/                      # Android 原生代码
│   └── app/src/main/
│       ├── AndroidManifest.xml  # 权限配置
│       ├── kotlin/              # Kotlin 代码
│       │   └── com/example/word_master/
│       │       ├── MainActivity.kt
│       │       ├── OverlayService.kt
│       │       └── BootReceiver.kt
│       └── res/layout/          # 布局文件
│           └── overlay_popup.xml
├── pubspec.yaml                  # 依赖配置
└── README.md                     # 说明文档
```

---

## 权限说明

应用需要以下权限：

| 权限 | 用途 |
|------|------|
| SYSTEM_ALERT_WINDOW | 悬浮窗显示 |
| CAMERA | 拍照识别 |
| READ_EXTERNAL_STORAGE | 读取图片 |
| WRITE_EXTERNAL_STORAGE | 保存数据 |
| POST_NOTIFICATIONS | 推送通知 |

---

## 使用指南

### 添加单词

1. **手动添加**
   - 进入「词库」页面
   - 点击右下角「+」按钮
   - 输入单词、意思和记忆技巧

2. **图片导入**
   - 进入「首页」
   - 点击「图片导入」
   - 拍摄或选择单词卡片图片
   - 确认识别结果后导入

### 学习单词

1. 进入「学习」页面
2. 系统会显示不熟悉的单词
3. 选择正确的意思
4. 答对提高熟悉度，答错降低熟悉度

### 开启弹窗复习

1. 进入「设置」页面
2. 开启「弹窗复习」开关
3. 授予悬浮窗权限
4. 设置弹窗间隔和免打扰时段

---

## 常见问题

### Q: 悬浮窗不显示？
A: 请确保已授予悬浮窗权限。在系统设置中找到「弹词」→「权限」→ 开启「显示在其他应用上层」。

### Q: 图片识别不准确？
A: 确保图片清晰，光线充足。手写符号建议使用标准的 ✓ 和 X。

### Q: 如何备份数据？
A: 目前支持导出功能，在「设置」→「导出单词」中导出 CSV 文件。

---

## 技术栈

- **框架**: Flutter 3.x
- **语言**: Dart
- **数据库**: SQLite (sqflite)
- **OCR**: Google ML Kit
- **状态管理**: Provider

---

## 后续开发计划

- [ ] iOS 版本适配
- [ ] 云端同步
- [ ] 更多词书
- [ ] 学习统计图表
- [ ] 社区分享记忆梗

---

## 联系方式

如有问题或建议，欢迎反馈！
