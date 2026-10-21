import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../l10n.dart';
import '../local_data.dart';
import '../models.dart';
import '../services.dart';
import '../widgets/mascot.dart';
import 'common.dart';

class TransportTab extends StatefulWidget {
  const TransportTab({super.key});

  @override
  State<TransportTab> createState() => _TransportTabState();
}

class _TransportTabState extends State<TransportTab> {
  final _border = BorderService();
  final _corridors = CorridorService();

  late Future<List<BridgeReading>> _readings;
  List<Corridor> _live = const [];
  DateTime _updated = DateTime.now();
  bool _commercial = false;

  Bridge? _etaBridge;
  int _etaHour = DateTime.now().hour;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _readings = _border.currentReadings(commercial: _commercial);
      _live = _corridors.current();
      _updated = DateTime.now();
    });
  }

  Color _bridgeColor(BridgeState s) => switch (s) {
        BridgeState.moving => const Color(0xFF2E7D32),
        BridgeState.slow => const Color(0xFFF9A825),
        BridgeState.heavy => const Color(0xFFC62828),
      };

  String _bridgeLabel(S s, BridgeState st) => switch (st) {
        BridgeState.moving => s.t('bridge_moving'),
        BridgeState.slow => s.t('bridge_slow'),
        BridgeState.heavy => s.t('bridge_heavy'),
      };

  String _corridorLabel(S s, CorridorLevel l) => switch (l) {
        CorridorLevel.light => s.t('traffic_light'),
        CorridorLevel.moderate => s.t('traffic_moderate'),
        CorridorLevel.heavy => s.t('traffic_heavy'),
        CorridorLevel.severe => s.t('traffic_severe'),
      };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final es = s.es;
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _introCard(s),
          SectionCard(
            icon: Icons.directions_car,
            title: s.t('bridges'),
            trailing: TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(s.t('refresh')),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text(s.t('passenger_mode'),
                              style: const TextStyle(fontSize: 12)),
                          icon: const Icon(Icons.person, size: 16),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(s.t('cargo_mode'),
                              style: const TextStyle(fontSize: 12)),
                          icon: const Icon(Icons.local_shipping, size: 16),
                        ),
                      ],
                      selected: {_commercial},
                      onSelectionChanged: (v) {
                        _commercial = v.first;
                        _refresh();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FutureBuilder<List<BridgeReading>>(
                  future: _readings,
                  builder: (context, snap) {
                    final data = snap.data;
                    if (data == null) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Mascot(size: 68, mood: MascotMood.thinking),
                            SizedBox(height: 10),
                            SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final r in data) _bridgeCard(context, s, r, es),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('${s.t('updated')}: ${fmtTime(_updated)} ',
                                style: Theme.of(context).textTheme.bodySmall),
                            LiveBadge(live: data.any((r) => r.live)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          SectionCard(
            icon: Icons.auto_awesome,
            title: s.t('forecast'),
            trailing: const AiBadge(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final b in _bridgeList())
                  _forecastStrip(context, s, b),
                const SizedBox(height: 4),
                Text(s.t('ai_engine_note'),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.black54)),
              ],
            ),
          ),
          SectionCard(
            icon: Icons.calculate_outlined,
            title: s.t('eta_calculator'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _etaBridge?.id,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: s.t('eta_bridge')),
                  items: [
                    for (final b in _bridgeList())
                      DropdownMenuItem(
                        value: b.id,
                        child: Text(es ? b.nameEs : b.name,
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    _etaBridge = _bridgeList().where((b) => b.id == v).firstOrNull;
                  }),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text('${s.t('eta_when')}: ${_hourLabel(_etaHour)}'),
                    ),
                  ],
                ),
                Slider(
                  value: _etaHour.toDouble(),
                  min: 0,
                  max: 23,
                  divisions: 23,
                  label: _hourLabel(_etaHour),
                  onChanged: (v) => setState(() => _etaHour = v.round()),
                ),
                if (_etaBridge != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.07),
                      border: Border.all(
                          color: const Color(0xFF6A1B9A).withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF6A1B9A)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${s.t('eta_result')}: ${BorderService.predictWait(_etaBridge!, DateTime(2026, 1, 1, _etaHour))} ${s.t('min')}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6A1B9A)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SectionCard(
            icon: Icons.traffic_outlined,
            title: s.t('corridors'),
            trailing: LiveBadge(live: false),
            child: Column(
              children: [
                MapPane(
                  markers: [
                    for (final c in _live)
                      MapMarker(
                        point: LatLng(c.lat, c.lon),
                        color: levelColor(CorridorLevel.values.indexOf(c.level)),
                        icon: Icons.traffic,
                        label: '${c.name}: ${c.segment}',
                      ),
                  ],
                  center: const LatLng(26.19, -98.0),
                  zoom: 8.8,
                  height: 300,
                ),
                const SizedBox(height: 10),
                for (final c in _live) _corridorRow(context, s, c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Bridge> _bridgeList() {
    final seen = <String>{};
    final out = <Bridge>[];
    for (final b in kBridges) {
      if (seen.add(b.id)) out.add(b);
    }
    return out;
  }

  Widget _bridgeCard(BuildContext context, S s, BridgeReading r, bool es) {
    final color = _bridgeColor(r.state);
    final best = BorderService.bestWindow(r.bridge, DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: const Icon(Icons.directions_car, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(es ? r.bridge.nameEs : r.bridge.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                          '${es ? r.bridge.cityEs : r.bridge.city} · ${r.bridge.crossing}',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(_bridgeLabel(s, r.state),
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${r.waitMinutes}',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: color)),
                    Text(s.t('bridge_wait').toLowerCase(),
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: Colors.black54),
                const SizedBox(width: 4),
                Text('${s.t('best_time')}: ${_hourLabel(best.hour)} (${best.wait} ${s.t('min')})',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _forecastStrip(BuildContext context, S s, Bridge b) {
    final f = BorderService.forecast(b, DateTime.now(), hours: 8);
    final maxWait = f.map((e) => e.wait).fold(1, (a, c) => c > a ? c : a);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.es ? b.nameEs : b.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final e in f)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${e.wait}',
                            style: const TextStyle(fontSize: 9, color: Colors.black54)),
                        const SizedBox(height: 2),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 50 * (e.wait / maxWait) + 6,
                          decoration: BoxDecoration(
                            color: levelColor(e.wait >= 35
                                ? 3
                                : e.wait >= 20
                                    ? 2
                                    : e.wait >= 12
                                        ? 1
                                        : 0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(_hourShort(e.hour),
                            style: const TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _corridorRow(BuildContext context, S s, Corridor c) {
    final color = levelColor(CorridorLevel.values.indexOf(c.level));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.es ? c.nameEs : c.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(c.segment,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_corridorLabel(s, c.level),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              Text('${c.speedMph} mph',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  String _hourLabel(int h) {
    final hr = h % 12 == 0 ? 12 : h % 12;
    return '$hr:00 ${h < 12 ? 'AM' : 'PM'}';
  }

  String _hourShort(int h) {
    final hr = h % 12 == 0 ? 12 : h % 12;
    return '$hr${h < 12 ? 'a' : 'p'}';
  }

  Widget _introCard(S s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0E7490), Color(0xFF6A1B9A)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const MascotAvatar(size: 46),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(s.t('move_title'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(s.t('move_intro'),
                style: const TextStyle(color: Colors.white, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}
