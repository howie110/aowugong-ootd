# ADR-003 使用 `zip` 作为备份格式

Status: accepted
Type: adr
Last Updated: 2026-04-06
Source of Truth: yes
Related: [存储策略](../02-architecture/storage-strategy.md), [发版说明](../06-operations/release.md)

## Context

项目需要解决两类迁移场景：

- 用户安装新版本 apk 后，继续沿用旧数据
- 用户换手机时，把数据从旧设备带到新设备

当前数据同时包含结构化信息和图片文件，不适合只导出单个 JSON。

## Decision

备份文件统一使用 `zip`。

`zip` 中包含：

- `manifest.json`
- 穿搭数据
- 筛选数据
- 选项配置
- 被穿搭引用的图片文件

## Rationale

- 一个文件最容易让用户传递
- 结构化数据和图片可以一起打包
- Android 文件系统和分享流程都容易处理
- 后续增加 `backupFormatVersion` 也方便

## Consequences

### Positive

- 适合换机
- 适合手动备份
- 导入时可先预览 manifest

### Negative

- 仍然需要用户自己选择保存位置
- 大量图片时备份文件会变大
- 需要维护格式版本兼容

## Follow-Up

- 保持 `manifest.json` 稳定
- 后续格式变更时递增 `backupFormatVersion`
- 重要字段变动时补迁移和兼容说明
