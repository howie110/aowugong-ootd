# 公开项目检查清单

Status: active
Type: operations-publication
Last Updated: 2026-06-20
Source of Truth: yes

## Required Before Public Release

- README 能让陌生用户在 30 秒内知道这个 app 是什么、能解决什么问题、怎么下载
- GitHub Releases 至少有一个可下载 APK
- `CHANGELOG.md` 记录当前版本变更
- `pubspec.yaml`、`lib/app/app_metadata.dart`、README、发版文档里的版本号一致
- 选择并提交 `LICENSE`
- 不提交 `android/key.properties`、`android/keystore/`、token、密码、私钥
- Release APK 使用固定包名；如果要支持长期覆盖升级，需要改用固定保存的 release keystore
- 真机安装、首次打开、覆盖升级、备份导入导出都验证过

## Recommended Project Files

- `README.md`: 项目首页、功能亮点、下载入口、隐私说明、开发入口
- `CHANGELOG.md`: 每个版本改了什么
- `LICENSE`: 代码授权，推荐先明确是否开源
- `SECURITY.md`: 漏洞反馈方式
- `CONTRIBUTING.md`: 外部贡献规则
- `.github/workflows/`: CI 和 Release 自动化
- `.github/repository-about.md`: GitHub About 描述、topics 和预览图建议
- `.github/ISSUE_TEMPLATE/`: bug 和功能建议模板

## README Images

公开项目建议准备 3 到 5 张真实截图：

- 首页列表或网格
- 新增/编辑穿搭
- 多维筛选
- 选项管理
- 备份导入导出

图片建议放在：

```text
docs/assets/screenshots/
```

不要使用与真实界面不一致的合成截图。截图里的穿搭照片应使用自己拍摄、自己生成且授权清楚、或明确可商用/可再分发的素材。

## Copyright And Infringement Rules

公开仓库前逐项确认：

- 代码：自己写的代码可以按你选择的 license 授权；第三方依赖要确认 license 兼容
- 图片：不能直接使用网上找来的穿搭图、人物图、商品图，除非许可明确允许再分发
- 图标：应用图标、README 图标、宣传图里的素材要可商用或自有
- 品牌：不要把第三方品牌 logo、商标、商品图作为项目宣传主素材
- 人像：真人照片需要拍摄者和出镜者授权，公开项目尤其要谨慎
- AI 图片：也要确认生成服务的使用条款，并避免生成近似真实名人或品牌广告图
- 数据：不要提交真实用户照片、备份 zip、日志或设备路径

如果素材来源不清楚，默认不要放进仓库和 APK。

## Privacy Notes

本项目是离线优先 app，公开说明里应持续保持以下承诺与实现一致：

- 不需要账号
- 不上传穿搭照片
- 数据保存在本机
- 备份 zip 由用户主动导出和分享
- Android 图片权限只用于用户选择和管理本机图片

如果以后增加联网、云同步、统计、崩溃上报或广告，需要同步更新 README 和隐私说明。

## Release Page Copy

每个 GitHub Release 建议包含：

```text
## 下载

- Android APK: 见本 Release 附件

## 本版变化

- ...

## 安装提示

- 这是 GitHub 分发的 APK，Android 可能提示“未知来源”
- 覆盖安装前请确认旧版本也是同一包名和同一签名；当前临时签名构建可能需要先卸载旧版

## 数据提醒

- 升级通常会保留本地数据
- 卸载 app 会删除本地数据，重要数据请先导出备份
```

## License Decision

常见选择：

- MIT: 简短宽松，适合个人开源项目
- Apache-2.0: 宽松，并包含更明确的专利授权条款
- GPL-3.0: 要求衍生分发也开源，约束更强
- 不开源: 不添加开源 license，只提供 APK 下载和源码可见性限制

在没有 `LICENSE` 文件前，即使 GitHub 仓库公开，也不等于别人自动获得复制、修改、再分发源码的许可。
