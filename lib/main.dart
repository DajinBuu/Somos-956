import 'package:flutter/material.dart';

import 'l10n.dart';
import 'notifications.dart';
import 'tabs/dashboard.dart';
import 'tabs/heat.dart';
import 'tabs/traffic.dart';
import 'tabs/water.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.load();
  await Notifier.init();
  runApp(RgvReadyApp(settings: settings));
}

class RgvReadyApp extends StatelessWidget {
  final AppSettings settings;
  const RgvReadyApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      settings: settings,
      child: MaterialApp(
        title: 'RGV Ready',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD9531E),
            primary: const Color(0xFFC2410C),
            secondary: const Color(0xFF0E7490),
            brightness: Brightness.light,
          ),
          cardTheme: const CardThemeData(
            elevation: 1.5,
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            isDense: true,
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
    DashboardTab(),
    HeatTab(),
    WaterTab(),
    TrafficTab(),
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
            Text(s.t('app_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
            onPressed: () => settings.setLang(settings.lang == 'en' ? 'es' : 'en'),
            child: Text(
              settings.lang == 'en' ? 'ES' : 'EN',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: s.t('nav_dashboard')),
          NavigationDestination(
              icon: const Icon(Icons.wb_sunny_outlined),
              selectedIcon: const Icon(Icons.wb_sunny),
              label: s.t('nav_heat')),
          NavigationDestination(
              icon: const Icon(Icons.water_drop_outlined),
              selectedIcon: const Icon(Icons.water_drop),
              label: s.t('nav_water')),
          NavigationDestination(
              icon: const Icon(Icons.traffic_outlined),
              selectedIcon: const Icon(Icons.traffic),
              label: s.t('nav_traffic')),
        ],
      ),
    );
  }
}
