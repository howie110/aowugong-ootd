# 每日穿搭

离线优先的 Flutter Android 应用，用来按天记录和回看穿搭。

当前代码已经进入可运行、可安装、可迭代的阶段，不再是纯文档方案。当前稳定版本为 `1.0.3+4`，Android 正式包名为 `com.aowugong.ootd`，应用名称为“每日穿搭”。

## 当前已实现

- 首页穿搭网格浏览
- 穿搭详情查看、编辑、删除
- 新增穿搭，且同一天只能新增一条
- 每条穿搭最多 `4` 张图片，包含 `1` 张主图和最多 `3` 张副图
- 首页多维度筛选，并持久化筛选状态
- 选项管理：内置选项和自定义选项
- 数据备份与备份导入，使用 `zip`
- Android 正式签名 `release apk`

## 快速入口

- [文档地图](docs/README.md)
- [项目架构](docs/02-architecture/architecture-overview.md)
- [项目结构](docs/02-architecture/project-structure.md)
- [数据流](docs/02-architecture/data-flow.md)
- [本地开发与安装](docs/06-operations/dev-setup.md)
- [调试与运行](docs/06-operations/debug-and-run.md)
- [发版说明](docs/06-operations/release.md)
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
assets/         当前提交到仓库的静态资源
docs/           产品、架构、操作、决策文档
test/           Widget 测试
```

## 开发说明

本项目当前优先支持 Windows + Android Studio + Flutter 的开发环境。

首次接手建议按这个顺序阅读：

1. [文档地图](docs/README.md)
2. [项目架构](docs/02-architecture/architecture-overview.md)
3. [本地开发与安装](docs/06-operations/dev-setup.md)
4. [调试与运行](docs/06-operations/debug-and-run.md)
5. [发版说明](docs/06-operations/release.md)

## 当前维护原则

- 文档描述必须以当前代码实现为准，不保留“早期设想”冒充现状。
- 关键取舍写入 `docs/04-decisions/`。
- 版本变化写入 [CHANGELOG.md](CHANGELOG.md)。
- 发版、签名、备份、调试问题写入 `docs/06-operations/`。
