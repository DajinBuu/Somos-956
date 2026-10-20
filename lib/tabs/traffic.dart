import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../l10n.dart';
import '../local_data.dart';
import '../models.dart';
import 'common.dart';

class TrafficTab extends StatefulWidget {
  const TrafficTab({super.key});

  @override
  State<TrafficTab> createState() => _TrafficTabState();
}

class _TrafficTabState extends State<TrafficTab> {
  final _rng = Random();
  late List<BridgeStatus> _bridges;
  DateTime _fetched = DateTime.now();

  @override
  void initState() {
    super.initState();
    _bridges = _simulate();
  }

  List<BridgeStatus> _simulate() {
    final now = DateTime.now();
    return [
      for (final b in kBridges)
        () {
          final w = (b.waitMinutes + _rng.nextInt(9) - 4).clamp(2, 75);
          return BridgeStatus(
            name: b.name,
            nameEs: b.nameEs,
            waitMinutes: w,
            state: w >= 40
                ? BridgeState.heavy
                : w >= 20
                    ? BridgeState.delayed
                    : BridgeState.open,
            updated: now,
            demo: true,
          );
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final es = s.lang == 'es';
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _bridges = _simulate();
          _fetched = DateTime.now();
        });
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SectionCard(
            icon: Icons.traffic_outlined,
            title: s.t('bridge_delays'),
            trailing: TextButton.icon(
              onPressed: () => setState(() {
                _bridges = _simulate();
                _fetched = DateTime.now();
              }),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(s.t('refresh')),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.t('updated')}: ${fmtTime(_fetched)} · ${s.t('demo')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                for (final b in _bridges) _bridgeCard(context, s, b, es),
                Text(
                  s.t('demo_note'),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.black45),
                ),
              ],
            ),
          ),
          SectionCard(
            icon: Icons.warning_amber_outlined,
            title: s.t('road_hazards'),
            trailing: const LiveBadge(live: false),
            child: Column(
              children: [
                for (final h in kHazards)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: severityColor(h.severity)
                            .withValues(alpha: 0.07),
                        border: Border.all(
                          color: severityColor(h.severity)
                              .withValues(alpha: 0.45),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                switch (h.type) {
                                  HazardType.flood => Icons.flood,
                                  HazardType.construction => Icons.construction,
                                  HazardType.accident =>
                                    Icons.car_crash_outlined,
                                  HazardType.debris => Icons.delete_outline,
                                },
                                size: 18,
                                color: severityColor(h.severity),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  es ? h.titleEs : h.titleEn,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(h.road,
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: severityColor(h.severity),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  severityLabel(context, h.severity),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                s.t('hazard_${h.type.name}'),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SectionCard(
            icon: Icons.map_outlined,
            title: s.t('flood_prone'),
            trailing: const LiveBadge(live: false),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MapPane(
                  zoom: 11.4,
                  markers: [
                    for (final h in kHazards)
                      if (h.type == HazardType.flood)
                        MapMarker(
                          point: LatLng(h.lat, h.lon),
                          color: severityColor(h.severity),
                          icon: Icons.flood,
                          label: h.titleEn,
                        ),
                    for (final site in kSites)
                      if (site.name.contains('Community') ||
                          site.name.contains('Library'))
                        MapMarker(
                          point: LatLng(site.lat, site.lon),
                          color: const Color(0xFF0E7490),
                          icon: Icons.ac_unit,
                          label: site.name,
                        ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.lang == 'es'
                      ? 'Los marcadores rojos/ámbar son puntos donde el agua tiende a cruzar la calzada tras lluvias repentinas del Valle. Los marcadores turquesa son centros con aire acondicionado.'
                      : 'Red/amber markers are spots where water tends to cover the road after sudden RGV downpours. Turquoise markers are air-conditioned centers.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.black54),
                ),
                Text(
                  s.t('demo_note'),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.black45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bridgeCard(BuildContext context, S s, BridgeStatus b, bool es) {
    final color = switch (b.state) {
      BridgeState.open => Colors.green.shade700,
      BridgeState.delayed => Colors.orange.shade800,
      BridgeState.heavy => Colors.red.shade700,
      BridgeState.closed => Colors.black,
    };
    final stateLabel = switch (b.state) {
      BridgeState.open => s.t('bridge_open'),
      BridgeState.delayed => s.t('bridge_delayed'),
      BridgeState.heavy => s.t('bridge_heavy'),
      BridgeState.closed => s.t('bridge_closed'),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
              child: const Icon(Icons.directions_car, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(es ? b.nameEs : b.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(stateLabel,
                      style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${b.waitMinutes}',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: color),
                ),
                Text(s.t('wait').toLowerCase(),
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
