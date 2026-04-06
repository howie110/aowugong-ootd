# 项目结构

Status: active
Type: architecture-structure
Last Updated: 2026-04-06
Source of Truth: yes
Related: [架构总览](architecture-overview.md)

## Summary

当前仓库结构已经稳定到可以长期维护。目录遵循“应用壳 + 启动层 + 按功能拆分 + 共用层”的组织方式。

## Repository Layout

```text
android/         Android 工程、签名、图标、包名
assets/          仓库内静态资源
docs/            产品、架构、操作、决策文档
lib/             Flutter 业务代码
test/            Widget 测试
README.md        项目入口说明
CHANGELOG.md     版本变化记录
pubspec.yaml     依赖与版本号
```

## `lib/` Layout

```text
lib/
  app/
    app.dart
    app_metadata.dart
    providers.dart
    router.dart
  bootstrap/
    startup.dart
  features/
    ootd/
      data/
        local_ootd_store.dart
      presentation/
        detail/
          ootd_detail_page.dart
          photo_selection_page.dart
        home/
          home_page.dart
          mock_ootd_items.dart
        shared/
    settings/
      data/
        ootd_backup_service.dart
      presentation/
        settings/
          settings_page.dart
          option_management_page.dart
          backup_export_page.dart
          backup_import_page.dart
          settings_placeholder_page.dart
  shared/
    design/
```

## Directory Responsibility

### `app/`

- 根应用配置
- 页面壳
- 版本信息
- 根级 Provider

### `bootstrap/`

- 启动初始化
- 本地数据读取
- 初始状态注入

### `features/ootd/`

- 穿搭数据持久化
- 首页浏览
- 详情编辑
- 图片选择

### `features/settings/`

- 选项管理
- 备份导出
- 备份导入
- 设置占位页

### `shared/`

- 主题
- 共享样式
- 可复用 UI 能力

## Notable Current Technical Debt

- `mock_ootd_items.dart` 名字已不符合其真实职责
- `features/ootd/presentation/home/` 中混有模型、状态和业务逻辑
- 当前目录足够支撑小型项目，但未来复杂度继续增长时建议继续拆分

## Recommended Next Refactor

- 从 `mock_ootd_items.dart` 拆出 `models.dart`、`providers.dart`、`option_config.dart`
- 给 `settings` 下的备份相关页面补更清晰的子目录
- 为图片相关逻辑建立独立 service 文件
