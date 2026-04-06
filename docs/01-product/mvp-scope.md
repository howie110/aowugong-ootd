# MVP 范围

Status: active
Type: product-scope
Last Updated: 2026-04-06
Source of Truth: yes
Related: [产品需求](product-requirements.md), [当前执行计划](../03-plans/current.md)

## Summary

本文件描述当前已经成型、适合继续稳定迭代的版本边界。它不再是“准备进入开发”的草案，而是“当前稳定基线”的定义。

## Current Stable Scope

### 已纳入当前稳定版本

- Android Flutter 应用壳
- 正式应用名“每日穿搭”
- 正式包名 `com.aowugong.ootd`
- 首页穿搭浏览
- 多维度筛选
- 穿搭详情编辑
- 新增穿搭
- 删除穿搭
- 单日唯一约束
- 最多 `4` 张图
- 选项管理
- 备份导出
- 备份导入
- 版本号管理
- `release apk` 打包

### 明确后置

- iOS 发版
- 云同步
- 自动换机迁移引导页
- 帮助中心正式内容
- 版本信息正式内容
- 统计分析
- 图像高级编辑
- Web、桌面端支持

## UX Boundary

- 当前主入口只有“穿搭”和“设置”两个 tab。
- 穿搭页承担浏览、筛选、进入新增和详情。
- 详情页承担查看和编辑，不再拆独立编辑页。
- 设置页承担选项管理和数据迁移入口。

## Data Boundary

- 当前持久化方案是 JSON + 图片文件，不是数据库。
- 当前备份方案是 `zip`。
- 当前图片使用 app 管理目录中的文件路径，不长期依赖系统相册路径。

## Engineering Boundary

- 当前优先保证 Android 真机可安装、可升级、可继承旧数据。
- 当前正式包必须保持稳定包名与签名。
- 当前任何数据结构调整，都必须考虑旧版本数据兼容。

## Exit Criteria For Next Stage

达到以下条件后，可进入下一轮功能优化：

- 手动自测一轮真实使用流程
- 覆盖安装验证通过
- 备份导出和导入验证通过
- 文档与当前实现保持一致

## Next Focus

- 在真实使用中收集交互问题
- 针对录入效率、筛选效率和备份体验继续优化
- 在不破坏升级链的前提下迭代 UI 和数据结构
