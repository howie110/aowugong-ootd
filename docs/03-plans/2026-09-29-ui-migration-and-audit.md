# shadcn 界面迁移与项目检查

日期：2026-09-29
状态：检查结果与迁移提案；尚未实施产品代码修改

## 需求与边界

- 用户决定暂不做微信小程序，继续优化现有 Android App。
- 用户要求界面组件全部换为 shadcn，并检查项目优化点。
- 延续纯本地、照片不上云、没有服务端基础设施的约束。
- 建议保留 Flutter、Riverpod、现有记录字段和 ZIP 备份兼容性。
- 原版 shadcn/ui 面向 Web/React；Flutter 需使用社区实现。待确认采用 shadcn_flutter，还是用户指定的其他库。

## 组件方案

推荐 shadcn_flutter，统一采用 New York / Zinc 中性色主题。另一候选 shadcn_ui 也支持 Flutter；不同时引入两套组件库。仅改 Material 主题不满足“全部换组件”的要求；为使用 React 原版重写整个 App 则不适合本次现有 Flutter 工程的优化范围。

兼容性检查发现：pub.dev 当前 shadcn_flutter 0.0.54 声明 Dart >=3.13.0、Flutter >=3.47.0；0.0.53 声明 Dart >=3.6.0、Flutter >=3.32.3。当前项目 pubspec 的 Dart 下限为 3.11.4，lockfile 的 Flutter 下限为 3.38.4。这些下限不能证明实际安装的 SDK 版本。实施时先定位/准备 SDK、验证依赖解析，再锁定兼容组合；不要直接使用浮动最新版。shadcn_ui 0.57.1 声明 Dart >=3.11.0、Flutter >=3.41.0，可作为备选。

| 界面范围 | 迁移要求 |
| --- | --- |
| 应用入口与主题 | 使用所选库的 App/Theme、统一颜色/字体/圆角/间距；移除现有 Material 主题的产品样式职责 |
| 首页 | 保留网格回看、多维多选、结果数量；卡片和交互筛选使用库组件；保留 Sliver 按需构建 |
| 详情页 | 保留主图、副图、预览、单选属性、保存和删除；统一按钮、图标按钮、确认弹窗和反馈提示 |
| 自定义相册页 | 保留相册分页及缩略图；替换应用内工具栏、选择按钮、错误态和加载态 |
| 设置与选项管理 | 统一卡片、列表行、输入框、操作按钮、确认对话框 |
| ZIP 导入/导出 | 统一文件信息、按钮、确认、进度及错误反馈；沿用用户主动备份流程 |
| 基础控件边界 | Flutter 的 Row/Column/Sliver/Image/Gesture 等仍负责布局、渲染和手势；不是第二套视觉组件库 |
| 系统窗口边界 | Android 权限、相机、文件选择和系统分享窗口由系统控制，不能换成 shadcn |

视觉提案：浅色中性背景、黑色主操作、细边框、统一线性图标、明确破坏性操作颜色。保持当前功能与主要导航结构；手机触摸区域、中文排版和大字体需要适配，不机械照搬网页尺寸。是否增加深色模式、重排首页密度，另行确认，不默认扩大范围。

## 检查发现

以下为静态源码发现或风险推断，不代表已在真机复现。优先级表示修复顺序。

### P1：发版签名不固定，影响覆盖升级

证据：`.github/workflows/android-release.yml:47` 起每次运行 keytool -genkeypair，创建新的 release.jks；Gradle 使用该文件签名。相同 alias 和密码不会使密钥保持相同。

影响：通过该流程分别生成的 APK 不能按普通同签名更新覆盖安装。用户卸载再装会影响本地数据。应优先确认已分发 APK 的证书及对应私钥是否仍在，再确定固定签名方案；不能把任意新密钥当作旧版本的无损升级方案。

### P1：保存完成与持久化完成脱节

证据：`ootd_items_provider.dart:167` 的 _persist 使用 unawaited，失败仅 assert 打印；options/filters 同样如此。`ootd_detail_page.dart:263` 的 _save 更新内存后直接返回。

影响：磁盘写失败时 UI 看起来已经保存，重启后可能丢失修改。多个持久化任务也没有写入串行化保证。

建议：保存返回可等待结果，持久化成功后完成操作，失败留在编辑页并允许重试；按文件串行写入并保存明确快照。

### P1：JSON 覆盖写与读取异常缺乏保护

证据：`local_ootd_store.dart:70/99/128` 直接 writeAsString；loadItemsJson 等把文件不存在、JSON 损坏和读取失败都处理成 null。`startup.dart` 将 null 记录初始化为空列表。

影响：中断写入可能留下不完整文件；损坏数据被当成首次安装，后续保存可能覆盖原文件。

建议：使用临时文件写入、校验和平台适用的替换策略，保留恢复副本；区分缺文件与坏文件，后者展示恢复入口且禁止自动覆盖。

### P1：备份导入过程不具备崩溃恢复能力

证据：`ootd_backup_service.dart:418` 先删除现有 images，再写新图片和三个 JSON。虽然有 ZIP 回滚及 catch 恢复，但进程被杀、掉电时 catch 不会执行。

建议：完整解析和校验后写入暂存目录，保留旧数据，使用切换标记及启动恢复机制；验收必须覆盖导入中断，而不只是正常导入。

### P2：图片残留会持续占用空间

证据：`ootd_detail_page.dart:206` 在选图后立即复制图片，而不是点击保存后；取消编辑不会清理这些副本。`ootd_items_provider.dart:114` 删除穿搭仅移除记录；替换和移除副图也未清理旧文件。

建议：管理草稿图片生命周期，保存后做引用检查再删除无用副本；清理不得删除其他记录仍引用的图片。图片复制是否改为相册引用是另一项存储设计选择，本次不默认变更。

### P2：首页展示缺少缩略图/按尺寸解码

证据：`ootd_image_view.dart:35` 直接 Image.file，未指定 cacheWidth/cacheHeight；`local_ootd_store.dart:226` 直接复制选择的图片。首页本身已经使用 SliverGrid 按需构建，不应误报成一次创建所有卡片。

影响：高分辨率照片在网格中可能产生较大解码内存和滚动开销，具体程度需真机 profiling。

建议：列表按物理像素限制解码尺寸，按需生成可重建缩略图；详情保留清晰图。是否压缩长期保存的照片需要明确画质政策，不默认覆盖原有高清副本。

### P2：大 ZIP 的内存与主线程计算开销

证据：`ootd_backup_service.dart:162` 读取全部图片构建 Archive；166 行同步压缩；323 行整包读取后同步解码。导出页面又在 97 行读取完整 ZIP。导入只检查压缩包 <=500MB，未限制解压总大小、单文件大小和条目数量。

建议：采用流式文件处理并把重计算放入 isolate，限制解压资源，显示阶段进度；移动到 isolate 只能改善 UI 响应，不能替代流式处理解决内存峰值。

### P2：备份缺图与旧备份保留策略

证据：_prepareExportPayload 对任何缺失图片直接抛错；exportBackup 在新 ZIP 生成前调用 _clearExistingZipFiles。

建议：缺图时先列明缺失内容，由用户选择取消或导出其余数据，不能静默丢图；新备份完成并验证后才清理旧备份。既有 ZIP 格式的变化需明确兼容策略。

### P2：相册异常及返回权限设置后的恢复

证据：photo_selection_page 的 _loadAssets/_loadMore 没有覆盖加载流程的 try/catch/finally；权限页只调用 PhotoManager.openSetting，未看到应用恢复时重新检查权限的生命周期处理。

风险：插件读取失败可能停留加载态；从系统设置授权返回后可能不能自动刷新。需在 Android 真机验证拒绝、部分授权、再次授权和读取异常。

### P2：未保存退出缺乏提醒

证据：详情页维护 _draftItem，未看到 PopScope 或未保存确认。返回时会放弃当前修改。

建议：有修改时提供保存/放弃/继续编辑，保存失败时保留草稿。

### P3：测试与构建基线不足

现有 test/widget_test.dart 共 7 个测试（4 个 widget、3 个状态/模型测试）；未覆盖实际磁盘保存、备份往返、写失败、导入中断、图片生命周期。部分 widget 测试直接依赖 FilledButton/Dialog 类型，迁移时应调整为用户可观察行为断言。

CI 仅 flutter test，没有 flutter analyze；Flutter channel: stable 未固定版本，SDK 更新可能改变构建结果；--no-tree-shake-icons 值得结合图标替换评估是否仍必要，不能未经构建验证就删除。

### P3：设置界面仍暴露开发占位内容

settings_page.dart 的帮助与版本页是占位页，并直接显示“仍为预留页”等开发说明；本地 ZIP 备份还使用云上传图标。建议换成本地文件/归档图标，并提供真实使用帮助和版本信息。

## 建议实施顺序与验收

1. 确认组件库和视觉方向，定位 Flutter SDK，记录当前构建与测试基线。
2. 处理持久化错误、数据损坏保护、备份崩溃恢复等数据可靠性问题，并补对应故障测试。
3. 迁移全局主题和所有应用内交互组件，验收首页、详情、相册、选项管理、导入、导出六类流程。
4. 优化图片解码/缩略图、草稿清理、大文件备份，进行 Android 真机内存和滚动测试。
5. 固定构建工具链；在已安装 APK 的签名来源明确后处理发布签名，验证保留数据的升级路径。

验收保留：每天一条、最多四图、多维筛选、自定义选项、JSON/ZIP 兼容、不新增照片联网行为。验证小屏、大字体、Android 返回键/键盘/安全区、权限拒绝、损坏备份、磁盘写失败等行为。

## 本次验证范围

已完成源码及配置阅读、组件包的发布元数据查询。工作区初始 git status 干净；未修改产品源码、依赖、签名或用户数据。

当前 shell 无 flutter/dart 可执行命令，已检查的常用工具目录也未发现 SDK；因此本次未执行 flutter analyze、flutter test 或 APK 构建，也没有真机性能结论。

## 外部依据

- https://ui.shadcn.com/docs/installation
- https://pub.dev/packages/shadcn_flutter
- https://pub.dev/api/packages/shadcn_flutter
- https://pub.dev/packages/shadcn_ui
- https://pub.dev/api/packages/shadcn_ui
- https://developer.android.com/studio/publish/app-signing
