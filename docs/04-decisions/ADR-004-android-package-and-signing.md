# ADR-004 尽早固定 Android 包名和签名

Status: accepted
Type: adr
Last Updated: 2026-06-20
Source of Truth: yes
Related: [发版说明](../06-operations/release.md)

## Context

只要这个 app 要长期安装在同一台设备上持续升级，就不能一直沿用临时包名和 debug 签名，否则会出现：

- 新版本无法覆盖旧版本
- 升级链断掉
- 旧数据无法自然继承

## Decision

当前项目已经固定：

- Android 包名：`com.aowugong.ootd`
- 当前线上打包签名：GitHub Actions 构建时临时生成 `aowugong` release keystore

这能降低首次公开分享 APK 的门槛，但不是长期升级的最佳方案。如果后续有稳定用户，需要替换为固定保存的 release keystore。

## Rationale

- 保障覆盖安装
- 保障数据延续
- 保障长期发布可维护

## Consequences

### Positive

- 包名已经稳定，后续可以建立长期升级链
- 数据继承路径稳定

### Negative

- 当前临时签名构建可能导致新 APK 无法覆盖安装旧 APK
- 长期升级前仍然需要准备并妥善保存固定 keystore

## Operational Rule

- `android/key.properties` 不提交到 git
- `android/keystore/` 不提交到 git
- 任何改包名或改签名的想法，都必须当作高风险变更处理
