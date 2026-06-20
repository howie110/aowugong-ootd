import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design/app_theme.dart';
import '../../../../shared/design/ootd_card.dart';
import '../detail/ootd_detail_page.dart';
import '../shared/compact_option_group.dart';
import '../shared/ootd_image_view.dart';
import '../../../../shared/navigation/smooth_page_route.dart';
import 'mock_ootd_items.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filteredItems = ref.watch(filteredOotdItemsProvider);
    final filters = ref.watch(ootdFiltersProvider);
    final optionGroups = ref.watch(
      ootdOptionConfigProvider.select((config) => config.allGroups),
    );
    final filterNotifier = ref.read(ootdFiltersProvider.notifier);

    return CustomScrollView(
      key: const PageStorageKey<String>('home-scroll'),
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              for (var index = 0; index < optionGroups.length; index++) ...[
                _FilterDimensionRow(
                  options: optionGroups[index].values,
                  selected: filters.valuesOf(optionGroups[index].key),
                  onOptionTap: (value) {
                    filterNotifier.toggleOption(optionGroups[index].key, value);
                  },
                ),
                if (index != optionGroups.length - 1) const SizedBox(height: 8),
              ],
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${filteredItems.length} 条',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: filteredItems.isEmpty
              ? const SliverToBoxAdapter(child: _EmptyState())
              : SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _GridEntryCard(
                      item: filteredItems[index],
                    ),
                    childCount: filteredItems.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.72,
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterDimensionRow extends StatelessWidget {
  const _FilterDimensionRow({
    required this.options,
    required this.selected,
    required this.onOptionTap,
  });

  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onOptionTap;

  @override
  Widget build(BuildContext context) {
    return CompactOptionGroup<String>(
      options: options,
      isSelected: (option) => selected.contains(option),
      labelBuilder: (option) => option,
      onTap: onOptionTap,
    );
  }
}

class _GridEntryCard extends StatelessWidget {
  const _GridEntryCard({required this.item});

  final MockOotdItem item;

  @override
  Widget build(BuildContext context) {
    final ootd = Theme.of(context).extension<OotdColors>() ?? OotdColors.light;

    return Material(
      color: ootd.cardSurface,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        label: '穿搭 ${item.dateLabel}',
        button: true,
        child: InkWell(
          key: Key('ootd-card-${item.id}'),
          onTap: () {
            Navigator.of(context).push(
              SmoothPageRoute<void>(
                page: OotdDetailPage(itemId: item.id),
              ),
            );
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ootd.cardBorder),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                OotdImageView(image: item.primaryImage),
                Positioned(
                  right: 6,
                  bottom: 5,
                  child: _GridDateStamp(label: item.dateLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridDateStamp extends StatelessWidget {
  const _GridDateStamp({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ootd = Theme.of(context).extension<OotdColors>() ?? OotdColors.light;

    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: ootd.mutedForeground,
        fontSize: 7.4,
        fontWeight: FontWeight.w600,
        height: 1,
        letterSpacing: 0,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ootd = theme.extension<OotdColors>() ?? OotdColors.light;

    return OotdCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 28,
            color: ootd.subtleIcon,
          ),
          const SizedBox(height: 12),
          Text(
            '当前筛选条件下没有匹配的穿搭',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
