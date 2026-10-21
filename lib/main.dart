import 'package:flutter/material.dart';

import 'l10n.dart';
import 'notifications.dart';
import 'tabs/community.dart';
import 'tabs/education.dart';
import 'tabs/health.dart';
import 'tabs/home.dart';
import 'tabs/onboarding.dart';
import 'tabs/settings.dart';
import 'tabs/transport.dart';
import 'widgets/mascot.dart';

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
          scaffoldBackgroundColor: const Color(0xFFFFFBF5),
          cardTheme: CardThemeData(
            elevation: 0.5,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
            ),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 1,
            backgroundColor: Color(0xFFFFFBF5),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
          ),
          chipTheme: const ChipThemeData(shape: StadiumBorder()),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            height: 66,
            elevation: 3,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFC2410C).withValues(alpha: 0.14),
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        home: const RootGate(),
      ),
    );
  }
}

/// Shows the first-launch language chooser until the user has picked a mode,
/// then the main app shell. Rebuilds automatically via [LocaleScope].
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = LocaleScope.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: settings.onboarded
          ? const HomeShell(key: ValueKey('shell'))
          : OnboardingScreen(key: const ValueKey('onboarding'), settings: settings),
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

  late final List<Widget> _tabs = [
    HomeTab(onNavigate: (i) => setState(() => _index = i)),
    const HealthTab(),
    const TransportTab(),
    const CommunityTab(),
    const EducationTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = LocaleScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const MascotAvatar(size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.t('app_title'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 19)),
                  Text(
                    s.t('tagline'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                settings.setLang(settings.lang == 'en' ? 'es' : 'en'),
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 40),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Text(
              settings.lang == 'en' ? 'ES' : 'EN',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
          IconButton(
            tooltip: s.t('settings'),
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const _SettingsPage(),
              ),
            ),
          ),
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
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: s.t('nav_home')),
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
        ],
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('settings'))),
      body: const SettingsTab(),
    );
  }
}
