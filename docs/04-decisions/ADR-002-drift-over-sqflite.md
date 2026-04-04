# ADR-002 使用 Drift 而不是直接使用 sqflite

Status: proposed
Type: adr
Last Updated: 2026-04-04
Source of Truth: yes
Related: [架构总览](../02-architecture/architecture-overview.md), [数据模型](../02-architecture/data-model.md)

## Context

本项目需要：

- 本地关系型数据建模
- 多条件筛选
- 首页列表和标签筛选的响应式刷新
- 可维护的数据访问层

直接使用 `sqflite` 可以完成这些能力，但需要手写更多 SQL、映射代码和监听逻辑。

## Decision

首版建议使用 Drift 作为本地数据库访问层，而不是直接基于 `sqflite` 手写数据库逻辑。

## Rationale

- 类型安全更好。
- 查询组合和表关系表达更清晰。
- 与 Flutter 本地响应式数据流更契合。
- 后续迁移和重构成本更低。

## Consequences

### Positive

- 数据访问层更稳定。
- 代码可读性更高。
- 更适合长期维护和 AI 协作。

### Negative

- 初次接入比 `sqflite` 多一层生成代码和工具链。
- 团队需要接受 Drift 的写法和组织方式。

## Rejected Alternative

### 直接使用 sqflite

拒绝原因：

- 首版看似简单，后续在复杂筛选和维护上会更重。
- Repository 和 DAO 层会出现较多样板代码。
- 响应式查询能力不如 Drift 顺手。
