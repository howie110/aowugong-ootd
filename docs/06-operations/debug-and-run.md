# 调试与运行

Status: active
Type: operations-debug
Last Updated: 2026-04-06
Source of Truth: yes
Related: [本地开发与安装](dev-setup.md), [测试清单](test-checklist.md)

## Summary

本文件记录当前项目在 Windows 下的常用运行方式和排障方法。

## Standard Run Flow

1. 打开 Android 模拟器
2. 进入项目根目录
3. 设置镜像环境变量
4. 拉依赖
5. 运行 app

```powershell
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
flutter pub get
flutter run -d emulator-5554
```

## List Devices

```powershell
adb devices
flutter devices
```

## Hot Reload And Hot Restart

- 热重载：运行 `flutter run` 后，终端按 `r`
- 热重启：运行 `flutter run` 后，终端按 `R`

如果终端无反应，先确认当前焦点是否在运行中的 Flutter 终端。

## If UI Does Not Change

优先按顺序检查：

1. 是否真的保存了代码
2. 是否是热重载无法覆盖的改动，尝试热重启
3. 是否需要重新运行 `flutter run`
4. 是否其实安装的是旧 apk

## Common Errors

### `Running Gradle task 'assembleDebug'...` 长时间卡住

先确认：

- Android 模拟器已完全启动
- 当前终端已设置 Flutter 镜像环境变量
- Java 能正常找到

如果需要直接看 Gradle 日志，在 `android/` 目录执行：

```powershell
$env:JAVA_HOME='D:\software\android-studio\jbr'
.\gradlew.bat assembleDebug --info --stacktrace --console=plain *>&1 | Tee-Object ..\gradle-build.log
```

### `JAVA_HOME is not set`

当前项目建议直接指向 Android Studio 自带 JBR：

```powershell
$env:JAVA_HOME='D:\software\android-studio\jbr'
```

### `Got socket error trying to find package ... at https://pub.dev`

说明当前终端还没真正使用镜像源。重新执行：

```powershell
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
flutter pub get
```

### `Error connecting to the service protocol`

如果 apk 已安装成功且 app 已经打开，这通常不是打包失败，而是调试连接被拒绝。可尝试：

- 再次执行 `flutter run`
- 重启模拟器
- 关闭可能影响本地回环连接的软件

## Install Built APK Manually

如果已经打出了 `debug apk`，也可以手动安装：

```powershell
adb install -r .\build\app\outputs\flutter-apk\app-debug.apk
```

## Useful Commands

```powershell
flutter clean
flutter pub get
flutter test
flutter build apk --debug
flutter build apk --release
```
