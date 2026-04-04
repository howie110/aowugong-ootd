# 当前执行计划

Status: active
Type: plan
Last Updated: 2026-04-04
Source of Truth: yes
Related: [产品需求](../01-product/product-requirements.md), [MVP 范围](../01-product/mvp-scope.md), [2026-04 MVP 启动计划](2026-04-mvp-bootstrap.md)

## Summary

当前阶段目标不是写代码，而是把产品范围、架构边界和数据方案确认到足够稳定。当前已明确首版只保留首页和设置页、首页采用固定比例网格、详情采用独立全屏、照片只保存在 App 私有目录，并且每天只允许一条 OOTD 记录，该记录固定为 `1` 张主图和最多 `3` 张细节图，同时带有“喜欢 / 不喜欢”状态。

## Current Goal

完成“文档确认阶段”，得到一套可以直接转化为开发任务的共识版本。

## Review Order

建议按以下顺序逐份确认：

1. [产品需求](../01-product/product-requirements.md)
2. [MVP 范围](../01-product/mvp-scope.md)
3. [数据模型](../02-architecture/data-model.md)
4. [存储策略](../02-architecture/storage-strategy.md)
5. [架构总览](../02-architecture/architecture-overview.md)
6. [关键 ADR](../04-decisions/ADR-001-local-first-storage.md)
7. [当前任务清单](../05-tasks/now.md)

## Decision Gates

关键交互与存储决策已基本确认。进入编码前，剩余工作主要是对文档本身做最终确认。

## Done Definition For This Stage

以下条件满足后，文档确认阶段结束：

- `01-product/` 下两个文件被你确认。
- `02-architecture/` 下三个文件被你确认。
- 两份 ADR 无反对意见。
- `05-tasks/now.md` 中第 0 阶段任务全部转为 accepted。

## Next Stage

文档确认后，进入以下工作：

1. 初始化 Flutter 项目。
2. 建立推荐目录结构。
3. 接入核心依赖。
4. 建立 Drift 数据库与基础表。
5. 打通最小闭环：拍照/选图 -> 裁剪 -> 压缩 -> 存储 -> 首页固定网格展示 -> 标签筛选 -> 标记不喜欢/恢复 -> 独立全屏详情。
