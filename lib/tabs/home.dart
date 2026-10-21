import 'package:flutter/material.dart';

import '../l10n.dart';
import '../local_data.dart';
import '../location.dart';
import '../models.dart';
import '../services.dart';
import '../widgets/mascot.dart';
import 'common.dart';

class HomeTab extends StatefulWidget {
  final void Function(int index) onNavigate;
  const HomeTab({super.key, required this.onNavigate});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _border = BorderService();
  final _weather = WeatherService();
  late Future<List<BridgeReading>> _readings;
  late Future<WeatherSnapshot?> _wx;
  late Future<AirQuality?> _aqi;
  late Future<List<WeatherAlert>> _alerts;
  final bool _nearest = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _readings = _border.currentReadings();
    _wx = _weatherWithLocation();
    _aqi = _aqiWithLocation();
    _alerts = _weather.alerts();
  }

  Future<WeatherSnapshot?> _weatherWithLocation() async {
    final p = await locationService.ensure();
    if (p != null && mounted) setState(() {});
    return _weather.current(atLat: p?.latitude, atLon: p?.longitude);
  }

  Future<AirQuality?> _aqiWithLocation() async {
    final p = await locationService.ensure();
    return _weather.airQuality(atLat: p?.latitude, atLon: p?.longitude);
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait<void>([_readings, _wx, _aqi, _alerts]);
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
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          _hero(s, theme),
          _locationBanner(s, theme),
          _liveBanner(s, theme),
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
  Widget _locationBanner(S s, ThemeData theme) {
    final hasFix = locationService.hasFix;
    final denied = locationService.status == LocStatus.denied ||
        locationService.status == LocStatus.deniedForever ||
        locationService.status == LocStatus.unsupported;
    final title = locationService.isManual
        ? s.t('manual_location')
        : (denied ? s.t('location_blocked') : s.t('location_prompt'));
    final subtitle = locationService.isManual || hasFix
        ? s.t('pick_location_hint')
        : (denied ? s.t('location_blocked_hint') : s.t('location_hint'));
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Material(
        color: theme.colorScheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _pickLocation,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                    locationService.isManual
                        ? Icons.pin_drop
                        : (hasFix
                            ? Icons.my_location
                            : (denied
                                ? Icons.location_disabled
                                : Icons.my_location)),
                    color: theme.colorScheme.secondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13.5)),
                      Text(subtitle,
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.edit_location_alt,
                    color: theme.colorScheme.secondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickLocation() async {
    await showLocationPicker(context);
    if (mounted) setState(_load);
  }

  Widget _liveBanner(S s, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<List<WeatherAlert>>(
                future: _alerts,
                builder: (context, snap) {
                  final alerts = snap.data ?? const <WeatherAlert>[];
                  if (alerts.isEmpty) return const SizedBox.shrink();
                  final a = alerts.first;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC62828).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFC62828)
                              .withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFC62828)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.event,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFC62828))),
                              const SizedBox(height: 2),
                              Text(
                                a.headline.isNotEmpty
                                    ? a.headline
                                    : a.description,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5),
                              ),
                              if (alerts.length > 1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '+${alerts.length - 1} ${s.t('alerts').toLowerCase()}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFC62828)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Row(
                children: [
                  FutureBuilder<WeatherSnapshot?>(
                    future: _wx,
                    builder: (context, snap) {
                      final w = snap.data;
                      if (snap.connectionState != ConnectionState.done) {
                        return const _LoadingChip();
                      }
                      if (w == null) return Expanded(child: _offlineChip(s));
                      return Expanded(
                        child: Row(
                          children: [
                            Icon(_weatherIcon(w.weatherCode),
                                size: 34, color: const Color(0xFF0E7490)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${w.temperatureF.round()}°F',
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900)),
                                  Text(
                                    '${w.condition} · ${s.t('feels_like')} ${w.feelsLikeF.round()}°',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  FutureBuilder<AirQuality?>(
                    future: _aqi,
                    builder: (context, snap) {
                      final a = snap.data;
                      if (a == null) return const SizedBox.shrink();
                      final color = _aqiColor(a.aqi);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('AQI ${a.aqi}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                  fontSize: 15)),
                          Text(_aqiLabel(s, a.aqi),
                              style: TextStyle(fontSize: 11, color: color)),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FutureBuilder<WeatherSnapshot?>(
                future: _wx,
                builder: (context, snap) {
                  final w = snap.data;
                  if (w == null) return const SizedBox.shrink();
                  return Row(
                    children: [
                      _miniInfo(theme, Icons.water_drop_outlined,
                          '${w.humidity}%'),
                      const SizedBox(width: 14),
                      _miniInfo(theme, Icons.air,
                          '${w.windMph.round()} mph'),
                      if (w.heatIndexF != null) ...[
                        const SizedBox(width: 14),
                        _miniInfo(theme, Icons.thermostat,
                            '${s.t('heat_index')} ${w.heatIndexF!.round()}°'),
                      ],
                      const Spacer(),
                      LiveBadge(live: true, label: s.t('data_live')),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniInfo(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.secondary),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12.5)),
      ],
    );
  }

  Widget _offlineChip(S s) {
    return Row(
      children: [
        const Icon(Icons.cloud_off, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Flexible(
          child: Text(s.t('load_error'),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: Colors.blueGrey)),
        ),
      ],
    );
  }

  static IconData _weatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code <= 3) return Icons.wb_cloudy;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 51 && code <= 67) return Icons.grain;
    if (code >= 80 && code <= 82) return Icons.umbrella;
    if (code >= 95) return Icons.thunderstorm;
    return Icons.cloud;
  }

  static Color _aqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF2E7D32);
    if (aqi <= 100) return const Color(0xFFF9A825);
    if (aqi <= 150) return const Color(0xFFEF6C00);
    if (aqi <= 200) return const Color(0xFFC62828);
    if (aqi <= 300) return const Color(0xFF6A1B9A);
    return const Color(0xFF7F1D1D);
  }

  static String _aqiLabel(S s, int aqi) {
    if (aqi <= 50) return s.t('aqi_good');
    if (aqi <= 100) return s.t('aqi_moderate');
    if (aqi <= 150) return s.t('aqi_unhealthy_sensitive');
    if (aqi <= 200) return s.t('aqi_unhealthy');
    if (aqi <= 300) return s.t('aqi_very_unhealthy');
    return s.t('aqi_hazardous');
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
                      final haveFix = locationService.hasFix;
                      final sorted = [...data]..sort((a, b) => _nearest && haveFix
                          ? locationService
                              .distanceTo(a.bridge.lat, a.bridge.lon)
                              .compareTo(locationService.distanceTo(
                                  b.bridge.lat, b.bridge.lon))
                          : a.waitMinutes.compareTo(b.waitMinutes));
                      final top = sorted.take(3).toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (haveFix)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.near_me,
                                      size: 14, color: Color(0xFF0E7490)),
                                  const SizedBox(width: 4),
                                  Text(
                                    _nearest
                                        ? s.t('nearest_to_you')
                                        : s.t('fastest_now'),
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.secondary),
                                  ),
                                ],
                              ),
                            ),
                          for (final r in top)
                            _glanceBridgeRow(context, s, r, haveFix),
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

  Widget _glanceBridgeRow(
      BuildContext context, S s, BridgeReading r, bool haveFix) {
    final color = switch (r.state) {
      BridgeState.moving => const Color(0xFF2E7D32),
      BridgeState.slow => const Color(0xFFF9A825),
      BridgeState.heavy => const Color(0xFFC62828),
    };
    final mi = haveFix
        ? locationService.distanceTo(r.bridge.lat, r.bridge.lon)
        : null;
    return InkWell(
      onTap: () => LocationService.directions(
        lat: r.bridge.lat,
        lon: r.bridge.lon,
        label: r.bridge.name,
        origin: locationService.origin,
      ),
      child: Padding(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.es ? r.bridge.nameEs : r.bridge.name,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                  if (mi != null)
                    Text('${mi.toStringAsFixed(1)} ${s.t('mi_away')}',
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                ],
              ),
            ),
            Text('${r.waitMinutes} ${s.t('min')}',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 13.5)),
            const SizedBox(width: 4),
            const Icon(Icons.directions, size: 15, color: Color(0xFF0E7490)),
          ],
        ),
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

class _LoadingChip extends StatelessWidget {
  const _LoadingChip();

  @override
  Widget build(BuildContext context) {
    return const Expanded(
      child: Row(
        children: [
          SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 8),
          Text('…', style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
