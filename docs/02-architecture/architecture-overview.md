# 架构总览

Status: active
Type: architecture
Last Updated: 2026-04-06
Source of Truth: yes
Related: [项目结构](project-structure.md), [数据流](data-flow.md), [存储策略](storage-strategy.md)

## Summary

当前项目采用 `Flutter + Riverpod + 本地 JSON + 本地图片文件 + zip 备份` 的离线优先架构。代码已经实现基础产品闭环，不再使用“数据库 + Drift”方案。

## Current Stack

- Framework: Flutter
- Language: Dart
- State Management: `flutter_riverpod`
- Local Persistence: `dart:io` + JSON 文件
- Path Utilities: `path` + `path_provider`
- Photo Input: `image_picker` + `photo_manager` + `camera`
- Image Processing: `image_cropper` + `flutter_image_compress`
- Backup: `archive` + `file_picker` + `share_plus`
- Testing: `flutter_test`

## High-Level Structure

### Bootstrap

- 入口在 `lib/main.dart`
- `bootstrap/startup.dart` 负责初始化 Flutter、读取本地文件、修正旧数据，再通过 `ProviderScope` 注入初始状态

### App Shell

- `lib/app/app.dart` 定义 `MaterialApp`
- `lib/app/router.dart` 定义应用壳、顶部标题、底部导航和页面切换动画
- 当前主 tab 只有“穿搭”和“设置”

### Feature Layer

- `features/ootd/` 负责穿搭数据、首页、详情页、选图页
- `features/settings/` 负责选项管理、备份导出、备份导入和占位页

### Shared Layer

- `shared/design/` 放主题和通用设计系统
- `shared/` 下其余目录放跨 feature 共用的组件和样式

## State Architecture

当前项目没有单独抽出 repository/use case/domain 三层，而是采用更轻量、直接的实现：

- 数据模型、默认值、部分业务规则集中在 `mock_ootd_items.dart`
- `NotifierProvider` 持有穿搭列表、筛选状态和选项配置
- 每次状态变更后，直接通过 `OotdLocalStore` 写回本地 JSON

当前这样做的原因：

- 项目体量仍小
- 单机离线逻辑相对集中
- 可以用较少抽象快速迭代

当前明显技术债：

- `mock_ootd_items.dart` 这个文件名已经不准确，里面承载了真实业务模型和持久化逻辑入口，后续可拆分重命名

## Navigation Strategy

- 主导航：底部 `NavigationBar`
- 页面切换：`AnimatedSwitcher`
- 子页面：`MaterialPageRoute`
- 穿搭详情和设置子页面都以 push 方式进入

## Persistence Strategy

- 穿搭列表：`ootd_items.json`
- 首页筛选：`ootd_filters.json`
- 选项配置：`ootd_options.json`
- 最近导出备份信息：`ootd_backup_meta.json`
- 本地图片：`daily_ootd/images/`

## Why No Local Database For Now

- 当前数据结构仍然轻量
- 查询模式主要是全量读入后内存筛选
- 当前优先保证数据可迁移、可理解、可排查
- JSON 文件更利于备份和手工验证

## Current Architecture Strengths

- 依赖少
- 本地数据结构透明
- 调试简单
- 备份逻辑直接
- 适合当前单用户、单设备优先的产品阶段

## Current Architecture Risks

- 模型、状态、持久化写在同一特性文件里，后期会变重
- 数据量继续增大后，全量加载再筛选的方式可能需要优化
- 未来如果接入同步或统计能力，当前结构需要进一步拆层

## Recommended Refactor Direction

- 拆出 `models/`、`providers/`、`services/`
- 把 `mock_ootd_items.dart` 重命名为真实业务文件
- 为备份、图片和持久化补更完整的单元测试
- 如果数据规模明显增长，再评估数据库方案
