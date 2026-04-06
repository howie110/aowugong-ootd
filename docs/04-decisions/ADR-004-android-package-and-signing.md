# ADR-004 尽早固定 Android 包名和签名

Status: accepted
Type: adr
Last Updated: 2026-04-06
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
- release 签名：使用项目自己的 keystore

## Rationale

- 保障覆盖安装
- 保障数据延续
- 保障长期发布可维护

## Consequences

### Positive

- release 包可以长期升级
- 数据继承路径稳定

### Negative

- keystore 必须妥善保存
- 签名丢失会直接影响后续发版

## Operational Rule

- `android/key.properties` 不提交到 git
- `android/keystore/` 不提交到 git
- 任何改包名或改签名的想法，都必须当作高风险变更处理
