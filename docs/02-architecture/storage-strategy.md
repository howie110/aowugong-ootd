# 存储策略

Status: active
Type: architecture-storage
Last Updated: 2026-04-06
Source of Truth: yes
Related: [数据模型](data-model.md), [ADR-001](../04-decisions/ADR-001-local-first-storage.md), [ADR-003](../04-decisions/ADR-003-zip-backup-format.md)

## Summary

当前项目使用“JSON + 图片文件 + zip 备份”的存储策略。它不是数据库方案，也不长期引用系统相册原路径。

## Application Data Directory

当前 app 的主数据目录名为：

```text
daily_ootd
```

该目录位于 `getApplicationDocumentsDirectory()` 下。

## Persistent File Layout

```text
<ApplicationDocuments>/daily_ootd/
  ootd_items.json
  ootd_filters.json
  ootd_options.json
  ootd_backup_meta.json
  images/
    ootd_<timestamp>.jpg
```

## What Is Actually Stored

### `ootd_items.json`

保存穿搭本体和图片引用关系。

### `ootd_filters.json`

保存首页筛选状态。

### `ootd_options.json`

保存内置组和自定义组选项。

### `ootd_backup_meta.json`

保存最近一次导出成功的 `zip` 完整路径。

### `images/`

保存 app 真正管理的穿搭图片文件。

## Image Path Strategy

- 图片进入 app 后，会复制到 app 管理目录
- JSON 中优先保存相对路径
- 运行时再通过数据根目录解析成绝对路径

这样做的原因：

- 更利于备份和恢复
- 更利于跨安装路径迁移
- 更利于排查路径问题

## Why There Is No `captured_images/`

当前已经明确不单独维护 `captured_images/`。

拍照后的正确链路是：

1. 拍照或选图
2. 进入当前选择流程
3. 真正保存为穿搭时，再复制到 app 管理目录

也就是说，只有“已纳入穿搭数据”的图片才进入 `images/`。

## Backup Export Strategy

### 导出时

1. 读取当前穿搭、筛选、选项
2. 收集被穿搭引用的本地图片
3. 生成 `manifest.json`
4. 打包成 `zip`
5. 弹出系统另存为窗口，让用户自己选择保存路径
6. 记录最近一次导出成功的保存路径

### 导出结果

最终备份文件不强制落在 `Android/data/...`，而是由用户决定保存位置。当前推荐保存到 `Download`。

## Backup Import Strategy

### 导入时

1. 用户选择一个 `zip`
2. 先读取并预览 `manifest.json`
3. 用户确认导入
4. 自动生成一份回滚备份
5. 删除当前 `images/`
6. 写入备份中的图片
7. 写入新的 `ootd_items.json`、`ootd_filters.json`、`ootd_options.json`

## Rollback Backup Strategy

导入前自动生成回滚备份，便于导入失败时恢复当前数据。

回滚备份用于内部安全兜底，不作为用户主导出的主要体验入口。

## File Naming Strategy

当前图片文件名规则：

```text
ootd_<microsecondsSinceEpoch>.<ext>
```

这个策略的特点：

- 简单
- 基本避免重名
- 不依赖用户输入

## Deletion Strategy

删除整条穿搭时：

- 从内存状态移除
- 持久化新的 `ootd_items.json`

当前实现没有额外做图片级垃圾回收扫描。未来如果发现孤儿图片积累，再补清理策略。

## Compatibility Strategy

- 首次安装没有 `ootd_items.json` 时，初始化为空穿搭列表
- 旧数据中的绝对路径会尝试规范化为相对路径
- 导入备份时使用 `backupFormatVersion` 约束格式兼容

## Future Improvements

- 增加图片孤儿文件清理
- 增加备份校验信息
- 增加更明确的导入冲突提示
