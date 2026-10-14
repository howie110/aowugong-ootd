import '../../../ootd/presentation/home/providers/ootd_mutation_queue.dart';
import 'package:file_picker/file_picker.dart';
import 'package:aowugong_ootd/shared/design/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/ootd/presentation/home/mock_ootd_items.dart';
import '../../../../shared/design/ootd_card.dart';
import '../../data/ootd_backup_service.dart';

class BackupImportPage extends ConsumerStatefulWidget {
  const BackupImportPage({super.key});

  @override
  ConsumerState<BackupImportPage> createState() => _BackupImportPageState();
}

class _BackupImportPageState extends ConsumerState<BackupImportPage> {
  OotdBackupService get _backupService =>
      OotdBackupService(store: ref.read(ootdLocalStoreProvider));

  String? _selectedZipPath;
  OotdBackupPreview? _preview;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: AppScaffold(
        appBar: AppPageBar(title: const Text('备份导入')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const _ImportGuideCard(),
            const SizedBox(height: 12),
            OutlineButton(
              onPressed: _busy ? null : _pickZipFile,
              leading: const Icon(LucideIcons.archive),
              child: Text(_busy ? '处理中...' : '选择 zip 文件'),
            ),
            if (_preview != null) ...[
              const SizedBox(height: 12),
              _PreviewCard(preview: _preview!, zipPath: _selectedZipPath ?? ''),
              const SizedBox(height: 12),
              PrimaryButton(
                onPressed: _busy ? null : _confirmAndImport,
                leading: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(),
                      )
                    : const Icon(LucideIcons.download),
                child: Text(_busy ? '正在导入...' : '开始导入'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickZipFile() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: const ['zip'],
      );
      final zipPath = result?.files.single.path;
      if (!mounted || zipPath == null) {
        return;
      }

      setState(() => _busy = true);
      final preview = await _backupService.readBackupPreview(zipPath);
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedZipPath = zipPath;
        _preview = preview;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppMessage(
        context,
        error is OotdBackupException
            ? '读取 zip 失败：$error'
            : '读取 zip 失败，请检查文件是否正确',
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _confirmAndImport() async {
    if (_busy) return;
    final zipPath = _selectedZipPath;
    final preview = _preview;
    if (zipPath == null || preview == null) {
      return;
    }

    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('导入备份'),
          content: Text('将导入 ${preview.fileName}。\n\n这会覆盖当前目录下的本地数据和图片，是否继续？'),
          actions: [
            GhostButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            PrimaryButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('继续导入'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(ootdMutationQueueProvider).run(() async {
        final imported = await _backupService.importBackup(
          zipPath: zipPath,
          currentItems: ref.read(ootdItemsProvider),
          currentFilters: ref.read(ootdFiltersProvider),
          currentOptions: ref.read(ootdOptionConfigProvider),
        );

        ref
            .read(ootdOptionConfigProvider.notifier)
            .acceptPersisted(imported.options);
        ref.read(ootdItemsProvider.notifier).acceptPersisted(imported.items);
        ref
            .read(ootdFiltersProvider.notifier)
            .acceptPersisted(imported.filters);

        if (!mounted) {
          return;
        }

        showAppMessage(
          context,
          '导入完成：恢复了 ${imported.preview.itemCount} 条穿搭，${imported.preview.imageCount} 张图片',
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppMessage(
        context,
        error is OotdBackupException ? '备份导入失败：$error' : '备份导入失败，请重试',
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

class _ImportGuideCard extends StatelessWidget {
  const _ImportGuideCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OotdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '导入说明',
            style: theme.typography.large.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请选择之前导出的 zip 备份文件。通常你会把它保存在 Download 或其他可见目录。',
            style: theme.typography.small.copyWith(
              color: theme.colorScheme.mutedForeground,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '导入会先校验并暂存图片，再整体切换数据。中断时可在下次启动恢复。',
            style: theme.typography.small.copyWith(
              color: theme.colorScheme.mutedForeground,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview, required this.zipPath});

  final OotdBackupPreview preview;
  final String zipPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OotdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'zip 预览',
            style: theme.typography.large.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          _PreviewLine(label: '文件名', value: preview.fileName),
          _PreviewLine(label: '完整路径', value: zipPath),
          _PreviewLine(label: '导出时间', value: preview.exportedAt),
          _PreviewLine(label: '格式版本', value: '${preview.backupFormatVersion}'),
          _PreviewLine(label: '应用版本', value: preview.appVersion),
          _PreviewLine(label: '穿搭数量', value: '${preview.itemCount}'),
          _PreviewLine(label: '穿搭图', value: '${preview.ootdImageCount}'),
          _PreviewLine(label: 'zip图', value: '${preview.imageCount}'),
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: theme.typography.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.typography.small.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
