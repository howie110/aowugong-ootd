# 文档地图

Status: active
Type: index
Last Updated: 2026-06-11
Source of Truth: yes

## Summary

本目录用于描述“每日穿搭”项目当前真实状态，包括产品边界、架构实现、开发方式、发版方式和后续优化方向。

本次文档更新后，文档基线已经从“开发前设想”切换到“当前已实现版本”。如果文档与代码冲突，以代码和本文档索引指向的长期文档为准。

## 建议阅读顺序

1. [项目根说明](../README.md)
2. [产品需求](01-product/product-requirements.md)
3. [MVP 与当前稳定范围](01-product/mvp-scope.md)
4. [架构总览](02-architecture/architecture-overview.md)
5. [项目结构](02-architecture/project-structure.md)
6. [数据流](02-architecture/data-flow.md)
7. [数据模型](02-architecture/data-model.md)
8. [存储策略](02-architecture/storage-strategy.md)
9. [本地开发与安装](06-operations/dev-setup.md)
10. [调试与运行](06-operations/debug-and-run.md)
11. [发版说明](06-operations/release.md)
12. [GitHub Release 自动打包](06-operations/github-release.md)
13. [公开项目检查清单](06-operations/public-project-checklist.md)
14. [测试清单](06-operations/test-checklist.md)
15. [版本记录](../CHANGELOG.md)

## 目录说明

### `01-product/`

回答“这个产品现在做什么、不做什么”。

- `product-requirements.md`: 当前产品能力、核心流程、约束和成功标准
- `mvp-scope.md`: 当前稳定版本的边界，以及明确后置的能力

### `02-architecture/`

回答“现在的代码怎么组织、数据怎么流动、文件怎么存”。

- `architecture-overview.md`: 技术栈、分层、核心实现方式
- `project-structure.md`: 仓库和 `lib/` 目录结构
- `data-flow.md`: 启动、编辑、备份导入等关键流程
- `data-model.md`: 当前持久化模型与内存模型
- `storage-strategy.md`: JSON、图片、zip 和目录策略

### `03-plans/`

回答“当前阶段在做什么”。

- `current.md`: 当前阶段目标与执行重点
- 其他文件默认视为阶段性计划或历史记录，不作为长期真相

### `04-decisions/`

回答“为什么要这么定”。

- `ADR-001-local-first-storage.md`: 为什么坚持离线优先
- `ADR-002-json-files-over-local-db.md`: 为什么当前版本不用本地数据库
- `ADR-003-zip-backup-format.md`: 为什么备份使用 `zip`
- `ADR-004-android-package-and-signing.md`: 为什么尽早固定包名和签名

### `05-tasks/`

回答“下一阶段优化做什么”。

- `now.md`: 当前正在推进或等待验证的事项
- `backlog.md`: 已经确认有价值，但暂未排进当前迭代的方向

### `06-operations/`

回答“怎么装环境、怎么调试、怎么发版、怎么验证”。

- `dev-setup.md`
- `debug-and-run.md`
- `release.md`
- `github-release.md`
- `public-project-checklist.md`
- `test-checklist.md`

### `99-archive/`

存放已失效或仅保留历史背景价值的文档，不作为当前实现依据。

## 冲突处理规则

- 产品边界冲突时，以 `01-product/` 为准。
- 实现方式冲突时，以 `02-architecture/` 和 `04-decisions/` 为准。
- 操作步骤冲突时，以 `06-operations/` 为准。
- 版本变化冲突时，以 [CHANGELOG.md](../CHANGELOG.md) 为准。

## 文档维护规则

- 文档必须描述当前实现，不写“理想上以后可能这样”的模糊现状。
- 关键工程决策不要只留在聊天里，必须回写 ADR。
- 任何会影响安装、调试、发版、数据兼容的变化，都要同步更新 `06-operations/`。
- 新版本发布后，同时更新 `CHANGELOG.md`、`pubspec.yaml` 和相关操作文档。
