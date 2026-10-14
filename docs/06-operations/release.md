# 发版说明

Status: active
Type: operations-release
Last Updated: 2026-09-29
Source of Truth: yes
Related: [ADR-004](../04-decisions/ADR-004-android-package-and-signing.md), [测试清单](test-checklist.md)

## Summary

当前项目已经具备正式 `release apk` 打包能力，并支持通过 GitHub Actions 在线打包上传到 GitHub Releases。发版时最重要的 3 件事：

- 版本号正确
- 包名不变
- 签名策略清楚

## Current Release Identity

- App 名称：`每日穿搭`
- 包名：`com.aowugong.ootd`
- 当前版本：`1.0.8+9`

## Version Files

每次发版至少检查这两个位置：

- `pubspec.yaml`
- `lib/app/app_metadata.dart`

## Release Build Command

在项目根目录执行：

```powershell
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
flutter build apk --release --no-tree-shake-icons
```

## Release APK Output

```text
build/app/outputs/flutter-apk/app-release.apk
```

## GitHub Release Build

仓库包含 GitHub Actions workflow：

```text
.github/workflows/android-release.yml
```

推送形如 `v1.0.8` 的 tag 后，GitHub 会自动执行：

```text
flutter pub get
flutter test
flutter build apk --release --no-tree-shake-icons
```

并把 APK 上传到 GitHub Releases。配置方式见 [GitHub Release 自动打包](github-release.md)。

## Signing Strategy

使用固定 release keystore，通过 GitHub Secrets 注入。不得在每次构建时生成新密钥。
包名保持 com.aowugong.ootd；私钥及 android/key.properties 不提交到仓库。
配置与旧签名恢复要求见本文末尾。

## Debug vs Release

- `debug apk` 适合开发调试
- `release apk` 适合真机长期安装

如果手机上装的是 `debug` 版，安装 `release` 版前通常需要先卸载，因为签名不同。

## Upgrade Verification

验证“新版本覆盖安装后数据仍在”时：

1. 先安装旧 `release`
2. 在 app 内录入一些真实数据
3. 构建新 `release`
4. 直接覆盖安装
5. 打开 app 检查旧数据是否仍在

不要先卸载 app，否则会把本地沙盒数据一起删掉。

## First Install Verification

验证“首次安装默认没有穿搭数据”时：

1. 先卸载设备上的 app
2. 再安装新的 apk
3. 打开 app
4. 检查是否只有默认选项，没有默认穿搭

## Release Checklist

- 版本号已递增
- `flutter test` 通过
- `flutter build apk --release --no-tree-shake-icons` 通过
- GitHub Actions release workflow 通过
- 安装包路径正确
- 覆盖安装验证通过
- 备份导出和导入验证通过


## 2026-09-29 签名与 SDK 更新

CI 固定 Flutter 3.41.6，先执行 analyze 与 test。移除每次构建临时生成 keystore 的流程。
发布必须配置固定 Secrets：ANDROID_KEYSTORE_BASE64、ANDROID_KEYSTORE_PASSWORD、ANDROID_KEY_ALIAS、ANDROID_KEY_PASSWORD。
必须使用旧版 APK 对应的原始私钥；仅有密码、别名或证书不能恢复私钥。缺失配置会中止构建。
本次本地工作区未找到 APK、JKS 或 keystore，未创建或上传任何签名材料，也未触发发布。
尚不能保证对已安装旧版的覆盖升级；发版前需找回旧私钥并核对证书 SHA-256。
