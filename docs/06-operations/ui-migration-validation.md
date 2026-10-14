# shadcn_flutter 迁移验证记录

日期：2026-09-29。工作分支：codex/shadcn-app-refresh。未提交、未推送、未发布。

## 后续：本机 APK 构建已完成

2026-09-30：为用户的一加 Ace 5 重新生成 ARM64 Release 优化预览包，未删减功能、未修改应用源码。产物 `build/app/outputs/flutter-apk/daily-ootd-preview-arm64-1.0.8+10.apk` 为 20,797,438 bytes（19.8 MiB），较上一版 163,849,352 bytes 缩小约 87.3%。仅包含 arm64-v8a 的 libapp.so / libflutter.so，无调试 kernel、无 debuggable 标记；图标裁剪成功。构建、apksigner 验证均退出 0。包名仍为 `com.aowugong.ootd.preview`，versionCode 提高至 10，与之前预览包证书 SHA-256 相同，可覆盖更新预览版；仍使用调试密钥签署，不是正式发布包。未在真机安装测试。

新文件 SHA-256：`429318BC20467945277FAC82B957C47CEAC5F5AA919B0A9ACEC8F62093D49BD1`。复用下方环境变量，额外设置 `$env:OOTD_RELEASE_PREVIEW='1'`，命令改为 `flutter build apk --release --target-platform android-arm64 --build-number 10 --no-pub`。本机 init script 通过 `androidComponents.finalizeDsl` 注入 release 预览包名、同一 debug 签名及 `release-preview-manifest.xml`；正式发布配置未修改。首次签名配置时序错误与 Windows 构建文件占用已修正，最终构建成功。

用户随后要求生成 APK。已补齐本机 Java 17、Android SDK（platform 36/34、build-tools 35.0.0）、NDK 28.2.13676358 与 Gradle 8.14，`flutter doctor -v` 的 Android toolchain 检查通过。以下原始验收记录中的“缺 SDK、无法构建”是迁移交付时的状态，已被本次构建结果取代；真机测试与正式签名限制仍然有效。

- `flutter build apk --debug --no-pub -v` 成功，退出码 0，223 个 Gradle tasks。未构建正式 release。
- 文件：`build/app/outputs/flutter-apk/daily-ootd-preview-1.0.8.apk`，163,849,352 bytes（约 156.3 MiB）。包含 arm64-v8a、armeabi-v7a、x86_64，最低 Android 7.0 / API 24。
- 已用 apksigner 验证 APK v2 签名通过，用 aapt 确认应用名称“每日穿搭预览”、包名 `com.aowugong.ootd.preview`、启动入口 `com.aowugong.ootd.MainActivity`。
- SHA-256：`7C17C305016E7A7ADFB6BE24C086870BF628696632850F4F1E446A05C85F7504`。
- 使用标准 Android 调试签名，仅供独立安装预览，不是原正式版的覆盖升级包。预览版与正式版的数据隔离，不需卸载正式版。没有连接手机，尚未实际安装运行，也未验证性能。
- 仅本次构建的独立 `GRADLE_USER_HOME` 中注入 `.preview` 后缀和预览名称；仓库正式包名、Manifest 和正式签名配置不变。

本机复现（仅当前 PowerShell 进程生效）：

```powershell
$env:JAVA_HOME = 'C:/howiedata/tools/jdk17/jdk-17.0.20.1+1'
$env:ANDROID_HOME = 'C:/howiedata/tools/android-sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:GRADLE_USER_HOME = 'C:/howiedata/tools/gradle-ootd-preview'
$env:PATH = "$env:JAVA_HOME/bin;$env:PATH"
& C:/howiedata/tools/flutter-3.41.6/bin/flutter.bat build apk --debug --no-pub
```

预览注入文件位于 `C:/howiedata/tools/gradle-ootd-preview/init.d/ootd-preview.gradle` 和同目录上一级的 `preview-manifest.xml`。这些本机文件不是正式发布流程的一部分。

## 实现

- Flutter 3.41.6 / Dart 3.11.4；shadcn_flutter 固定 0.0.53，依赖解析及组件编译通过。0.0.54 的 SDK 下限不适合当前 SDK。
- 应用入口、主题、底部导航、按钮、选中按钮、输入框、弹窗、Toast、卡片与 Lucide 图标统一。系统相册权限、文件选择和分享保持系统界面。
- 所有照片与记录仍在本机，没有增加云存储、账号或后端。
- 记录/选项/筛选按队列保存，使用临时文件、flush 和替换；关联的三份 JSON 通过恢复日志整体提交。失败后不提前改变 provider state。
- 编辑保存失败保留草稿，选项输入失败保留内容；离开时可保存、放弃或继续编辑。
- 网格按显示宽度与像素密度限制解码，高清预览保留原分辨率，不覆盖原图。
- 选图先进入 drafts，保存时复制到 images；放弃/删除后的清理仅遍历应用受管目录，保留磁盘记录引用，不跟随符号链接。
- 相册恢复前台时刷新，加载错误可重试；缩略图失败/空结果可单独重试。
- ZIP 压缩、解压和校验在 isolate，使用文件流；单图 64MB、manifest 16MB、总解压 1GB、压缩包 500MB、条目 10000 的限制。校验实际字节量和 CRC，拒绝非法路径、链接、加密、不支持的压缩方式、重复记录/日期与无效图片数量。
- 导入先写入独立图片代际目录，再提交 JSON 快照；旧图片不被覆盖。故障时恢复日志决定旧/新快照，启动时再清理未引用文件。失败的解压只清理本次暂存目录。
- 导出先完成并验证新 ZIP 才删除旧备份；失败清理当前 ZIP/tmp，保留旧备份。
- CI 固定 SDK，增加 analyze；签名由固定 Secrets 注入，缺失即失败，不生成新私钥。

## 验证证据

- 迁移前：现有 7 个测试通过，analyze 有 3 条既有提示；测试暴露原有未等待持久化在 provider 释放后仍执行。
- 完整测试覆盖：多次写入顺序、失败不丢旧数据、损坏 JSON、失败后的重试、关联 JSON 回滚、逐个 JSON 替换中断后恢复；ZIP 往返、实际原图字节、失败保留备份、失败暂存清理、非法记录/路径；缩略图 decode size、引用与草稿清理、保存/输入失败、小屏和大字体、返回确认、相册和缩略图失败重试。
- 独立全改动评审发现失败暂存残留、备份记录缺少运行时校验，以及标题编码/缩略图重试问题。均用失败回归测试定位后修复；没有重复发起评审。
- `flutter analyze`：No issues found，退出码 0。
- `flutter test`：40 个测试全部通过，退出码 0。之后仅补两处 if 花括号并重新通过 analyze。
- `flutter build apk --debug`：已执行，因找不到 Android SDK 失败。额外尝试 Android release bundle 同样被 SDK 缺失阻止。
- 没有构建 release APK，没有检验 APK 证书。工作区中未发现 APK/JKS/keystore，未读取或更改远端 Secrets。
- 截图位于 build/ui-review/home.png 与 detail.png，390×844；使用测试数据和 Windows 中文字体辅助检查，不是真机截图。另有 320/390 宽度、文字缩放 1.0/1.5 的 widget 布局检查。

## 性能结论与限制

shadcn_flutter 使用 Flutter widgets，本次未加入 WebView。图片尺寸解码与后台 ZIP 处理针对已确认的开销来源进行了优化，但当前没有 Android 设备，不能据此宣称帧率、冷启动、峰值内存或 APK 大小已经改善。

file_picker 在 Android 的另存为接口仍要求完整 ZIP bytes，最终调用系统保存前仍有一份 ZIP 内存开销；不能称为全链路流式。备份上限不会消除低内存手机的大文件风险。完整校验预览会读取图片，耗时随备份大小增加，但在后台 isolate 执行。

故障恢复保证的是有序文件替换/进程中断语义；没有在真实硬件验证突然断电及存储介质损坏。原图片代际在切换后临时保留，直到安全清理完成，因而需要额外磁盘空间。

保留现有 --no-tree-shake-icons 发布参数；尚未具备 Android 构建环境来验证去掉它是否解决旧版动态图标构建问题，因此 APK 体积尚未比较。

## 人工待验收

在同一 Android 设备、同一数据集下，用迁移前后 profile 构建比较冷启动、连续滚动 UI/raster 帧耗时与内存、大图预览和大 ZIP 导入导出。还需检查系统权限设置返回、有限照片权限、相机返回、系统另存为、分享、键盘弹出及 Android 返回手势。

正式发布前必须找回原始签名私钥并核对证书 SHA-256；只有旧密码、别名或证书无法重建私钥，不能保证未知旧签名 APK 的覆盖升级。不要通过卸载来测试保留本地数据。

## 实施判断

1. 在当前干净工作区创建独立开发分支，没有再复制工作树；不修改 main，也不推送。
2. 图片生命周期与界面保存处理一起实施，避免 Future 接口迁移中留下不可用调用链。
3. 导入采用不可变图片代际 + JSON 恢复日志，替代先删图片和二次 ZIP 回滚；恢复步骤更少，代价是清理前额外占用存储空间。
4. 缺 Android SDK/设备/旧签名材料时报告未验证，不以 widget 测试代替构建、真机性能或覆盖升级证据。
5. 将评审中的标题编码与缩略图永久 loading 按用户可见功能问题处理，一并修复，没有遗留这两项。
