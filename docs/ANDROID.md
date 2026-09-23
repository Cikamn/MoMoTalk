# Android 构建与测试

## 构建环境

当前验证组合：Windows、DevEco Studio 6.1.0.830（内置 HarmonyOS SDK API 24）、ArkUI-X 6.1.1.100（API 24）、Hvigor ArkUI-X 插件 4.24.4、Node 18.20.1、JDK 21、Android SDK Platform 35 / Build Tools 35.0.0、Gradle 8.9 / Android Gradle Plugin 8.7.3。

通过 DevEco Studio 的 SDK 管理器获取 ArkUI-X SDK，通过 Android 官方 SDK 工具安装 Android SDK。SDK、签名和本机路径不提交到 Git。首次构建需要下载依赖，耗时取决于网络；后续可复用本机缓存。

在仓库根目录打开 PowerShell：

```powershell
.\scripts\build-android.ps1 `
  -DevEcoHome '你的 DevEco Studio 安装目录' `
  -ArkUIXSdkHome '包含 24/arkui-x 的 SDK 根目录' `
  -AndroidSdkHome '你的 Android SDK 目录' `
  -JavaHome '你的 JDK 21 目录'
```

也可通过 `DEVECO_STUDIO_HOME`、`ARKUIX_SDK_HOME`、`ANDROID_HOME`、`JAVA_HOME` 提供这些路径。下载需要本地 HTTP 代理时加 `-ProxyUrl 'http://127.0.0.1:端口'`；不在项目中写入代理凭据。脚本只临时设置当前进程环境，结束后恢复。

输出：`build/arkuix/.arkui-x/android/app/build/outputs/apk/debug/app-debug.apk`。这是开发测试包；正式发布需要自行配置发布签名，不能用调试签名冒充正式版本。

## 模拟器

可在 Android Studio 的 Device Manager 创建模拟器。当前实际验证使用 Android 9 / API 28 的 AOSP x86_64 镜像。ArkUI-X 需要可用的 OpenGL ES 3；本机启动测试使用 `-gpu host -feature GLESDynamicVersion`，单独使用默认兼容图形设置出现过白屏。

```powershell
adb devices
adb -s 你的设备ID install -r .\build\arkuix\.arkui-x\android\app\build\outputs\apk\debug\app-debug.apk
adb -s 你的设备ID shell am start -n com.cikamn.momotalk/.PhoneEntryAbilityActivity
```

安装到不同设备会使用不同的应用数据。鸿蒙原应用数据不会自动迁移到 Android。

## 适配结构

- 共享源码仍在 `products` 和 `components`；鸿蒙构建配置保持原状。
- `platforms/android/overrides.json` 明确列出 Android 的替换文件，覆盖登录、网络、文件、窗口及部分系统服务。修改对应共享文件时需同步检查适配版本，避免两端行为分叉。
- `platforms/android/native` 是 Android 原生宿主，包名 `com.cikamn.momotalk`；ArkTS bundle 身份保持原值。
- `scripts/prepare-android.cjs` 只重建固定的 `build/arkuix` 目录，保持 `ignoreCrossPlatform: false`，不关闭兼容性检查。
- Hvigor 4.24.4 默认只复制 ARM 库；`stage-emulator-libs.cjs` 从同一 SDK 补齐对应的 x86_64 库，缺失时直接报错。
- `runtime-modules.json` 记录预编译 HAR 和 UIContext 间接使用、构建工具未识别的 API；`stage-runtime-libs.cjs` 根据 SDK 元数据复制它们及依赖。
- Android APK 排除 Hvigor 生成的鸿蒙测试模块 `phoneTest`。该模块内部名 `entry_test` 的路由路径与输出目录不匹配，打进 APK 会中断正常路由加载。
- Android 文件选择通过系统文档选择器和授权 URI 读取，复制到应用缓存后继续使用现有头像裁剪流程，不申请整个相册的访问权限。

## 验证记录

2026-09-21，本地实际验证：

- Android 完整构建脚本从生成目录重建 APK 成功。
- 干净安装、首次声明页、主页三标签、角色列表和编辑页面、模型设置页面打开正常。
- Android 模拟登录成功，并明确标注不连接第三方账号。
- 模型设置保存成功；使用本地模拟 OpenAI 兼容接口验证流式文字回复，不使用真实 API Key。
- 聊天记录在强制停止并重启应用后仍可打开，消息内容恢复正常。
- 自动化构建辅助工具测试覆盖适配路径检查、缺失文件、ABI 库选择、间接依赖解析。

- 系统文档选图、头像裁剪和保存通过；原 227×224 图片输出为 512×512 PNG，新建角色及头像在重启后保留。
- 鸿蒙根工程重新构建成功；本次不修改其业务源码和构建入口。
- 设置页清理缓存成功，系统选图产生的缓存也被删除，显示值从 0.41M 变为 0M。

验证边界：尚未验证 ARM 真机、Android 15 等其他系统版本及真实模型服务的联网鉴权。原第三方聊天库内的华为语音识别服务在 Android 上不可用，当前验证范围为文字聊天。Android 不接入真实华为/微信登录，也未接入应用商店更新，更新操作会明确提示。应用中原有的协议、反馈等模板内容仍需按后续版本计划完善。

## 自动化检查

```powershell
$env:DEVECO_STUDIO_HOME = '你的 DevEco Studio 安装目录'
npm ci --ignore-scripts
npm test
```

## 官方参考

- [ArkUI-X SDK](https://github.com/arkui-x/docs/blob/master/zh-cn/application-dev/tools/how-to-use-arkui-x-sdk.md)
- [AndroidX 窗口依赖](https://github.com/arkui-x/docs/blob/master/zh-cn/application-dev/reference/apis/js-apis-display.md)
- [Android SDK 管理工具](https://developer.android.com/tools/sdkmanager)
