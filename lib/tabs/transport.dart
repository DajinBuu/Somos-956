import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../l10n.dart';
import '../local_data.dart';
import '../location.dart';
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
  final _roads = RoadService();

  late Future<List<BridgeReading>> _readings;
  late Future<List<RoadEvent>> _closures;
  DateTime _updated = DateTime.now();
  bool _commercial = false;
  bool _nearestFirst = true;

  Bridge? _etaBridge;
  int _etaHour = DateTime.now().hour;
  int _etaWeekday = DateTime.now().weekday;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _readings = _border.currentReadings(commercial: _commercial);
      _closures = _roads.closures(
        nearLat: locationService.hasFix ? locationService.reference.$1 : null,
        nearLon: locationService.hasFix ? locationService.reference.$2 : null,
      );
      _updated = DateTime.now();
    });
  }

  Future<void> _enableLocation() async {
    await showLocationPicker(context);
    if (mounted) _refresh();
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

  String _roadLabel(S s, RoadSeverity sev) => switch (sev) {
        RoadSeverity.closure => s.t('traffic_severe'),
        RoadSeverity.major => s.t('traffic_heavy'),
        RoadSeverity.minor => s.t('traffic_moderate'),
        RoadSeverity.info => s.t('traffic_light'),
      };

  Color _roadColor(RoadSeverity sev) => switch (sev) {
        RoadSeverity.closure => const Color(0xFFC62828),
        RoadSeverity.major => const Color(0xFFEF6C00),
        RoadSeverity.minor => const Color(0xFFF9A825),
        RoadSeverity.info => const Color(0xFF0E7490),
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
            title: 'bridges',
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
                    final haveFix = locationService.hasFix;
                    final list = [...data];
                    if (haveFix && _nearestFirst) {
                      list.sort((a, b) => locationService
                          .distanceTo(a.bridge.lat, a.bridge.lon)
                          .compareTo(locationService.distanceTo(
                              b.bridge.lat, b.bridge.lon)));
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (!haveFix)
                              ActionChip(
                                avatar: const Icon(Icons.my_location, size: 16),
                                label: Text(s.t('location_prompt'),
                                    style: const TextStyle(fontSize: 12)),
                                onPressed: _enableLocation,
                              )
                            else
                              ChoiceChip(
                                avatar: Icon(
                                    _nearestFirst
                                        ? Icons.near_me
                                        : Icons.speed,
                                    size: 16),
                                label: Text(
                                    _nearestFirst
                                        ? s.t('nearest_to_you')
                                        : s.t('fastest_now'),
                                    style: const TextStyle(fontSize: 12)),
                                selected: _nearestFirst,
                                onSelected: (v) =>
                                    setState(() => _nearestFirst = v),
                              ),
                            const SizedBox(width: 8),
                            ActionChip(
                              avatar: Icon(
                                  locationService.isManual
                                      ? Icons.pin_drop
                                      : Icons.my_location,
                                  size: 16),
                              label: Text(
                                  locationService.isManual
                                      ? s.t('manual_location')
                                      : s.t('pick_location'),
                                  style: const TextStyle(fontSize: 12)),
                              onPressed: _enableLocation,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        MapPane(
                          markers: [
                            for (final r in list)
                              MapMarker(
                                point: LatLng(r.bridge.lat, r.bridge.lon),
                                color: _bridgeColor(r.state),
                                icon: Icons.directions_car,
                                label:
                                    '${r.bridge.name}: ${r.waitMinutes} ${s.t('min')}',
                              ),
                          ],
                          center: haveFix
                              ? LatLng(locationService.reference.$1,
                                  locationService.reference.$2)
                              : const LatLng(26.05, -98.0),
                          zoom: 8.6,
                          height: 280,
                        ),
                        const SizedBox(height: 10),
                        for (final r in list)
                          _bridgeCard(context, s, r, es, haveFix),
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
            title: 'forecast',
            subtitle: 'ai_engine_note',
            trailing: const AiBadge(label: 'Estimate'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final b in _bridgeList())
                  _forecastStrip(context, s, b),
              ],
            ),
          ),
          SectionCard(
            icon: Icons.calculate_outlined,
            title: 'eta_calculator',
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
                Text(s.t('eta_day'),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final d in const [1, 2, 3, 4, 5, 6, 7])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(_dayLabel(s, d),
                                style: const TextStyle(fontSize: 12.5)),
                            selected: _etaWeekday == d,
                            onSelected: (_) =>
                                setState(() => _etaWeekday = d),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          '${s.t('eta_when')}: ${_hourLabel(_etaHour)}'),
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
                if (_etaBridge != null) ...[
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
                        const Icon(Icons.auto_awesome,
                            color: Color(0xFF6A1B9A)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${s.t('eta_result')} · ${_dayLabel(s, _etaWeekday)} ${_hourLabel(_etaHour)}: '
                            '${BorderService.predictWaitForDay(_etaBridge!, _etaWeekday, _etaHour)} ${s.t('min')}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6A1B9A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _dayPatternBars(context, s, _etaBridge!),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.history,
                          size: 15, color: Color(0xFF6A1B9A)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(s.t('eta_historical'),
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SectionCard(
            icon: Icons.construction_outlined,
            title: 'road_closures',
            trailing: FutureBuilder<List<RoadEvent>>(
              future: _closures,
              builder: (context, snap) {
                final done = snap.connectionState == ConnectionState.done;
                final events = snap.data ?? const <RoadEvent>[];
                return LiveBadge(
                  live: done && events.isNotEmpty,
                  label: !done
                      ? s.t('loading')
                      : (events.isEmpty
                          ? s.t('none_active')
                          : s.t('data_live')),
                );
              },
            ),
            child: FutureBuilder<List<RoadEvent>>(
              future: _closures,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                        child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5))),
                  );
                }
                final events = snap.data ?? const <RoadEvent>[];
                if (events.isEmpty) {
                  return EmptyState(
                    message: s.t('no_closures'),
                    mood: MascotMood.happy,
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final e in events.take(12)) _roadRow(context, s, e),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${s.t('data_source')}: TxDOT DriveTexas',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
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

  Widget _bridgeCard(
      BuildContext context, S s, BridgeReading r, bool es, bool haveFix) {
    final color = _bridgeColor(r.state);
    final best = BorderService.bestWindow(r.bridge, DateTime.now());
    final mi = haveFix
        ? locationService.distanceTo(r.bridge.lat, r.bridge.lon)
        : null;
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
                          '${es ? r.bridge.cityEs : r.bridge.city} · ${r.bridge.crossing}'
                          '${mi != null ? ' · ${mi.toStringAsFixed(1)} ${s.t('mi_away')}' : ''}',
                          style: Theme.of(context).textTheme.bodySmall),
                      Row(
                        children: [
                          Text(_bridgeLabel(s, r.state),
                              style: TextStyle(
                                  color: color, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          if (r.live)
                            const Icon(Icons.cell_tower,
                                size: 12, color: Colors.green)
                          else
                            const Icon(Icons.schedule,
                                size: 12, color: Colors.blueGrey),
                          if (!r.live) ...[
                            const SizedBox(width: 3),
                            Text(s.t('est_wait'),
                                style: const TextStyle(
                                    fontSize: 10.5, color: Colors.blueGrey)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (r.lanesClosed && !r.live)
                      Text(s.t('lanes_closed'),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color))
                    else
                      Text('${r.waitMinutes}',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: color)),
                    Text(s.t('bridge_wait').toLowerCase(),
                        style: Theme.of(context).textTheme.labelSmall),
                    Text('as of ${fmtTime(r.updated)}',
                        style: TextStyle(
                            fontSize: 9.5,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (r.passengerWait != null ||
                r.commercialWait != null ||
                r.pedestrianWait != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (r.passengerWait != null)
                    _laneChip(context, Icons.person, s.t('passenger_mode'),
                        r.passengerWait!),
                  if (r.commercialWait != null)
                    _laneChip(context, Icons.local_shipping, s.t('cargo_mode'),
                        r.commercialWait!),
                  if (r.pedestrianWait != null)
                    _laneChip(context, Icons.directions_walk,
                        s.t('pedestrian'), r.pedestrianWait!),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                            '${s.t('best_time')}: ${_hourLabel(best.hour)} (${best.wait} ${s.t('min')})',
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => LocationService.directions(
                    lat: r.bridge.lat,
                    lon: r.bridge.lon,
                    label: r.bridge.name,
                    origin: locationService.origin,
                  ),
                  icon: const Icon(Icons.directions, size: 16),
                  label: Text(s.t('directions'),
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _laneChip(
      BuildContext context, IconData icon, String label, int minutes) {
    final color = BorderService.stateFor(minutes) == BridgeState.heavy
        ? const Color(0xFFC62828)
        : BorderService.stateFor(minutes) == BridgeState.slow
            ? const Color(0xFFF9A825)
            : const Color(0xFF2E7D32);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text('$label: $minutes min',
              style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _dayLabel(S s, int weekday) {
    const keys = [
      'day_sun', 'day_mon', 'day_tue', 'day_wed',
      'day_thu', 'day_fri', 'day_sat',
    ];
    return s.t(keys[(weekday - 1) % 7]);
  }

  /// Shows the average wait per weekday and highlights the busiest and lightest
  /// days, so users can see which days run longer before they pick one.
  Widget _dayPatternBars(BuildContext context, S s, Bridge b) {
    final avgs = BorderService.dailyAverages(b);
    final maxAvg = avgs.reduce((a, c) => c > a ? c : a);
    var busiest = 1;
    var lightest = 1;
    for (var d = 1; d <= 7; d++) {
      if (avgs[(d - 1) % 7] > avgs[(busiest - 1) % 7]) busiest = d;
      if (avgs[(d - 1) % 7] < avgs[(lightest - 1) % 7]) lightest = d;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 74,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final d in const [1, 2, 3, 4, 5, 6, 7])
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _etaWeekday = d),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${avgs[(d - 1) % 7]}',
                            style: const TextStyle(
                                fontSize: 9, color: Colors.black54)),
                        const SizedBox(height: 2),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 40 * (avgs[(d - 1) % 7] / maxAvg) + 5,
                          decoration: BoxDecoration(
                            color: _etaWeekday == d
                                ? const Color(0xFF6A1B9A)
                                : levelColor(avgs[(d - 1) % 7] >= 35
                                    ? 3
                                    : avgs[(d - 1) % 7] >= 20
                                        ? 2
                                        : avgs[(d - 1) % 7] >= 12
                                            ? 1
                                            : 0),
                            borderRadius: BorderRadius.circular(4),
                            border: _etaWeekday == d
                                ? Border.all(
                                    color: const Color(0xFF4A148C), width: 1.5)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(_dayLabel(s, d),
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: _etaWeekday == d
                                    ? FontWeight.w800
                                    : FontWeight.w400)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 2,
          children: [
            Text('${s.t('busiest_day')}: ${_dayLabel(s, busiest)}',
                style: const TextStyle(
                    fontSize: 11.5, color: Color(0xFFC62828))),
            Text('${s.t('lightest_day')}: ${_dayLabel(s, lightest)}',
                style: const TextStyle(
                    fontSize: 11.5, color: Color(0xFF2E7D32))),
          ],
        ),
      ],
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

  Widget _roadRow(BuildContext context, S s, RoadEvent e) {
    final color = _roadColor(e.severity);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (e.route.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(e.route,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ),
                    Expanded(
                      child: Text(e.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13.5)),
                    ),
                  ],
                ),
                if (e.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(e.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(_roadLabel(s, e.severity),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          if (e.lat != 0 || e.lon != 0)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: s.t('directions'),
              icon: const Icon(Icons.directions, size: 18, color: Color(0xFF0E7490)),
              onPressed: () => LocationService.directions(
                lat: e.lat,
                lon: e.lon,
                label: e.route,
                origin: locationService.origin,
              ),
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
