import 'package:flutter/material.dart';
import 'package:illyricum_music/src/features/menu/colors_menu.dart';
import 'package:sidebarx/sidebarx.dart';

class SidebarXMenus extends StatelessWidget {
  const SidebarXMenus({
    super.key,
    required SidebarXController controller,
    required this.closeDrawer,
  }) : _controller = controller;

  final SidebarXController _controller;
  final VoidCallback closeDrawer;

  @override
  Widget build(BuildContext context) {
    return SidebarX(
      controller: _controller,
      theme: SidebarXTheme(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: canvasColor,
          borderRadius: BorderRadius.circular(20),
        ),
        hoverColor: scaffoldBackgroundColor,
        hoverTextStyle: const TextStyle(color: Colors.black),
        textStyle: const TextStyle(color: Colors.black),
        selectedTextStyle: const TextStyle(color: Colors.black),
        itemTextPadding: const EdgeInsets.only(left: 30),
        selectedItemTextPadding: const EdgeInsets.only(left: 30),
        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [accentCanvasColor, canvasColor],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 30,
            ),
          ],
        ),
        iconTheme: const IconThemeData(
          color: Colors.black,
          size: 20,
        ),
        selectedIconTheme: const IconThemeData(
          size: 20,
        ),
      ),
      extendedTheme: const SidebarXTheme(
        width: 250,
        decoration: BoxDecoration(
          color: canvasColor,
        ),
      ),
      headerBuilder: (context, extended) {
        return const SizedBox(
          height: 100,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
      items: [
        SidebarXItem(
          icon: Icons.music_note,
          label: 'Musiche',
          onTap:  closeDrawer,
        ),
        SidebarXItem(
          icon: Icons.download,
          label: 'Scarica',
          onTap: closeDrawer,
        ),
      ],
      footerItems: [
        SidebarXItem(
          icon: Icons.settings,
          label: 'Settings',
          onTap: closeDrawer,
        ),
      ],
    );
  }
}
