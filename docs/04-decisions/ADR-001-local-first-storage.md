# ADR-001 离线优先与本地存储

Status: accepted
Type: adr
Last Updated: 2026-04-06
Source of Truth: yes
Related: [产品需求](../01-product/product-requirements.md), [存储策略](../02-architecture/storage-strategy.md)

## Context

本项目是个人穿搭记录应用，首要目标是：

- 隐私优先
- 无网络也能用
- 尽快形成可安装、可迭代版本

## Decision

当前版本坚持离线优先：

- 穿搭、筛选、选项全部保存在本地
- 图片保存到 app 管理目录
- 备份使用本地 `zip`
- 不依赖服务端

## Rationale

- 开发路径最短
- 复杂度可控
- 数据可直接排查
- 更适合单用户单设备起步

## Consequences

### Positive

- 断网可用
- 隐私风险低
- 调试和备份简单

### Negative

- 没有自动云同步
- 换机需要手动导出和导入
- 后续如果做同步，需要重新设计冲突和迁移

## Follow-Up

- 通过 `zip` 备份弥补换机和重装场景
- 未来如果要做云同步，仍以“本地为主，云为增强”作为原则
