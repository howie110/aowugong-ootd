# shadcn_flutter Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task if the user selects inline execution; otherwise use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将每日穿搭 App 的应用内视觉组件统一迁移到 shadcn_flutter，保留本地数据与现有功能，并修复直接影响记录可靠性和图片体验的问题。

**Architecture:** 保留 Flutter + Riverpod 和 JSON/图片/ZIP 存储协议。先建立可测试的磁盘写入与恢复边界，再替换应用主题及页面组件。布局、图片和手势继续使用 Flutter 基础 widgets；系统权限、文件选择和分享继续使用平台插件。

**Tech Stack:** Flutter/Dart、shadcn_flutter、flutter_riverpod、photo_manager、image_picker、archive、file_picker、share_plus。

**Spec:** ../../03-plans/2026-09-29-ui-migration-and-audit.md

## Global Constraints

- 用户于 2026-09-29 确认采用 shadcn_flutter；保留 Flutter，不转 React/WebView。
- 纯本地、照片不上云、没有服务端基础设施。
- 每天一条、最多四图、多维筛选、自定义选项、JSON/ZIP 兼容。
- New York / Zinc 浅色中性主题；不默认新增深色模式，不重排现有产品功能。
- 全部应用内按钮、表单、弹窗、反馈、导航使用同一套库；不同时引入 shadcn_ui。
- 不更换 applicationId，不生成替代旧签名的新密钥，不在此任务中发布 APK。
- 先验证 SDK 与依赖兼容性，再锁定版本。优先验证 shadcn_flutter 0.0.53 与现有 Dart 3.11 系列兼容的 Flutter；如果无法解析，记录具体冲突后调整 SDK/包版本。不能只依据环境下限宣称兼容。

## Review Focus

- 写盘失败：编辑草稿仍在，界面明确提示，旧文件仍可读取（Task 2）。
- 备份导入期间进程中断：重启后能恢复完整旧数据或完整新数据（Task 3）。
- 多条记录引用同一图片：取消、替换、删除任一条不误删其他引用（Task 5）。
- 中文大字体及小屏：按钮不溢出，输入框与底部操作不被键盘遮挡（Task 4）。
- 系统相册授权后返回：重新读取权限和资源，异常可重试（Task 5）。

## Task 1: 工具链、基线与迁移依赖

**Files:** pubspec.yaml、pubspec.lock、.github/workflows/android-release.yml；新增 docs/06-operations/ui-migration-validation.md。

**Interfaces:** 产出可复用的 Flutter 可执行路径、固定 SDK 版本、可解析的 shadcn_flutter 版本及验证记录。

- [ ] 定位或安装独立 Flutter SDK，记录 flutter --version / flutter doctor -v；不修改全局 PATH。
- [ ] 在当前源码上运行 flutter pub get、flutter analyze、flutter test，保存既有失败与警告。
- [ ] 在开发分支/隔离工作区验证组件包解析，锁定兼容版本；阅读该版本实际包源码，确认 App、Theme、按钮、输入、对话框、Toast、Navigation API。
- [ ] 更新 CI 固定 flutter-version，并添加 flutter analyze。保留现有签名流程待 Task 6 审计处理，暂不触发发布。
- [ ] 在可用 Android 设备上记录迁移前 profile 数据：冷启动、首页连续滚动、详情切换、大图预览、备份；无设备时明确记录未测，不能用 widget 测试替代性能数据。

## Task 2: 可等待、串行且可恢复的本地保存

**Files:** lib/features/ootd/data/local_ootd_store.dart；lib/features/ootd/presentation/home/providers/ootd_items_provider.dart、ootd_options_provider.dart、ootd_filters_provider.dart；lib/bootstrap/startup.dart；新增 test/local_ootd_store_test.dart、test/persistence_failure_test.dart。

**Interfaces:** OotdLocalStore 增加可选 dataDirectoryOverride，默认仍用现有目录；saveItemsJson/saveFiltersJson/saveOptionsJson 维持 Future<void>，按目标文件串行执行。新增 flushPendingWrites()。记录和选项的修改方法返回 Future<void> 或 Future<OotdOptionEditResult>，仅在保存成功后提交对应 state。

- [ ] 编写真实临时目录测试：连续写入后得到最后一次快照；写失败保留旧数据；坏 JSON 不返回“无数据”；初始化不覆盖损坏文件；一项写入失败不阻断后续重试。
- [ ] 运行以上测试，确认失败是缺失的行为。
- [ ] 实现临时文件写入/flush、恢复副本、替换和串行队列；启动区分缺文件与损坏数据，损坏时显示恢复说明，不自动清空。
- [ ] 更新 Provider 调用链，使保存结果可等待、错误可传到页面。选项改名涉及多文件时保留可恢复快照，避免只保存一半。
- [ ] 测试保存失败后的 provider state 和 UI 草稿，验证成功后再完成页面返回；运行 flutter test。

## Task 3: ZIP 备份的事务恢复与内存控制

**Files:** lib/features/settings/data/ootd_backup_service.dart；lib/features/ootd/data/local_ootd_store.dart；lib/bootstrap/startup.dart；新增 test/ootd_backup_service_test.dart。

**Interfaces:** 保留 exportBackup/readBackupPreview/importBackup 对外返回类型和 backupFormatVersion=1。新增 recoverInterruptedImport()，由启动流程在加载 JSON 前调用；导入暂存目录和恢复标记属于内部实现，不进入公开 ZIP 协议。

- [ ] 使用临时目录构造 ZIP 往返测试、缺文件/非法路径/版本不支持测试，以及通过可注入导入阶段故障模拟“旧图尚在、新图已写、JSON 切换中”三个中断点。
- [ ] 先运行测试确认缺失恢复能力，再实现完整校验、暂存文件、切换标记和启动恢复；所有路径必须约束在管理目录，旧数据在新快照验证完成前保留。
- [ ] 将压缩/解压计算放入 isolate；采用 archive 包支持的文件流 API，避免同时保留所有原图与完整 ZIP 字节。file_picker 若必须接收 bytes，记录该平台接口的剩余内存限制，不宣称全链路流式。
- [ ] 压缩包仍限制 500MB；解压总量上限 1GB、单图片上限 64MB、manifest 上限 16MB、条目上限 10000，并在读入内容前校验声明大小、写出时累计校验实际大小。
- [ ] 先完成并验证新备份，再清理旧备份。缺图导出保留默认报错并列明缺图；“跳过缺图继续导出”作为独立产品选项，不静默改变备份含义。
- [ ] 运行全部备份测试，并用较大生成文件验证 UI 有进度反馈、可以响应操作。

## Task 4: 全量 shadcn 组件迁移

**Files:** lib/app/app.dart、router.dart；lib/shared/design/app_theme.dart、ootd_card.dart；lib/shared/navigation/smooth_page_route.dart；lib/features/ootd/presentation/home/home_page.dart；lib/features/ootd/presentation/detail/ootd_detail_page.dart、photo_selection_page.dart；lib/features/ootd/presentation/shared/compact_option_group.dart；lib/features/settings/presentation/settings/ 下所有页面；test/widget_test.dart。

**Interfaces:** DailyOotdApp 保持入口名称；统一 AppTheme 创建所选库主题。新增 lib/shared/design/app_feedback.dart，提供 Future<bool> confirmAction(BuildContext context, {required String title, required String message, bool destructive = false}) 和 void showAppMessage(BuildContext context, String message)。业务页面复用反馈入口，不重新模拟 Material 组件。

- [ ] 调整 widget 测试为行为断言：筛选结果、详情预览关闭、保存可用/禁用、删除取消/确认、选项输入验证、设置导航和备份入口，去掉对 FilledButton/Dialog 具体类型的依赖。
- [ ] 新增 shadcn 应用壳 smoke test，先观察迁移前失败；用所选库替换应用入口、全局主题、导航和路由。
- [ ] 逐页替换 Card/Button/IconButton/Input/Dialog/Toast 等组件，筛选使用库中具备选中语义的交互组件，图标统一为 Lucide。保留 SliverGrid 和相册 GridView.builder。
- [ ] 将保存按钮接入 Task 2 的 Future，提交期间禁用重复操作，失败留在编辑页。加入有修改时返回确认，允许保存、放弃或继续编辑。
- [ ] 用真实帮助和版本信息替代设置占位文案；本地备份使用文件/归档图标。
- [ ] 在宽度 320、390 和文字缩放 1.0、1.5 的组合下运行页面测试；检查键盘遮挡、Android 返回键、焦点与触摸目标。
- [ ] 搜索所有应用内 Material/Cupertino 风格控件，验证无遗留；基础 widgets 和库内部实现不算遗留。运行 flutter analyze、flutter test。

## Task 5: 图片生命周期与相册恢复

**Files:** lib/features/ootd/presentation/shared/ootd_image_view.dart；lib/features/ootd/data/local_ootd_store.dart；lib/features/ootd/presentation/detail/ootd_detail_page.dart、photo_selection_page.dart；新增 test/image_lifecycle_test.dart、test/image_view_test.dart。

**Interfaces:** OotdImageView 增加 bool fullResolution=false；网格默认按布局尺寸乘 devicePixelRatio 限制解码，预览显式 fullResolution=true。新增清理入口 Future<void> removeUnreferencedImages(Set<String> referencedPaths, {required Set<String> protectedDraftPaths})，只处理 App 管理目录。

- [ ] 测试网格的 decode size 与预览差异；测试取消草稿清理、替换后清理、共享图片保留、保存失败时草稿图片保留和非管理目录不删除。
- [ ] 实现按尺寸解码，不压缩或覆盖既有高清副本；草稿使用独立受管目录，成功保存后转入正式目录，放弃时清理。
- [ ] 相册加载加入异常反馈和 finally 复位；应用恢复时重新检查权限，支持权限变化、部分访问及再次加载。
- [ ] 保留分页，避免为所有相册图片请求原图；测试加载失败可以重试而非永久 loading。
- [ ] 运行测试和 profile，对比迁移前后网格滚动内存、帧耗时及详情加载。

## Task 6: 发布边界、验收和交付

**Files:** .github/workflows/android-release.yml、docs/06-operations/release.md、docs/06-operations/github-release.md、docs/06-operations/ui-migration-validation.md、CHANGELOG.md。

- [ ] 检查现有分发 APK 的签名证书及已有 keystore 的可恢复性；仅报告指纹，不输出私钥。缺少旧私钥时明确无法保证覆盖升级，不能生成新密钥后声称兼容。
- [ ] 发布流水线改为需要已配置的固定签名材料，缺少配置时明确失败；密钥通过 CI secrets 注入。此任务不擅自创建、上传或替换用户密钥。
- [ ] 执行 flutter analyze、flutter test、flutter build apk --debug；签名材料具备时再构建 release，尚不发布。
- [ ] 完成一次独立全分支评审，修复数据丢失、组件漏迁移、文件误删和回归问题；再运行受影响测试及完整测试集。
- [ ] 将真机测量、截图、未测项和升级限制写入验证记录。没有 Android 设备时交付构建/测试结果及明确的真机待测项，不能宣称“运行速度不变”。

## 性能验收口径

- 同一设备、同一数据集、同一 profile 构建条件，对比迁移前后结果。
- 网格保持按需构建，build 方法内不进行图片读写或 ZIP 运算。
- 记录 UI/raster 帧耗时及超出设备帧预算的帧比例，冷启动到首屏时间、滚动峰值内存和 APK 大小；不把 debug 模式的卡顿当成 release 结论。
- 优先消除大图解码和同步 ZIP 造成的阻塞；组件替换不能作为“必定加速”的依据。

## 执行结果（2026-09-29）

Task 1–6 的代码实施已完成；上方保留原始验收清单，不能把其中真机与签名检查视为已经通过。最终 analyze 无问题、40 个测试通过；一次独立全改动评审的四项问题均已修复。完整证据及未测项见 docs/06-operations/ui-migration-validation.md。

尚未完成的环境验收：Android APK 构建、真机 profile 性能对比、平台权限/相机/分享/键盘交互，以及旧签名证书与覆盖升级核验。缺 Android SDK/设备/旧签名材料，已记录实际失败及限制，没有发布。

## 准备状态

- [x] 用户已确认 shadcn_flutter 与迁移方向。
- [x] 已检查组件发布元数据，识别 0.0.54 的 SDK 门槛。
- [x] 已完成实施计划自查，记录接口、异常输入与验证要求。
- [x] 用户审阅本实施计划并选择当前任务内执行。
- [x] 准备 SDK、建立基线并完成源码实施。

已在 C:/howiedata/tools/flutter-3.41.6 安装独立 Flutter 3.41.6 / Dart 3.11.4，无全局 PATH 变更；依赖解析通过。Android SDK 仍缺失，不能视为 Android 构建环境已经就绪。
