# 文档地图

Status: active
Type: index
Last Updated: 2026-04-04
Source of Truth: yes

## Summary

本文件用于说明整个 `docs/` 目录怎么读、每类文档分别解决什么问题，以及当文档冲突时以谁为准。

## 阅读顺序

1. [产品需求](01-product/product-requirements.md)
2. [MVP 范围](01-product/mvp-scope.md)
3. [架构总览](02-architecture/architecture-overview.md)
4. [数据模型](02-architecture/data-model.md)
5. [存储策略](02-architecture/storage-strategy.md)
6. [当前执行计划](03-plans/current.md)
7. [当前任务清单](05-tasks/now.md)

## 目录说明

### `01-product/`

回答“做什么”。

- `product-requirements.md`: 产品目标、核心功能、约束、待确认项。
- `mvp-scope.md`: 首版必须做什么、明确不做什么。

### `02-architecture/`

回答“怎么做”。

- `architecture-overview.md`: 技术栈、分层、代码组织建议。
- `data-model.md`: 本地数据库模型、查询模式、索引建议。
- `storage-strategy.md`: 图片文件、缩略图、路径和清理策略。

### `03-plans/`

回答“现在先做什么”。

- `current.md`: 当前有效的执行计划，始终保持最新。
- `2026-04-mvp-bootstrap.md`: 第一阶段实施方案。

### `04-decisions/`

回答“为什么这么定”。

- `ADR-001-local-first-storage.md`: 选择离线优先和本地存储。
- `ADR-002-drift-over-sqflite.md`: 选择 Drift 而不是直接写 sqflite。

### `05-tasks/`

回答“下一步具体做什么”。

- `now.md`: 当前待确认和待实施项。
- `backlog.md`: MVP 之后的候选工作。

### `99-archive/`

存放过期方案和已失效文档，不删除历史，但不作为当前执行依据。

## 冲突处理规则

- 产品范围冲突时，以 `01-product/` 为准。
- 技术方案冲突时，以 `02-architecture/` 和 `04-decisions/` 为准。
- 执行步骤冲突时，以 `03-plans/current.md` 为准。
- 如果两份长期文档冲突，优先看 `Last Updated`，然后人工确认并修订。

## 文档写作规则

- 一个文件只负责一个主题。
- 开头必须包含 `Status`、`Type`、`Last Updated`、`Source of Truth`。
- `Source of Truth: yes` 的文件只能少量存在。
- 讨论结论不要只留在聊天里，要沉淀回文档。
- 做完阶段性工作后，把有效结论回写到长期文档，再更新 `current.md`。
