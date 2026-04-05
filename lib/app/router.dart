import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/ootd/presentation/home/home_page.dart';
import '../features/settings/presentation/settings/settings_page.dart';
import 'providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const List<Widget> _pages = <Widget>[HomePage(), SettingsPage()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(rootTabProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_titleFor(currentTab))),
      body: SafeArea(
        child: IndexedStack(index: currentTab.index, children: _pages),
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
            label: '首页',
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

  String _titleFor(RootTab tab) {
    return switch (tab) {
      RootTab.home => 'Daily OOTD',
      RootTab.settings => '设置',
    };
  }
}
