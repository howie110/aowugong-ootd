# 2026-04 MVP 启动计划

Status: draft
Type: implementation-plan
Last Updated: 2026-04-04
Source of Truth: no
Related: [当前执行计划](current.md), [当前任务清单](../05-tasks/now.md)

## Summary

本计划描述在文档确认完成后，如何以较低风险启动项目并尽快打通最小闭环。

## Phase 0: Confirm Design

- 确认产品范围与非目标。
- 确认数据库主表和标签模型。
- 确认图片存储目录与缩略图策略。
- 确认首页与设置页的交互方向。

## Phase 1: Bootstrap Project

- 创建 Flutter 工程。
- 配置 Android 首发所需的基础设置。
- 接入核心依赖。
- 建立基础目录结构。
- 搭建最小路由和主题。

## Phase 2: Data Foundation

- 建立 Drift 数据库。
- 建立 `ootd_entries`、`ootd_photos`、`tags`、`entry_tags`。
- 建立 repository 接口和实现。
- 建立本地文件存储服务。
- 写入基础数据流和增删改查测试。

## Phase 3: Capture Flow

- 集成相机。
- 集成系统相册选图。
- 集成裁剪。
- 集成压缩。
- 打通保存流程。
- 处理失败回滚。

## Phase 4: Browse Flow

- 实现最近记录首页。
- 实现首页网格浏览。
- 接入首页标签筛选。
- 接入标记“不喜欢”和恢复流程。
- 接入独立全屏详情页。
- 实现设置页标签管理与“不喜欢”记录管理。

## Phase 5: Stabilization

- 做真机性能验证。
- 检查大批量图片滚动。
- 处理空状态和错误状态。
- 补齐关键测试。

## Risk Hotspots

- Android 各机型相机兼容性。
- 图片裁剪后的文件管理。
- 大列表下图片解码与内存占用。
- 文件和数据库之间的一致性维护。
