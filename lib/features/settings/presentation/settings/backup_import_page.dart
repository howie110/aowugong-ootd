import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  final OotdBackupService _backupService = const OotdBackupService();

  String? _selectedZipPath;
  OotdBackupPreview? _preview;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('备份导入')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _ImportGuideCard(),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickZipFile,
            icon: const Icon(Icons.folder_zip_outlined),
            label: Text(_busy ? '处理中...' : '选择 zip 文件'),
          ),
          if (_preview != null) ...[
            const SizedBox(height: 12),
            _PreviewCard(preview: _preview!, zipPath: _selectedZipPath ?? ''),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _confirmAndImport,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_done_rounded),
              label: Text(_busy ? '正在导入...' : '开始导入'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickZipFile() async {
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            error is OotdBackupException ? '读取 zip 失败：$error' : '读取 zip 失败，请检查文件是否正确',
          ),
        ));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _confirmAndImport() async {
    final zipPath = _selectedZipPath;
    final preview = _preview;
    if (zipPath == null || preview == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('导入备份'),
          content: Text(
            '将导入 ${preview.fileName}。\n\n这会覆盖当前目录下的本地数据和图片，是否继续？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
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
      final imported = await _backupService.importBackup(
        zipPath: zipPath,
        currentItems: ref.read(ootdItemsProvider),
        currentFilters: ref.read(ootdFiltersProvider),
        currentOptions: ref.read(ootdOptionConfigProvider),
      );

      ref.read(ootdOptionConfigProvider.notifier).replaceAll(imported.options);
      ref.read(ootdItemsProvider.notifier).replaceAll(imported.items);
      ref.read(ootdFiltersProvider.notifier).replaceAll(imported.filters);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '导入完成：恢复了 ${imported.preview.itemCount} 条穿搭，${imported.preview.imageCount} 张图片',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            error is OotdBackupException ? '备份导入失败：$error' : '备份导入失败，请重试',
          ),
        ));
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请选择之前导出的 zip 备份文件。通常你会把它保存在 Download 或其他可见目录。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '导入时会先生成自动回滚备份，再覆盖当前本地目录。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.preview,
    required this.zipPath,
  });

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
            style: theme.textTheme.titleMedium?.copyWith(
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
  const _PreviewLine({
    required this.label,
    required this.value,
  });

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
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
