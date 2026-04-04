# ADR-001 离线优先与本地存储

Status: proposed
Type: adr
Last Updated: 2026-04-04
Source of Truth: yes
Related: [产品需求](../01-product/product-requirements.md), [存储策略](../02-architecture/storage-strategy.md)

## Context

本产品的核心价值之一是私人穿搭记录。用户对隐私和即时可用性都有要求，同时首版希望降低后端复杂度和成本。

## Decision

首版采用离线优先方案：

- 结构化数据存本地数据库。
- 图片文件存 App 私有目录。
- 创建 OOTD 时允许从系统相册选择图片，但入库前统一复制到 App 私有目录。
- 不将 OOTD 成品照片回写到系统相册。
- 不依赖云端 API 才能完成核心功能。

## Rationale

- 隐私风险最低。
- 首版交付路径最短。
- 无网络环境下仍可完整使用。
- 数据模型和 UI 流程不会被同步机制干扰。

## Consequences

### Positive

- 架构简单，首版开发效率更高。
- 启动速度更快，核心操作不依赖网络。
- 更容易先验证真实使用习惯。

### Negative

- 无法自动跨设备同步。
- 卸载 App 后若无备份会丢失数据。
- 未来若加同步，需要设计冲突合并和数据迁移。

## Follow-Up

- MVP 后评估是否增加导出/备份。
- 如果未来增加云同步，本 ADR 仍可保留为“本地为主、云端为可选增强”。
