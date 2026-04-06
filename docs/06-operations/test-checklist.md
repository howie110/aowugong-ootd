# 测试清单

Status: active
Type: operations-test-checklist
Last Updated: 2026-04-06
Source of Truth: yes
Related: [发版说明](release.md), [调试与运行](debug-and-run.md)

## Summary

每次准备交付新 apk 前，至少走完这份检查单。

## Automated Checks

- [ ] `flutter test`
- [ ] `flutter build apk --debug`
- [ ] `flutter build apk --release`

## First Install Checks

- [ ] 卸载设备上已有 app
- [ ] 安装新 apk
- [ ] 首次打开时默认没有穿搭数据
- [ ] 默认内置选项存在
- [ ] app 名称显示为“每日穿搭”
- [ ] 图标显示为衣服图标

## Basic Functional Checks

- [ ] 首页正常显示穿搭
- [ ] 首页筛选正常工作
- [ ] 筛选状态重开 app 后仍保留
- [ ] 新增穿搭成功
- [ ] 同一天不能重复新增
- [ ] 详情页可编辑并保存
- [ ] 删除穿搭需要确认，且删除后确实消失
- [ ] 图片可点击放大

## Option Management Checks

- [ ] 可新增自定义选项组
- [ ] 可新增组选项内容
- [ ] 可编辑选项内容
- [ ] 可删除选项内容
- [ ] 可删除整组选项

## Backup Checks

- [ ] 数据备份可生成 `zip`
- [ ] 能看到最近一次导出的文件信息
- [ ] 重进页面后最近一次导出信息仍存在
- [ ] 可分享导出的 `zip`
- [ ] 备份导入前可预览 `zip`
- [ ] 备份导入成功后数据恢复正确

## Upgrade Checks

- [ ] 安装旧 release 版本并制造测试数据
- [ ] 直接覆盖安装新 release 版本
- [ ] 打开后旧数据仍在
- [ ] 选项配置仍在
- [ ] 图片仍可打开

## Manual Regression Notes

- [ ] 没有明显页面卡顿
- [ ] 页面切换动画没有叠影或重影
- [ ] 选择图片流程正常
- [ ] 模拟器和真机行为没有明显不一致
