import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RootTab { home, settings }

final rootTabProvider = NotifierProvider<RootTabNotifier, RootTab>(
  RootTabNotifier.new,
);

class RootTabNotifier extends Notifier<RootTab> {
  @override
  RootTab build() => RootTab.home;

  void setTab(RootTab tab) {
    if (state == tab) {
      return;
    }

    state = tab;
  }
}
