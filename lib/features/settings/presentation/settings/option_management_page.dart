import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ootd/presentation/home/mock_ootd_items.dart';

class OptionManagementPage extends ConsumerWidget {
  const OptionManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(ootdOptionConfigProvider);
    final groups = config.allGroups;

    return Scaffold(
      appBar: AppBar(
        title: const Text('选项管理'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              onPressed: () => _handleAddGroup(context, ref),
              tooltip: '新增选项',
              icon: const Icon(Icons.add_rounded, size: 18),
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

  Future<void> _handleAddGroup(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final value = await _showOptionInputDialog(
      context,
      title: '新增选项',
      hintText: '输入首个选项内容',
    );
    if (!context.mounted || value == null) {
      return;
    }

    final result = ref.read(ootdOptionConfigProvider.notifier).addExtraGroup(
      value,
    );
    if (!context.mounted) {
      return;
    }

    _showResult(context, result, successMessage: '已新增选项');
  }

  Future<void> _handleAddValue(
    BuildContext context,
    WidgetRef ref,
    String key,
  ) async {
    final value = await _showOptionInputDialog(context, title: '新增选项');
    if (!context.mounted || value == null) {
      return;
    }

    final result = ref
        .read(ootdOptionConfigProvider.notifier)
        .addOptionByKey(key, value);
    _showResult(context, result);
  }

  Future<void> _handleEditValue(
    BuildContext context,
    WidgetRef ref,
    String key,
    String currentValue,
  ) async {
    final value = await _showOptionInputDialog(
      context,
      title: '编辑选项',
      initialValue: currentValue,
    );
    if (!context.mounted || value == null) {
      return;
    }

    final result = ref
        .read(ootdOptionConfigProvider.notifier)
        .renameOptionByKey(key, currentValue, value);
    _showResult(context, result);
  }

  Future<void> _handleDeleteValue(
    BuildContext context,
    WidgetRef ref,
    String key,
    String currentValue,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除选项'),
          content: const Text('删除后，已有穿搭会自动切换到同组的其他选项。是否继续？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除整个选项'),
          content: const Text('删除后，这一组选项会从筛选和穿搭详情中移除。是否继续？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
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

    final result = ref.read(ootdOptionConfigProvider.notifier).deleteGroupByKey(
      key,
    );
    _showResult(context, result, successMessage: '已删除选项');
  }

  void _showResult(
    BuildContext context,
    OotdOptionEditResult result, {
    String successMessage = '已保存',
  }) {
    final message = switch (result) {
      OotdOptionEditResult.success => successMessage,
      OotdOptionEditResult.emptyValue => '内容不能为空',
      OotdOptionEditResult.duplicateValue => '这个选项已经存在',
      OotdOptionEditResult.minimumReached => '每一组至少保留一个选项',
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6F6)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              IconButton.filledTonal(
                onPressed: onAdd,
                tooltip: '新增内容',
                icon: const Icon(Icons.add_rounded, size: 16),
                constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: onDeleteGroup,
                tooltip: '删除整个选项',
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                padding: EdgeInsets.zero,
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
              const Divider(height: 10, color: Color(0xFFF0F4FA)),
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

    return Row(
      children: [
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        IconButton(
          onPressed: onEdit,
          tooltip: '编辑',
          icon: const Icon(Icons.edit_outlined, size: 18),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
          padding: EdgeInsets.zero,
        ),
        IconButton(
          onPressed: onDelete,
          tooltip: '删除',
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

Future<String?> _showOptionInputDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String hintText = '输入选项内容',
}) async {
  final controller = TextEditingController(text: initialValue);

  try {
    return await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: hintText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  } finally {
    controller.dispose();
  }
}
