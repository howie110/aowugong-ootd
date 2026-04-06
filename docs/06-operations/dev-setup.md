# 本地开发与安装

Status: active
Type: operations-setup
Last Updated: 2026-04-06
Source of Truth: yes
Related: [调试与运行](debug-and-run.md)

## Summary

当前推荐开发环境为 Windows + Android Studio + Flutter。

## Required Software

- Flutter SDK
- Android Studio
- Android SDK
- Android Emulator
- Git

## Recommended Local Paths

以下路径不是强制，但与当前项目环境一致，后续排障最方便：

```text
Flutter: C:\Users\Administrator\dev\flutter
Android Studio: D:\software\android-studio
Project: D:\project\aowugong-ootd
```

## Flutter Setup

1. 下载 Flutter SDK 并解压
2. 将 `flutter\bin` 加入 `PATH`
3. 运行：

```powershell
flutter doctor
```

## Android Studio Setup

需要安装：

- Android SDK
- Android SDK Platform-Tools
- Android Emulator
- 对应版本的 Android Platform

建议在 Android Studio 的 Device Manager 中创建一个 Android 模拟器。

## Network Mirror For Mainland China

如果 `flutter pub get` 或 `flutter build` 拉包慢，可以在 PowerShell 当前会话执行：

```powershell
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
```

如果希望写入系统环境变量，可执行：

```powershell
setx PUB_HOSTED_URL https://pub.flutter-io.cn
setx FLUTTER_STORAGE_BASE_URL https://storage.flutter-io.cn
```

注意：`setx` 只对新开的终端生效，不会立即影响当前 PowerShell 窗口。

## First Project Setup

进入项目根目录后执行：

```powershell
flutter pub get
```

## Verify Toolchain

建议依次验证：

```powershell
flutter doctor -v
flutter --version
adb devices
```

## Current Android Identity

- App 名称：`每日穿搭`
- 包名：`com.aowugong.ootd`

## Important Git Ignore Files

以下文件不能提交：

- `android/key.properties`
- `android/keystore/`
- `.dart_tool/`
- `build/`

## Common Setup Problems

### `flutter pub get` 仍访问 `pub.dev`

- 先确认是否在当前 PowerShell 会话里设置了 `$env:PUB_HOSTED_URL`
- 如果只执行了 `setx`，请重新打开终端

### Android Studio zip 解压损坏

- 重新下载
- 校验文件哈希
- 避免下载中断后的残缺 zip
