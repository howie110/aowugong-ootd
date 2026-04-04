# 架构总览

Status: draft
Type: architecture
Last Updated: 2026-04-04
Source of Truth: yes
Related: [数据模型](data-model.md), [存储策略](storage-strategy.md), [ADR-002](../04-decisions/ADR-002-drift-over-sqflite.md)

## Summary

本项目建议采用 `Flutter + Riverpod + Drift + 本地文件系统` 的离线优先架构。首版只保留首页和设置页两个主页面，标签与“不喜欢” OOTD 管理集中在设置页，首页负责拍照/选图入口、历史记录浏览和标签筛选。数据模型以“一天一条 OOTD 记录”为核心，每条记录固定为 `1` 张主图和最多 `3` 张细节图，并带有“喜欢 / 不喜欢”状态。

## Recommended Stack

- Framework: Flutter
- Language: Dart
- State Management: flutter_riverpod
- Database: drift
- Camera: camera
- Crop: image_cropper
- Image Compression: flutter_image_compress
- File Access: path_provider + path

## Layering

### Presentation

负责页面、组件、交互状态。

- 页面示例：首页、设置页、拍照/选图与裁剪流程、独立全屏详情页。
- 不直接操作 SQL。
- 不直接拼接文件路径。

### Application

负责业务流程编排。

- 用例示例：`CreateEntryFromCameraOrGallery`、`MoveEntryToDisliked`、`RestoreEntryToLiked`、`DeleteEntry`、`RenameTag`、`SearchEntries`。
- 处理“先压缩再保存”、“先删数据库再删文件”这类跨服务流程。

### Domain

负责核心模型与接口定义。

- 实体示例：`OotdEntry`、`OotdPhoto`、`Tag`、`EntryFilter`。
- 接口示例：`OotdRepository`、`PhotoStorage`、`CaptureService`。

### Data

负责具体实现。

- Drift table / DAO
- 本地文件读写
- 相机与裁剪插件适配
- Repository 实现

## Suggested Code Layout

```text
lib/
  app/
    app.dart
    router.dart
    providers.dart
  features/
    ootd/
      application/
      data/
        db/
        repositories/
        services/
      domain/
      presentation/
        home/
        capture/
        preview/
    settings/
      presentation/
  shared/
    design/
    utils/
    widgets/
  bootstrap/
    startup.dart
```

## Why Feature-First

- OOTD 是单一主功能产品，按 feature 聚合更容易维护。
- 首页浏览与设置页标签管理会共享同一批领域对象，按 feature 聚合更容易维持边界。
- AI 在读取代码时更容易基于目录推断边界。

## State Management Guidance

- 页面短状态，例如当前选中标签筛选项，可放在 notifier。
- 持久化数据流由 repository 暴露 stream。
- UI 只订阅 view model，不直接订阅表结构。
- 一次性的业务动作通过 use case 触发。
- 设置页改动标签后，首页筛选列表应自动响应刷新。
- 设置页改动 OOTD 的喜欢状态后，首页灵感库应自动响应刷新。
- 详情页照片轮播或滑动索引属于短状态，不应反向污染数据层。

## Performance Guidance

- 列表页只读取状态为 `liked` 的主图缩略图与轻量字段。
- 数据库连接放后台 isolate。
- 首页采用固定比例网格，而不是复杂自适应瀑布流。
- 不在 build 阶段进行图片压缩、路径计算或大对象转换。
- 独立全屏详情页再按需加载同一条记录下的细节图。

## Open Questions

- 暂无架构级未决问题。
