# GitHub Release 自动打包

Status: active
Type: operations-release
Last Updated: 2026-09-29
Source of Truth: yes
Related: [发版说明](release.md), [测试清单](test-checklist.md)

## Summary

本项目可以用 GitHub Actions 在线构建 Android `release apk`，并把 APK 自动上传到 GitHub Releases。

推荐流程是：

1. 本地修改版本号、更新 changelog、提交代码
2. 推送形如 `v1.0.8` 的 git tag
3. GitHub Actions 自动测试、签名、构建 APK
4. GitHub Releases 自动生成下载项

## Why GitHub Actions

- 本机不必长期保存完整打包环境
- 构建步骤可重复，减少“我电脑能打、别人不能打”的问题
- 签名文件不提交到仓库，GitHub Actions 从 Secrets 还原固定私钥
- Release 资产和源码版本天然绑定到 tag

## Android Signing

CI 使用固定 keystore，缺失 Secrets 会直接失败。配置 ANDROID_KEYSTORE_BASE64、ANDROID_KEYSTORE_PASSWORD、ANDROID_KEY_ALIAS、ANDROID_KEY_PASSWORD。

优先找回已发布 APK 对应的原始私钥，并核对证书 SHA-256；重新生成私钥不能延续旧版覆盖升级链。
不要提交私钥或密码。当前任务没有创建密钥或修改线上 Secrets。

## Release Flow

每次准备发布：

1. 更新 `pubspec.yaml` 的 `version`
2. 更新 `lib/app/app_metadata.dart`
3. 更新 `CHANGELOG.md`
4. 提交并推送代码
5. 创建并推送 tag

示例：

```powershell
git add pubspec.yaml lib/app/app_metadata.dart CHANGELOG.md
git commit -m "chore: release v1.0.8"
git tag v1.0.8
git push origin main
git push origin v1.0.8
```

Actions 成功后，APK 会出现在：

```text
https://github.com/howie110/aowugong-ootd/releases
```

## Manual Dispatch

也可以在 GitHub 网页上手动运行：

```text
Actions -> Android Release -> Run workflow
```

输入已经存在的 tag，例如：

```text
v1.0.8
```

## Local Fallback

如果要在本机打包，仍然可以执行：

```powershell
flutter pub get
flutter test
flutter build apk --release --no-tree-shake-icons
```

输出路径：

```text
build/app/outputs/flutter-apk/app-release.apk
```

本机必须提前准备 Flutter SDK、JDK、Android SDK、`android/key.properties` 和 `android/keystore/release.jks`。


## 2026-09-29 签名与 SDK 更新

CI 固定 Flutter 3.41.6，先执行 analyze 与 test。移除每次构建临时生成 keystore 的流程。
发布必须配置固定 Secrets：ANDROID_KEYSTORE_BASE64、ANDROID_KEYSTORE_PASSWORD、ANDROID_KEY_ALIAS、ANDROID_KEY_PASSWORD。
必须使用旧版 APK 对应的原始私钥；仅有密码、别名或证书不能恢复私钥。缺失配置会中止构建。
本次本地工作区未找到 APK、JKS 或 keystore，未创建或上传任何签名材料，也未触发发布。
尚不能保证对已安装旧版的覆盖升级；发版前需找回旧私钥并核对证书 SHA-256。
