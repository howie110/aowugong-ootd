# 数据模型

Status: draft
Type: architecture-data
Last Updated: 2026-04-04
Source of Truth: yes
Related: [产品需求](../01-product/product-requirements.md), [存储策略](storage-strategy.md)

## Summary

数据模型遵循两个原则：

- OOTD 记录与图片文件分层建模，记录是核心业务对象，图片是其子对象。
- 主图即首页展示图，细节图仅在全屏详情中加载。
- 高查询频率、可排序或可范围筛选的字段使用结构化列。
- 可多选、可复用的筛选信息使用标签关联表。

## Core Tables

### `ootd_entries`

每条穿搭记录一行。当前产品规则是每个自然日最多一条记录，每条记录可包含多张照片。

建议字段：

- `id`: 主键
- `day_key_local`: 本地日期键，例如 `2026-04-04`
- `captured_at_utc_ms`: 拍摄时间，UTC 毫秒
- `captured_tz_offset_min`: 拍摄时区偏移，分钟
- `preference_status`: `liked` 或 `disliked`
- `note`: 备注，可空
- `created_at_ms`
- `updated_at_ms`

### `ootd_photos`

同一条 OOTD 下的照片集合。

建议字段：

- `id`
- `entry_id`
- `photo_rel_path`
- `thumb_rel_path`
- `width`
- `height`
- `file_size_bytes`
- `sort_order`
- `is_cover`
- `source_type`: `camera` 或 `gallery`
- `created_at_ms`
- `updated_at_ms`

### `tags`

标签主表。

建议字段：

- `id`
- `name`
- `color_hex`
- `created_at_ms`
- `updated_at_ms`

### `entry_tags`

穿搭记录与标签的多对多关系表。

建议字段：

- `entry_id`
- `tag_id`

## Confirmed Constraints

- `day_key_local` 在首版必须唯一，代表一天一条记录。
- `ootd_photos(entry_id, sort_order)` 必须唯一，用于稳定展示多角度顺序。
- 每条 `ootd_entries` 固定为 `1` 张主图和最多 `3` 张细节图，总数限制在 `1..4` 张。
- 每条 `ootd_entries` 必须且只能有一张主图，主图即封面图。
- `preference_status` 默认值为 `liked`。
- `tags(name)` 唯一，避免重复标签。
- `entry_tags(entry_id, tag_id)` 使用复合主键。
- 删除标签时，只删除 `entry_tags` 关联，不删除 `ootd_entries`。
- 重命名标签时，由于记录关联的是 `tag_id`，所有历史记录自动显示新名称。

## Suggested Indexes

- `idx_entries_day` on `day_key_local DESC`
- `idx_entries_captured` on `captured_at_utc_ms DESC`
- `idx_entries_preference_day` on `(preference_status, day_key_local DESC)`
- `idx_photos_entry_order` on `(entry_id, sort_order)`
- `idx_photos_entry_cover` on `(entry_id, is_cover)`
- `uidx_photos_one_cover_per_entry` on `entry_id where is_cover = 1`
- `idx_entry_tags_tag` on `(tag_id, entry_id)`
- `idx_tags_name` on `name`

## Query Patterns To Optimize

- 查询最近 N 条“喜欢”记录，用于首页灵感库。
- 查询记录及其封面图，用于首页网格。
- 查询单条记录下的全部照片，用于独立全屏详情页左右滑动查看。
- 查询全部标签，用于首页筛选和设置页管理。
- 查询全部“不喜欢”记录，用于设置页恢复。
- 按一个或多个标签筛选。
- 重命名标签后刷新所有关联记录的显示结果。

## Example SQL

```sql
CREATE TABLE ootd_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  day_key_local TEXT NOT NULL UNIQUE,
  captured_at_utc_ms INTEGER NOT NULL,
  captured_tz_offset_min INTEGER NOT NULL,
  preference_status TEXT NOT NULL DEFAULT 'liked'
    CHECK (preference_status IN ('liked', 'disliked')),
  note TEXT,
  created_at_ms INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL
);

CREATE TABLE ootd_photos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entry_id INTEGER NOT NULL,
  photo_rel_path TEXT NOT NULL,
  thumb_rel_path TEXT NOT NULL,
  width INTEGER NOT NULL,
  height INTEGER NOT NULL,
  file_size_bytes INTEGER NOT NULL,
  sort_order INTEGER NOT NULL CHECK (sort_order BETWEEN 1 AND 4),
  is_cover INTEGER NOT NULL CHECK (is_cover IN (0, 1)),
  source_type TEXT NOT NULL CHECK (source_type IN ('camera', 'gallery')),
  created_at_ms INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL,
  FOREIGN KEY (entry_id) REFERENCES ootd_entries(id) ON DELETE CASCADE,
  UNIQUE(entry_id, sort_order)
);

CREATE UNIQUE INDEX uidx_photos_one_cover_per_entry
ON ootd_photos(entry_id)
WHERE is_cover = 1;

CREATE TABLE tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  color_hex TEXT,
  created_at_ms INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL
);

CREATE TABLE entry_tags (
  entry_id INTEGER NOT NULL,
  tag_id INTEGER NOT NULL,
  PRIMARY KEY (entry_id, tag_id),
  FOREIGN KEY (entry_id) REFERENCES ootd_entries(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);
```

## Open Questions

- 暂无数据模型级未决问题。
