# 内置 DeepSeek 开发配置

本地开发包可以内置默认 DeepSeek 密钥，鸿蒙和 Android 共用 `AIConfigStore`。新安装且没有完整自定义配置时，自动使用内置服务；右上角“配置”保存的完整配置优先。切换服务商或修改接口地址时清空原密钥，避免误用。

## 本机配置

在 `products/phone/src/main/resources/rawfile/ai_defaults.local.json` 写入：

```json
{
  "apiKey": "填入你自己的开发密钥"
}
```

此文件已被 Git 忽略，不会上传 GitHub。接口固定为 `https://api.deepseek.com`，沿用项目的 `deepseek-v4-flash` 模型别名。不从这个文件接收任意接口地址。缺失或损坏时仍可打开应用，使用右上角配置功能。

在 DevEco Studio 构建鸿蒙包，或运行 Android 构建脚本时，此资源会被包含进本机安装包。不同 worktree 的本地文件不会由 Git 同步，需要单独准备。仅在内存中使用默认配置，不自动将密钥写入应用偏好设置；用户在配置页主动保存则沿用原有的本机保存流程。

## 分发前

这是个人开发方案：忽略 Git 文件不能防止别人从安装包提取密钥。不要将含内置密钥的 HAP、APK 或生成目录公开发布。发给好友之前，改为后端代理、移除这个本地文件、重新构建并检查产物，同时更换开发密钥。

## 本次验证

只进行离线配置逻辑检查、两端构建及资源打包检查，不验证账户余额、密钥有效性或实际模型回答，不发送真实聊天请求。配置逻辑检查复用已安装 DevEco Studio 的 TypeScript 编译器，无需新增下载依赖：

```powershell
$env:DEVECO_STUDIO_HOME = '你的 DevEco Studio 安装目录'
npm ci --ignore-scripts
npm test
```
