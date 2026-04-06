# 数据流

Status: active
Type: architecture-data-flow
Last Updated: 2026-04-06
Source of Truth: yes
Related: [架构总览](architecture-overview.md), [数据模型](data-model.md), [存储策略](storage-strategy.md)

## Summary

当前项目的关键数据流主要有 4 条：

- 应用启动
- 穿搭新增或编辑
- 首页筛选
- 备份导出与导入

## 1. 应用启动流程

```text
main()
  -> bootstrap()
  -> OotdLocalStore 读取本地 JSON
  -> 规范化旧数据路径和选项
  -> ProviderScope 注入初始值
  -> DailyOotdApp
  -> AppShell
```

### 关键点

- 没有本地数据时，穿搭列表为空
- 没有本地筛选时，筛选状态为空
- 没有本地选项时，加载默认内置选项
- 启动时会顺手规范化历史图片路径

## 2. 穿搭新增和编辑流程

```text
用户进入详情页或新增页
  -> 选择图片
  -> 编辑选项
  -> 保存
  -> Notifier 更新内存状态
  -> OotdLocalStore 保存 ootd_items.json
  -> 返回首页后立刻可见
```

### 关键点

- 同一天不能重复新增
- 编辑页和新增页共用同一套布局
- 保存按钮只有内容变更后才可用

## 3. 首页筛选流程

```text
用户点击筛选项
  -> OotdFiltersNotifier.toggleOption()
  -> 更新内存中的 OotdFilterState
  -> 保存 ootd_filters.json
  -> filteredOotdItemsProvider 重新计算
  -> 首页网格刷新
```

### 关键点

- 首页是多选筛选
- 再点一次同一选项会取消
- 所有选项都不选时，显示全部穿搭
- 筛选状态会跨重启保留

## 4. 选项管理流程

```text
设置页 -> 选项管理
  -> 新增 / 编辑 / 删除选项值
  -> 更新 OotdOptionConfig
  -> 必要时同步修正已有穿搭和筛选状态
  -> 保存 ootd_options.json
```

### 关键点

- 删除选项值时，已有穿搭会自动切换到同组选项中的兜底值
- 删除整个自定义组选项时，会同时清理已有穿搭和筛选状态中的该组数据

## 5. 备份导出流程

```text
设置页 -> 数据备份
  -> OotdBackupService.exportBackup()
  -> 生成 manifest.json
  -> 收集被引用的图片文件
  -> 打成 zip
  -> 弹出系统另存为
  -> 记录最近一次导出路径
```

## 6. 备份导入流程

```text
设置页 -> 备份导入
  -> 选择 zip
  -> 读取 manifest 预览
  -> 用户确认
  -> 自动生成回滚备份
  -> 覆盖当前图片和 JSON
  -> Notifier.replaceAll()
  -> UI 刷新
```

## 7. 版本升级流程

```text
新 apk 覆盖安装
  -> 包名和签名一致
  -> 应用私有目录保留
  -> 启动时读取原有 JSON 和图片
  -> 用户继续使用旧数据
```

### 关键前提

- 不能随便改 Android 包名
- 不能丢失 release 签名

## Current Weak Points

- 当前大部分数据流依赖 Notifier 直接写本地文件，耦合较紧
- 缺少更细粒度的单元测试
- 图片删除后的孤儿文件治理还没补
