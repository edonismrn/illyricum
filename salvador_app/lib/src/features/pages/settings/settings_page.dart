import 'package:illyricum_music/src/features/pages/settings/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';



class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  onThemePressed(WidgetRef ref, ThemeMode themeMode) {
    ref.read(settingsControllerProvider.notifier).updateThemeMode(themeMode);
  }

   @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          alignment: Alignment.center,
          child: ListView(
            children: [
              _SingleSection(
                title: "Themes",
                children: [
                  const SizedBox(height: 20),
                  _CustomListTile(
                    title: "Dark Mode",
                    icon: Icons.dark_mode,
                    trailing: TextButton(
                      onPressed: () => {
                        onThemePressed(ref, ThemeMode.dark),
                      },
                      child: const Text("Seleziona"),
                    ),
                  ),
                  _CustomListTile(
                    title: "Light Mode",
                    icon: Icons.light_mode,
                    trailing: TextButton(
                      onPressed: () => {
                        onThemePressed(ref, ThemeMode.light),
                      },
                      child: const Text("Seleziona"),
                    ),
                  ),
                  _CustomListTile(
                    title: "System Mode",
                    icon: Icons.cloud,
                    trailing: TextButton(
                      onPressed: () => {
                        onThemePressed(ref, ThemeMode.system),
                      },
                      child: const Text("Seleziona"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
                _CustomListTile(
                    title: "Lingua",
                    icon: Icons.cloud,
                    trailing: TextButton(
                      onPressed: () => {
                        //onLanguageChanged(ref, ),
                      },
                      child: const Text("Seleziona"),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  const _CustomListTile(
      {required this.title, required this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      leading: Icon(icon),
      trailing: trailing,
      onTap: () {},
    );
  }
}

class _SingleSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  const _SingleSection({
    this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        Column(
          children: children,
        ),
      ],
    );
  }
}

class RotatingHourglass extends StatefulWidget {
  const RotatingHourglass({super.key});

  @override
  RotatingHourglassState createState() => RotatingHourglassState();
}

class RotatingHourglassState extends State<RotatingHourglass>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _animationController,
      child: const Icon(
        Icons.hourglass_bottom,
        size: 40,
      ),
    );
  }
}
