import 'package:aowugong_ootd/shared/design/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design/app_theme.dart';
import '../../../ootd/presentation/home/mock_ootd_items.dart';

class OptionManagementPage extends ConsumerWidget {
  const OptionManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(ootdOptionConfigProvider);
    final groups = config.allGroups;

    return AppScaffold(
      appBar: AppPageBar(
        title: const Text('选项管理'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AppIconButton(
              onPressed: () => _handleAddGroup(context, ref),
              tooltip: '新增选项',
              icon: const Icon(LucideIcons.plus, size: 18),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
        children: [
          for (var index = 0; index < groups.length; index++) ...[
            _OptionSection(
              values: groups[index].values,
              onAdd: () => _handleAddValue(context, ref, groups[index].key),
              onDeleteGroup: () =>
                  _handleDeleteGroup(context, ref, groups[index].key),
              onEdit: (value) =>
                  _handleEditValue(context, ref, groups[index].key, value),
              onDelete: (value) =>
                  _handleDeleteValue(context, ref, groups[index].key, value),
            ),
            if (index != groups.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAddGroup(BuildContext context, WidgetRef ref) =>
      _editOption(
        context,
        title: '新增选项',
        hintText: '输入首个选项内容',
        onSave: ref.read(ootdOptionConfigProvider.notifier).addExtraGroup,
      );

  Future<void> _handleAddValue(
    BuildContext context,
    WidgetRef ref,
    String key,
  ) => _editOption(
    context,
    title: '新增选项',
    onSave: (value) =>
        ref.read(ootdOptionConfigProvider.notifier).addOptionByKey(key, value),
  );

  Future<void> _handleEditValue(
    BuildContext context,
    WidgetRef ref,
    String key,
    String currentValue,
  ) => _editOption(
    context,
    title: '编辑选项',
    initialValue: currentValue,
    onSave: (value) => ref
        .read(ootdOptionConfigProvider.notifier)
        .renameOptionByKey(key, currentValue, value),
  );

  Future<void> _handleDeleteValue(
    BuildContext context,
    WidgetRef ref,
    String key,
    String currentValue,
  ) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除选项'),
          content: const Text('删除后，已有穿搭会自动切换到同组的其他选项。是否继续？'),
          actions: [
            GhostButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            PrimaryButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (!context.mounted || confirmed != true) {
      return;
    }

    final result = ref
        .read(ootdOptionConfigProvider.notifier)
        .deleteOptionByKey(key, currentValue);
    _showResult(context, result);
  }

  Future<void> _handleDeleteGroup(
    BuildContext context,
    WidgetRef ref,
    String key,
  ) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除整个选项'),
          content: const Text('删除后，这一组选项会从筛选和穿搭详情中移除。是否继续？'),
          actions: [
            GhostButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            PrimaryButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (!context.mounted || confirmed != true) {
      return;
    }

    final result = ref
        .read(ootdOptionConfigProvider.notifier)
        .deleteGroupByKey(key);
    _showResult(context, result, successMessage: '已删除选项');
  }

  Future<void> _showResult(
    BuildContext context,
    Future<OotdOptionEditResult> pending, {
    String successMessage = '已保存',
  }) async {
    try {
      final result = await pending;
      if (!context.mounted) return;
      final message = switch (result) {
        OotdOptionEditResult.success => successMessage,
        OotdOptionEditResult.emptyValue => '内容不能为空',
        OotdOptionEditResult.duplicateValue => '这个选项已经存在',
        OotdOptionEditResult.minimumReached => '每一组至少保留一个选项',
      };

      showAppMessage(context, message);
    } catch (_) {
      if (context.mounted) showAppMessage(context, '保存失败，请重试');
    }
  }
}

class _OptionSection extends StatelessWidget {
  const _OptionSection({
    required this.values,
    required this.onAdd,
    required this.onDeleteGroup,
    required this.onEdit,
    required this.onDelete,
  });

  final List<String> values;
  final VoidCallback onAdd;
  final VoidCallback onDeleteGroup;
  final ValueChanged<String> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final ootd = OotdColors.of(context);

    return Card(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              AppIconButton(
                onPressed: onAdd,
                tooltip: '新增内容',
                icon: const Icon(LucideIcons.plus, size: 16),
              ),
              const SizedBox(width: 6),
              AppIconButton(
                onPressed: onDeleteGroup,
                tooltip: '删除整个选项',
                icon: const Icon(LucideIcons.trash2, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (var index = 0; index < values.length; index++) ...[
            _OptionRow(
              value: values[index],
              onEdit: () => onEdit(values[index]),
              onDelete: () => onDelete(values[index]),
            ),
            if (index != values.length - 1)
              Divider(height: 10, color: ootd.subtleDivider),
          ],
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.value,
    required this.onEdit,
    required this.onDelete,
  });

  final String value;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ootd = OotdColors.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            value,
            style: theme.typography.large.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        AppIconButton(
          onPressed: onEdit,
          tooltip: '编辑',
          icon: Icon(LucideIcons.pencil, size: 18, color: ootd.mutedForeground),
        ),
        AppIconButton(
          onPressed: onDelete,
          tooltip: '删除',
          icon: Icon(LucideIcons.trash2, size: 18, color: ootd.destructive),
        ),
      ],
    );
  }
}

Future<void> _editOption(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String hintText = '输入选项内容',
  required Future<OotdOptionEditResult> Function(String) onSave,
}) async {
  await showAppDialog<void>(
    context: context,
    builder: (_) => _OptionInputDialog(
      title: title,
      initialValue: initialValue,
      hintText: hintText,
      onSave: onSave,
    ),
  );
}

class _OptionInputDialog extends StatefulWidget {
  const _OptionInputDialog({
    required this.title,
    required this.initialValue,
    required this.hintText,
    required this.onSave,
  });
  final String title, initialValue, hintText;
  final Future<OotdOptionEditResult> Function(String) onSave;
  @override
  State<_OptionInputDialog> createState() => _OptionInputDialogState();
}

class _OptionInputDialogState extends State<_OptionInputDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.onSave(_controller.text);
      if (!mounted) return;
      if (result == OotdOptionEditResult.success) {
        Navigator.pop(context);
        return;
      }
      setState(
        () => _error = switch (result) {
          OotdOptionEditResult.emptyValue => '内容不能为空',
          OotdOptionEditResult.duplicateValue => '这个选项已经存在',
          OotdOptionEditResult.minimumReached => '每一组至少保留一个选项',
          OotdOptionEditResult.success => null,
        },
      );
    } catch (_) {
      if (mounted) setState(() => _error = '保存失败，内容已保留，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_busy,
            hintText: widget.hintText,
            onSubmitted: (_) => _save(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.destructive,
              ),
            ),
          ],
        ],
      ),
      actions: [
        GhostButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        PrimaryButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? '保存中…' : '保存'),
        ),
      ],
    ),
  );
}
