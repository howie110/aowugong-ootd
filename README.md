# 每日穿搭

[![Android Release](https://github.com/howie110/aowugong-ootd/actions/workflows/android-release.yml/badge.svg)](https://github.com/howie110/aowugong-ootd/actions/workflows/android-release.yml)
![Flutter](https://img.shields.io/badge/Flutter-Android-blue)
![Local First](https://img.shields.io/badge/local--first-no%20cloud-success)
![Status](https://img.shields.io/badge/status-active-brightgreen)

一款离线优先的 Android 穿搭日记 App。

用它把每天的搭配、照片、喜好、季节、场景和评分整理成一个可以长期回看的私人穿搭档案。没有账号，没有云同步，没有广告；数据默认留在自己的手机里，需要迁移时再主动导出 ZIP 备份。

- 当前版本：`1.0.5+6`
- Android 包名：`com.aowugong.ootd`
- 应用名称：`每日穿搭`

## 立即下载

APK 会发布在 [GitHub Releases](https://github.com/howie110/aowugong-ootd/releases)。

手动安装 APK 时，Android 可能提示“未知来源应用”。这是 GitHub 分发 APK 的正常提示，请只从本仓库 Releases 下载。

## 它适合谁

- 想记录每天穿了什么，但不想发到社交平台的人
- 想回看哪些搭配好看、哪些不适合自己的人
- 想按季节、场景、色调、喜好快速筛选历史穿搭的人
- 想把穿搭数据留在本机，并能自己备份迁移的人

## 核心能力

| 能力 | 说明 |
| --- | --- |
| 每日记录 | 按日期保存穿搭，同一天只保留一条记录 |
| 多图管理 | 每条穿搭最多 `4` 张图片，包含主图和副图 |
| 快速回看 | 首页网格展示历史穿搭，适合翻看和比较 |
| 多维筛选 | 支持喜好、季节、场景、色调、评分等维度 |
| 自定义选项 | 可以按自己的习惯扩展记录维度 |
| 本地备份 | 支持 ZIP 导出和导入，方便迁移或留档 |
| 离线优先 | 无账号、无云同步、无广告，数据默认留在设备本机 |

## 隐私承诺

当前版本不提供账号系统、云同步、统计上报或广告 SDK。

穿搭记录和图片路径保存在设备本地。备份 ZIP 只会在用户主动导出或分享时离开设备。应用会申请 Android 图片相关权限，仅用于用户选择和管理本机穿搭照片。

如果未来加入联网、云同步、统计或崩溃上报，会在 README 和隐私说明中明确更新。

完整说明见 [Privacy Policy](PRIVACY.md)。

## 截图

<p align="center">
  <img src="docs/assets/screenshots/home-grid.jpg" width="220" alt="首页穿搭网格">
  <img src="docs/assets/screenshots/ootd-detail.jpg" width="220" alt="穿搭详情编辑">
  <img src="docs/assets/screenshots/settings.jpg" width="220" alt="设置页面">
</p>

首页可以按喜好、季节等维度筛选穿搭；详情页支持主图、副图和选项编辑；设置页提供选项管理、数据备份和备份导入入口。

## 项目状态

当前代码已经进入可运行、可安装、可迭代阶段。

已具备：

- Android release APK 构建配置
- GitHub Actions 在线打包到 GitHub Releases
- 本地数据存储、筛选、编辑和备份流程
- 发版、测试、架构和产品文档
- MIT License、隐私说明、安全反馈说明和 Issue 模板

## 开发

推荐环境：Windows + Android Studio + Flutter。

```powershell
flutter pub get
flutter test
flutter run
```

本机打 release APK 需要额外准备 Android release keystore，详见 [发版说明](docs/06-operations/release.md)。

## 发布

本项目支持 GitHub 在线打包：推送 `v*.*.*` tag 后，由 GitHub Actions 构建 signed release APK，并上传到 GitHub Releases。

线上打包需要先在 GitHub Secrets 中配置 Android 签名信息，详见 [GitHub Release 自动打包](docs/06-operations/github-release.md)。

## 文档入口

- [文档地图](docs/README.md)
- [产品需求](docs/01-product/product-requirements.md)
- [项目架构](docs/02-architecture/architecture-overview.md)
- [项目结构](docs/02-architecture/project-structure.md)
- [发版说明](docs/06-operations/release.md)
- [GitHub Release 自动打包](docs/06-operations/github-release.md)
- [公开项目检查清单](docs/06-operations/public-project-checklist.md)
- [测试清单](docs/06-operations/test-checklist.md)
- [版本记录](CHANGELOG.md)

## 仓库结构

```text
lib/
  app/          应用壳、根路由、全局 Provider
  bootstrap/    启动加载与初始数据注入
  features/     按功能拆分的业务代码
  shared/       主题、通用设计与共享组件
android/        Android 工程、包名、签名与图标
docs/           产品、架构、操作、决策文档
test/           Widget 测试
```

## 授权与素材

本项目使用 [MIT License](LICENSE)。

公开发布前请确认仓库和 APK 中的图片、图标、截图、文案和第三方依赖授权清楚。素材来源不明时，不要放入仓库或发布包。
