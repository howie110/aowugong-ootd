# GitHub Release 自动打包

Status: active
Type: operations-release
Last Updated: 2026-06-11
Source of Truth: yes
Related: [发版说明](release.md), [测试清单](test-checklist.md)

## Summary

本项目可以用 GitHub Actions 在线构建 Android `release apk`，并把 APK 自动上传到 GitHub Releases。

推荐流程是：

1. 本地修改版本号、更新 changelog、提交代码
2. 推送形如 `v1.0.5` 的 git tag
3. GitHub Actions 自动测试、签名、构建 APK
4. GitHub Releases 自动生成下载项

## Why GitHub Actions

- 本机不必长期保存完整打包环境
- 构建步骤可重复，减少“我电脑能打、别人不能打”的问题
- 签名文件不提交到仓库，只通过 GitHub Secrets 注入
- Release 资产和源码版本天然绑定到 tag

## Required Repository Secrets

进入 GitHub 仓库：

```text
Settings -> Secrets and variables -> Actions -> Repository secrets
```

添加以下 secret：

```text
ANDROID_KEYSTORE_BASE64
```

含义：

```text
ANDROID_KEYSTORE_BASE64   release.jks 的 base64 文本
```

当前项目为了简化个人发布流程，release keystore 的密码和 alias 统一固定为：

```text
aowugong
```

Windows PowerShell 生成 `ANDROID_KEYSTORE_BASE64`：

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\release.jks")) | Set-Clipboard
```

粘贴到 GitHub Secret 时不要添加空格或说明文字。

## If There Is No Existing Keystore

如果还没有长期使用的 release keystore，可以直接用 GitHub Actions 手动生成：

```text
Actions -> Generate Android Keystore -> Run workflow
```

下载 artifact `android-release-keystore-private` 后，把 `ANDROID_KEYSTORE_BASE64.txt` 的内容复制到 GitHub Secret `ANDROID_KEYSTORE_BASE64`。

如果要在安装 JDK 的电脑上手动生成，则命令为：

```powershell
New-Item -ItemType Directory -Force android\keystore | Out-Null
keytool -genkey -v -keystore android\keystore\release.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias aowugong -storepass aowugong -keypass aowugong
```

生成后补齐 `android/key.properties`，再本地测试一次 release build。

重要规则：

- 一旦公开发版并有人安装，就不要随意换 keystore
- 丢失 keystore 会影响后续覆盖安装升级
- `android/key.properties` 和 `android/keystore/` 绝不能提交到 git

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
git commit -m "chore: release v1.0.5"
git tag v1.0.5
git push origin main
git push origin v1.0.5
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
v1.0.5
```

## Local Fallback

如果要在本机打包，仍然可以执行：

```powershell
flutter pub get
flutter test
flutter build apk --release
```

输出路径：

```text
build/app/outputs/flutter-apk/app-release.apk
```

本机必须提前准备 Flutter SDK、JDK、Android SDK、`android/key.properties` 和 `android/keystore/release.jks`。
