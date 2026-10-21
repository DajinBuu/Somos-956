import 'package:flutter/material.dart';

import '../l10n.dart';
import '../local_data.dart';
import '../models.dart';
import '../services.dart';
import '../widgets/mascot.dart';

class HomeTab extends StatefulWidget {
  final void Function(int index) onNavigate;
  const HomeTab({super.key, required this.onNavigate});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _border = BorderService();
  late Future<List<BridgeReading>> _readings;

  @override
  void initState() {
    super.initState();
    _readings = _border.currentReadings();
  }

  String _greetingKey() {
    final h = DateTime.now().hour;
    if (h < 12) return 'home_greeting_morning';
    if (h < 18) return 'home_greeting_afternoon';
    return 'home_greeting_evening';
  }

  MascotMood _greetingMood() {
    final h = DateTime.now().hour;
    if (h < 12) return MascotMood.wave;
    if (h < 18) return MascotMood.happy;
    return MascotMood.cheer;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async =>
          setState(() => _readings = _border.currentReadings()),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          _hero(s, theme),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(s.t('home_quick'),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          _quickGrid(s, theme),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
            child: Text(s.t('home_glance'),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          _glanceCards(s, theme),
          const SizedBox(height: 14),
          _tipCard(s),
        ],
      ),
    );
  }

  Widget _hero(S s, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFC2410C), Color(0xFF0E7490)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC2410C).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Mascot(size: 78, mood: _greetingMood()),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.t(_greetingKey()),
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(s.t('app_title'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 2),
                    Text(s.t('region'),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(s.t('home_welcome'),
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35)),
        ],
      ),
    );
  }

  Widget _quickGrid(S s, ThemeData theme) {
    final items = [
      (Icons.local_hospital, 'home_find_care', 'home_care_short',
          const Color(0xFFC2410C), 1),
      (Icons.directions_car, 'home_bridge_waits', 'home_bridges_short',
          const Color(0xFF0E7490), 2),
      (Icons.volunteer_activism, 'home_get_help', 'home_help_short',
          const Color(0xFF2E7D32), 3),
      (Icons.school, 'home_edu_tools', 'home_edu_short',
          const Color(0xFF6A1B9A), 4),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i += 2)
            Row(
              children: [
                Expanded(child: _quickCard(s, theme, items[i])),
                const SizedBox(width: 10),
                Expanded(
                    child: i + 1 < items.length
                        ? _quickCard(s, theme, items[i + 1])
                        : const SizedBox.shrink()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _quickCard(
      S s,
      ThemeData theme,
      (IconData, String, String, Color, int) item) {
    final (icon, titleKey, subKey, color, index) = item;
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onNavigate(index),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 10),
              Text(s.t(titleKey),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14.5)),
              const SizedBox(height: 2),
              Text(s.t(subKey),
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.25)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(s.t('home_open'),
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward, size: 13, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glanceCards(S s, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_car, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(s.t('home_bridge_waits'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                      TextButton(
                        onPressed: () => widget.onNavigate(2),
                        child: Text(s.t('see_all')),
                      ),
                    ],
                  ),
                  FutureBuilder<List<BridgeReading>>(
                    future: _readings,
                    builder: (context, snap) {
                      final data = snap.data;
                      if (data == null) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                              child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5))),
                        );
                      }
                      final sorted = [...data]
                        ..sort((a, b) => a.waitMinutes.compareTo(b.waitMinutes));
                      final top = sorted.take(3).toList();
                      return Column(
                        children: [
                          for (final r in top) _glanceBridgeRow(context, s, r),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  theme,
                  Icons.medical_services,
                  const Color(0xFFC2410C),
                  '${kCareFacilities.length}',
                  s.t('care_directory'),
                  () => widget.onNavigate(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  theme,
                  Icons.volunteer_activism,
                  const Color(0xFF2E7D32),
                  '${kCommunityResources.length}',
                  s.t('resources'),
                  () => widget.onNavigate(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  theme,
                  Icons.school,
                  const Color(0xFF6A1B9A),
                  '${kEduResources.length}',
                  s.t('education_title'),
                  () => widget.onNavigate(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glanceBridgeRow(BuildContext context, S s, BridgeReading r) {
    final color = switch (r.state) {
      BridgeState.moving => const Color(0xFF2E7D32),
      BridgeState.slow => const Color(0xFFF9A825),
      BridgeState.heavy => const Color(0xFFC62828),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(s.es ? r.bridge.nameEs : r.bridge.name,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
          Text('${r.waitMinutes} ${s.t('min')}',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 13.5)),
        ],
      ),
    );
  }

  Widget _miniStat(ThemeData theme, IconData icon, Color color, String value,
      String label, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 20)),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tipCard(S s) {
    final tip = kCulturalTips[DateTime.now().day % kCulturalTips.length];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        elevation: 0,
        color: const Color(0xFFFFF7ED),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MascotAvatar(size: 52, mood: MascotMood.thinking),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.t('home_tip'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFF9A3412))),
                    const SizedBox(height: 4),
                    Text(s.pick(tip.titleEn, tip.titleEs),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(s.pick(tip.bodyEn, tip.bodyEs),
                        style: const TextStyle(fontSize: 13, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
