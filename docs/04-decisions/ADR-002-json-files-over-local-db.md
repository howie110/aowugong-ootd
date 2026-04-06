# ADR-002 使用 JSON 文件而不是本地数据库

Status: accepted
Type: adr
Last Updated: 2026-04-06
Source of Truth: yes
Related: [架构总览](../02-architecture/architecture-overview.md), [数据模型](../02-architecture/data-model.md)

## Context

项目早期曾考虑本地数据库方案，但当前真实数据结构和使用方式是：

- 穿搭总量仍小
- 主要是单机单用户使用
- 查询主要是全量载入后按内存筛选
- 需要尽快形成可读、可迁移、可备份的数据格式

## Decision

当前版本不接数据库，改用：

- `ootd_items.json`
- `ootd_filters.json`
- `ootd_options.json`
- 本地图片文件

## Rationale

- 结构更直观
- 调试更直接
- 更适合导出成 `zip`
- 首次迭代成本更低

## Consequences

### Positive

- 数据格式透明
- 手工排查容易
- 备份和导入实现直接

### Negative

- 数据继续增长后，性能优化空间不如数据库大
- 复杂查询和统计会越来越吃力
- 当前模型和持久化耦合较重

## Rejected Alternative

### 现在就上 Drift 或 sqflite

拒绝原因：

- 当前阶段收益不足以覆盖接入成本
- 备份和迁移实现反而会更重
- 当前最优先的问题不是复杂查询，而是交互打磨和数据兼容

## Revisit Trigger

出现以下任一情况时，再评估数据库：

- 数据量明显增大
- 需要复杂统计
- 需要更细粒度的查询优化
- 需要更强的迁移控制
