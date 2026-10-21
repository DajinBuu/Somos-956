import 'package:flutter/material.dart';

import 'l10n.dart';
import 'notifications.dart';
import 'tabs/community.dart';
import 'tabs/education.dart';
import 'tabs/health.dart';
import 'tabs/settings.dart';
import 'tabs/transport.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.load();
  await Notifier.init();
  runApp(Somos956App(settings: settings));
}

class Somos956App extends StatelessWidget {
  final AppSettings settings;
  const Somos956App({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      settings: settings,
      child: MaterialApp(
        title: 'Somos 956',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFC2410C),
            primary: const Color(0xFFC2410C),
            secondary: const Color(0xFF0E7490),
            tertiary: const Color(0xFF6A1B9A),
            brightness: Brightness.light,
          ),
          cardTheme: const CardThemeData(
            elevation: 1.5,
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          chipTheme: const ChipThemeData(
            shape: StadiumBorder(),
          ),
        ),
        home: const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    HealthTab(),
    TransportTab(),
    CommunityTab(),
    EducationTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = LocaleScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_alt_rounded, size: 22),
                const SizedBox(width: 8),
                Text(s.t('app_title'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
            Text(
              s.t('tagline'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                settings.setLang(settings.lang == 'en' ? 'es' : 'en'),
            child: Text(
              settings.lang == 'en' ? 'ES' : 'EN',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: _index, children: _tabs),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.local_hospital_outlined),
              selectedIcon: const Icon(Icons.local_hospital),
              label: s.t('nav_health')),
          NavigationDestination(
              icon: const Icon(Icons.directions_car_outlined),
              selectedIcon: const Icon(Icons.directions_car),
              label: s.t('nav_move')),
          NavigationDestination(
              icon: const Icon(Icons.volunteer_activism_outlined),
              selectedIcon: const Icon(Icons.volunteer_activism),
              label: s.t('nav_community')),
          NavigationDestination(
              icon: const Icon(Icons.school_outlined),
              selectedIcon: const Icon(Icons.school),
              label: s.t('nav_education')),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: s.t('settings')),
        ],
      ),
    );
  }
}
