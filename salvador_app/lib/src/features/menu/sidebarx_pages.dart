import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:illyricum_music/src/features/pages/download/download_page.dart';
import 'package:illyricum_music/src/features/pages/musiche/musiche_page.dart';
import 'package:illyricum_music/src/features/pages/settings/settings_page.dart';
import 'package:sidebarx/sidebarx.dart';

class SidebarXPages extends ConsumerWidget {
  SidebarXPages({
    super.key,
    required this.controller,
  });

  final SidebarXController controller;

  final List<Widget Function()> pageBuilders = [
    () => MusichePage(),
    () => DownloadPage(),
    () => const SettingsView(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final selectedPageIndex =
            controller.selectedIndex >= 0 && controller.selectedIndex < pageBuilders.length
                ? controller.selectedIndex
                : 0;

        return IndexedStack(
          index: selectedPageIndex,
          children: pageBuilders.map((pageBuilder) => pageBuilder()).toList(),
        );
      },
    );
  }
}