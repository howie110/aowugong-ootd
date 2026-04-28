import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/ootd/presentation/detail/ootd_detail_page.dart';
import '../features/ootd/presentation/home/home_page.dart';
import '../features/ootd/presentation/home/mock_ootd_items.dart';
import '../features/settings/presentation/settings/settings_page.dart';
import '../shared/navigation/smooth_page_route.dart';
import 'providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(rootTabProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(currentTab)),
        actions: [_buildAppBarAction(context, ref, currentTab)],
      ),
      body: SafeArea(
        child: ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.linear,
            layoutBuilder: (currentChild, previousChildren) {
              final children = <Widget>[
                ...previousChildren,
              ];
              if (currentChild != null) {
                children.add(currentChild);
              }

              return Stack(
                fit: StackFit.expand,
                children: children,
              );
            },
            transitionBuilder: (child, animation) {
              final isIncoming = child.key == ValueKey(currentTab);
              if (!isIncoming) {
                return FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeIn,
                    ),
                  ),
                  child: child,
                );
              }

              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );

              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.03, 0),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(currentTab),
              child: _buildPage(currentTab),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab.index,
        onDestinationSelected: (index) {
          ref.read(rootTabProvider.notifier).setTab(RootTab.values[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view),
            label: '穿搭',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }

  Widget _buildPage(RootTab tab) {
    return switch (tab) {
      RootTab.home => const HomePage(),
      RootTab.settings => const SettingsPage(),
    };
  }

  Widget _buildAppBarAction(
    BuildContext context,
    WidgetRef ref,
    RootTab currentTab,
  ) {
    if (currentTab != RootTab.home) {
      return const SizedBox(width: 64);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: IconButton.filledTonal(
        onPressed: () {
          final today = formatDateLabel(DateTime.now());
          final hasToday = ref.read(ootdItemsProvider.notifier).hasItemOnDate(today);
          if (hasToday) {
            final messenger = ScaffoldMessenger.maybeOf(context);
            messenger
              ?..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('今天已经有穿搭，不能重复新增')),
              );
            return;
          }

          Navigator.of(context).push(
            SmoothPageRoute<void>(
              page: const OotdDetailPage(),
            ),
          );
        },
        tooltip: '新增穿搭',
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }

  String _titleFor(RootTab tab) {
    return switch (tab) {
      RootTab.home => '穿搭',
      RootTab.settings => '设置',
    };
  }
}
