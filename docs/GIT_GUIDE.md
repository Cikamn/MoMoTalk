# MoMoTalk：Git、阶段版本与协作入门

本文的命令在项目根目录 `F:\Project\MoMOTalk` 的 PowerShell 中执行。
Visual Studio 2022 用于管理 Git；鸿蒙编译、签名和模拟器运行仍使用 DevEco Studio。

## 1. 先理解这些词

| 名称 | 在这个项目里的含义 |
| --- | --- |
| 仓库 | `.git` 目录记录提交历史；源码仍在原位置 |
| 工作区 | 你正在编辑的文件；按保存只更新这里 |
| 暂存区 / stage | 选好准备写进下一次提交的改动 |
| 提交 / commit | 给暂存的内容建立一个有编号、有说明的本地记录 |
| 分支 / branch | 一条可继续开发的历史线，如 `develop` |
| 标签 / tag | 给确定的提交起固定名字，如 `v0.1.0` |
| GitHub | 保存远端仓库，提供备份、协作和评审 |
| 推送 / push | 把本地提交、分支或标签上传到远端 |
| 拉取 / pull | 获取远端更新并整合到当前分支 |
| PR / Pull Request | 请协作者检查并合并一个分支的改动 |

保存文件、提交 Git、推送 GitHub 是三个步骤。Git 不会自动记录每次保存，也不会自动上传。
仅有本地 `.git` 不能替代远端备份。

## 2. 本项目的初始约定

- `main`：已选定的阶段展示基线。初始化时只代表当前源码快照，不代表正式验收版。
- `develop`：日常开发，允许比当前展示版本领先。
- `feature/功能名`：多人协作或较大功能时，从 `develop` 创建的短期分支。
- `baseline-2026-09-18`：首次纳入版本管理的基线标签，不代替正式版本号。
- `v0.1.0`、`v0.2.0`：以后每完成并验证一个阶段，再创建相应标签。

后文版本号和功能名都是示例，请按实际规划替换。标签不会证明测试通过，也不会自动修改 App 版本号。
初始化只在本仓库配置提交署名，不改变全局 Git 设置。查看当前状态：

```powershell
git config --local user.name
git config --local user.email
git branch --show-current
git log --oneline --decorate -5
git status
```

## 3. 平时保存一次开发成果

先在 DevEco Studio 中保存文件，验证本次修改，然后执行：

```powershell
git status
git diff
git add .
git diff --cached --stat
git diff --cached
git commit -m "fix: 修复角色头像显示"
```

含义依次是：查看状态、检查改动、暂存、查看暂存概要、检查将提交的内容、建立提交。
`git add .` 包括新增、修改和删除，执行前确认这些都属于本次工作。提交说明描述实际改动。
只提交部分文件时，用 `git add 文件路径`。暂存后又修改的内容，需要重新暂存。
`git diff` 不显示未跟踪新文件的内容；先查看新文件本身，暂存后再用 `git diff --cached` 检查。
完成一个小功能或修复就可以提交，不用等整版完成。很多提交最后可以对应一个版本标签。

远端和上游分支配置好以后，再用 `git push` 上传；首次连接方法见第 6 节。

## 4. 提前开发，按阶段展示

每完成一个阶段，就提交、验证、打标签，然后继续下一阶段。后续提交不会改变旧标签。

```text
初始基线 ── 第一阶段完成 ── 第二阶段完成 ── 第三阶段开发中
   ↑              ↑              ↑                  ↑
 main          v0.1.0         v0.2.0             develop
```

例如当前 `develop` 正好完成第一阶段，且所有改动都已提交、验证：

```powershell
git status
git tag -a v0.1.0 -m "第一阶段：填写实际完成并验证的功能"
```

第二阶段完成后同样创建 `v0.2.0`。保留真实提交日期，阶段说明区分已开发、已测试和已发布内容。
如果几阶段功能混在同一次提交中，Git 不能自动拆出较早阶段；需要重新拆分改动或使用功能开关。
未准备纳入当前阶段的独立功能可以先留在 `feature/*` 分支。

### 演示指定阶段，不影响正在开发的目录

推荐 Git worktree：从同一个仓库额外检出一个目录，专门运行固定版本。
以下示例要求 `v0.1.0` 标签已经存在：

```powershell
git worktree add --detach .demo-worktrees/v0.1.0 v0.1.0
git worktree list
```

用 DevEco Studio 打开 `F:\Project\MoMOTalk\.demo-worktrees\v0.1.0`，同步依赖、配置本机签名并运行。
该目录处于 detached HEAD，适合查看和演示；需要修改时先创建修复分支。
worktree 共享 Git 历史，但依赖、构建缓存和本机签名配置不会自动复制。
切换源码不会自动改变模拟器已安装的 App，必须重新构建和运行。
同包名 App 在同一模拟器上可能继续使用原有应用数据；旧版本不一定兼容新版数据，验收宜使用独立模拟器。
如果出现版本降级安装限制，优先使用演示专用模拟器，不要随意降低正式版本的 versionCode。

演示结束、确认目录内没有需要保留的文件，关闭对应 DevEco 工程后：

```powershell
git worktree remove .demo-worktrees/v0.1.0
```

若 Git 提示存在未提交或未跟踪文件，先检查并保留需要的内容，不要直接加 `--force`。

### 把第一阶段设为 main

如果 main 自基线以来没有另外产生提交，在干净工作区执行：

```powershell
git switch main
git merge --ff-only v0.1.0
git switch develop
```

这让 main 前进到第一阶段，不会带入 develop 上后续阶段的功能。
如果 `--ff-only` 失败，说明历史已分叉，先检查，不要强制重置。main 的修复也要合回 develop。
多人协作时通过 PR 检查阶段分支再合并；不要在 develop 已含未来阶段时直接把整个 develop 合入 main。
每次验收记录标签、提交号、功能清单、测试设备、已知问题和截图。提交号用 `git rev-parse --short HEAD` 查看。
`AppScope/app.json5` 中的 `versionName` 和 `versionCode` 要在阶段提交中另行维护，Git 标签不会替你改它们。

## 5. Visual Studio 2022 界面操作

1. 通过“文件 → 打开 → 文件夹”打开 `F:\Project\MoMOTalk`，不必创建 .sln 或 C# 工程。
2. 打开“视图 → Git 更改”（Git Changes）；找不到时用 Ctrl+Q 搜索窗口名称。
3. 双击有变化的文件，检查左右差异。
4. 点击文件旁的 + 暂存，只选择本次准备提交的内容。
5. 输入说明，选择“提交暂存的内容”（Commit Staged）。
6. 配置远端后，点击“推送”（Push）上传本地提交。
7. 在“视图 → Git 存储库”（Git Repository）查看历史和分支，也可以用 Ctrl+Q 搜索。

Visual Studio 2022 不同小版本的标签和 worktree 界面有差异，找不到时使用本文命令。
同一目录在任何工具中切换分支，其他工具看到的文件也会改变；先保存文件、停止构建。
同一工作区同时只进行一次暂存、提交或切分支操作，避免多个工具互相干扰。
操作说明依据 [Microsoft 提交指南](https://learn.microsoft.com/en-us/visualstudio/version-control/git-make-commit?view=vs-2022)。

## 6. 第一次连接 GitHub

本项目选择 Public，目标仓库为 https://github.com/Cikamn/MoMoTalk 。已推送的分支和历史公开可见；标签用于选择展示版本，不隐藏后续功能。
本项目的 GitHub 所属账号是 Cikamn，仓库名是 MoMoTalk；本地提交署名也使用 Cikamn 及该账号的 GitHub 隐私邮箱。
不要勾选自动创建 README、.gitignore 和 License，本地已经有这些文件。
本项目的远端地址如下。remote add 和首次推送命令只在尚未配置时执行；已经配置后，不要重复执行 remote add：

```powershell
git remote add origin https://github.com/Cikamn/MoMoTalk.git
git remote -v
git push -u origin main
git push -u origin develop
git push origin baseline-2026-09-18
```

`origin` 是远端地址简称，`-u` 设置本地分支对应的远端上游，之后在该分支上可直接 `git push`。
若 origin 已存在，先查看地址，不要重复添加或盲目覆盖。
若远端已有 README 或其他提交，先检查两边历史，不要强推覆盖。
本机已配置 Git Credential Manager；首次推送可能弹出 GitHub 登录/授权，由你完成。
提交署名不是登录凭据，连接器登录也不等于本机 Git 已登录。不要把密码或令牌发到聊天或写入远端 URL。
版本标签单独推送，例如 `git push origin v0.1.0`。
GitHub Release 是基于标签的发布说明，可以附安装包；普通 push 不会自动发布 Release。
首次上传后，在 GitHub 检查文件、main/develop 分支和基线标签都存在。
参见 [GitHub 上传本地仓库指南](https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/adding-locally-hosted-code-to-github)。

## 7. 多人协作

每个人用自己的电脑目录、Git 署名和 GitHub 账号，不共用工作目录或登录凭据。
协作者先 clone，再用 DevEco Studio 打开并同步依赖：

```powershell
git clone https://github.com/Cikamn/MoMoTalk.git
cd MoMoTalk
git switch develop
git pull --ff-only
git switch -c feature/avatar-preview
```

开发、验证、提交后：

```powershell
git push -u origin feature/avatar-preview
```

在 GitHub 创建 PR，目标分支选 develop，写明改动、验证方式和截图，检查后再合并。
合并后，每个人切回 develop，用 `git pull --ff-only` 同步。
拉取失败或产生冲突时，先看 `git status`，与修改同一区域的同学确认要保留的内容，不要强推。

## 8. 提交与忽略的文件

提交源码、资源、构建配置、文档和各模块的 `oh-package-lock.json5`，让依赖版本可以追溯。
不提交 oh_modules、build、.hvigor、.idea、.vs、自动生成的 BuildProfile.ets、本机密钥或签名文件。
忽略文件仍留在磁盘，只是不进入 Git。`.gitignore` 不能识别普通源码中粘贴的 API Key。
根目录 build-profile.json5 是需要提交的构建文件；DevEco 自动签名可能写入个人证书路径和口令。
每次提交前检查它的差异，避免提交本机签名字段，不要忽略整个构建文件。
文件已进入历史后，后来加 .gitignore 不会自动清除历史中的内容。

## 9. 查看和撤销

常用查看命令：

```powershell
git status
git log --oneline --graph --decorate --all -15
git diff
git diff --cached
git tag --list
```

- 暂存错了：`git restore --staged 文件路径`，保留工作区修改。
- 未提交的修改确实不要了：`git restore 文件路径`，丢弃该文件未暂存修改，先确认内容已备份。
- 错误已经提交并共享：通常用 `git revert 提交号` 生成反向提交，保留历史；涉及多个或合并提交时先检查。
- 不要用 `git reset --hard`、`git clean -fd` 或强推作为日常切回旧版的办法，演示用标签和 worktree。

更多官方说明：[Git 标签](https://git-scm.com/book/en/v2/Git-Basics-Tagging)、[Git worktree](https://git-scm.com/docs/git-worktree)、[Visual Studio 管理仓库](https://learn.microsoft.com/en-us/visualstudio/version-control/git-manage-repository?view=vs-2022)。
