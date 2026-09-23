# MoMoTalk

基于 ArkTS / ArkUI 的角色聊天应用，保留鸿蒙工程，并通过 ArkUI-X 构建 Android 版本。本次适配不包含 iOS。

现有功能包括角色设定、本地角色知识检索、头像裁剪、模型接口配置、文字聊天、聊天记录，以及个人中心和设置。本机开发包可使用[内置 DeepSeek 配置](docs/LOCAL_AI.md)，无需先在应用内填写密钥；右上角“配置”仍支持自定义模型服务。账号相关服务目前使用项目已有的模拟实现。

## 开发与构建

- **鸿蒙**：在 DevEco Studio 中打开仓库根目录，使用 `products/phone` 构建运行。
- **Android**：见 [Android 构建与测试](docs/ANDROID.md)，运行 `scripts/build-android.ps1`。APK 生成在 `build/arkuix/.arkui-x/android/app/build/outputs/apk/debug/`。
- **Git / Visual Studio 2022 / 阶段验收与协作**：见 [Git 使用指南](docs/GIT_GUIDE.md)。

Android 构建会复制共享源码到 `build/arkuix`，应用 `platforms/android/overrides.json` 中列出的平台适配，再调用官方 ArkUI-X 工具链。请修改共享源码或明确列出的 Android 适配文件，不要编辑生成目录。仓库根工程不要求安装 Android SDK 即可继续开发鸿蒙版本。

## 当前验证范围

Android 已在电脑的 Android 9（API 28）x86_64 模拟器上进行实际运行测试；具体结果及限制见 [验证记录](docs/ANDROID.md#验证记录)。构建包含 arm64-v8a 与 x86_64，ARM 真机和其他 Android 版本尚需进一步验证。不能把一次模拟器测试理解成所有安卓机型均已验证。

## 项目来源与许可

本项目基于原 AI 应用模板继续开发，保留原有模板来源和 Apache 2.0 许可声明。代码使用 [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)。第三方依赖及图片等素材遵循各自的许可。
