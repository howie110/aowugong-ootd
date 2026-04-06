# 数据模型

Status: active
Type: architecture-data
Last Updated: 2026-04-06
Source of Truth: yes
Related: [存储策略](storage-strategy.md), [数据流](data-flow.md)

## Summary

当前版本的数据模型围绕 4 类持久化对象组织：

- 穿搭列表
- 首页筛选状态
- 选项配置
- 最近一次导出备份的信息

这些对象以 JSON 文件形式落盘。

## Core Entity: OOTD Item

当前单条穿搭对应 `MockOotdItem`，虽然名字还带 `Mock`，但它已经是实际业务模型。

### 字段

- `id`: 唯一标识
- `images`: 图片列表，长度限制 `1..4`
- `dateLabel`: 日期字符串，格式为 `YYYY-MM-DD`
- `preference`: 偏好选项，例如 `喜欢`
- `season`: 季节选项，例如 `春`
- `scene`: 场景选项，例如 `工作`
- `tone`: 色调选项，例如 `冷色`
- `rating`: 评星选项，例如 `4星`
- `extraSelections`: 自定义选项组对应的值

### 约束

- 每条穿搭至少 `1` 张图
- 每条穿搭最多 `4` 张图
- `dateLabel` 在当前数据集中必须唯一
- 第一张图默认是主图

## Image Entity

当前单张图片对应 `MockOotdImage`。

### 字段

- `id`
- `sourceType`
- `path`
- `colorValue`

### 当前支持的图片来源类型

- `asset`: 仅用于仓库内演示资源或历史兼容
- `file`: 实际保存在 app 管理目录中的文件
- `solidColor`: 用于占位的纯色图

### 当前真实持久化关注点

长期真实数据主要依赖 `file` 类型。`asset` 和 `solidColor` 主要是为了兼容已有数据与占位场景。

## Filter State

首页筛选状态对应 `OotdFilterState`。

### 字段

- `preferences`
- `seasons`
- `scenes`
- `tones`
- `ratings`
- `extraSelections`

### 规则

- 首页筛选是多选
- 某一组为空时，表示该组不限制
- 所有组都为空时，首页显示全部穿搭

## Option Config

选项配置对应 `OotdOptionConfig`。

### 内置组选项

- `preferences`
- `seasons`
- `scenes`
- `tones`
- `ratings`

### 扩展字段

- `extraGroups`: 自定义选项组
- `hiddenBuiltInKeys`: 被隐藏的内置组选项 key

### 当前默认值

- 偏好：`喜欢`、`不喜欢`
- 季节：`春`、`夏`、`秋`、`冬`
- 场景：`工作`、`休息`
- 色调：`黑白`、`冷色`、`暖色`
- 评星：`1星` 到 `5星`

## Backup Metadata

`ootd_backup_meta.json` 只记录最近一次导出备份文件的路径，用于让设置页重新进入时还能看到最近导出的文件信息。

## First Install Defaults

首次安装时：

- `ootd_items.json` 不存在，因此初始穿搭列表为空
- `ootd_filters.json` 不存在，因此筛选状态为空
- `ootd_options.json` 不存在，因此加载默认内置选项

## JSON File Mapping

```text
ootd_items.json        -> List<MockOotdItem>
ootd_filters.json      -> OotdFilterState
ootd_options.json      -> OotdOptionConfig
ootd_backup_meta.json  -> 最近一次导出 zip 的路径
```

## Backup Manifest Model

导出的 `zip` 中包含 `manifest.json`，核心字段为：

- `backupFormatVersion`
- `appVersion`
- `exportedAt`
- `items`
- `filters`
- `options`
- `images`

## Data Model Evolution Direction

- 后续可以把当前模型从 `mock_ootd_items.dart` 中拆出
- 如果将来增加备注、统计或同步信息，再扩展 JSON 模型
- 如果数据量显著增大，再评估数据库化
