import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../local_data.dart';
import '../models.dart';
import '../services.dart';
import 'common.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final _nws = NwsService();
  final _res = ReservoirService();

  late Future<(HeatReading, List<NwsAlert>)> _wx;
  late Future<List<ReservoirReading>> _lakes;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _load());
  }

  void _load() {
    _wx = Future.wait([_nws.fetchHeat(), _nws.fetchAlerts()])
        .then((r) => (r[0] as HeatReading, r[1] as List<NwsAlert>));
    _lakes = _res.fetch();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    _load();
    await _wx;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          FutureBuilder<(HeatReading, List<NwsAlert>)>(
            future: _wx,
            builder: (context, snap) {
              final heat = snap.data?.$1;
              final alerts = snap.data?.$2 ?? [];
              if (heat == null) {
                return const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final level = heatLevelFor(heat.hi);
              final c = heatColor(level);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                    child: Card(
                      color: c.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: c.withValues(alpha: 0.4)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.t('heat_index'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: c,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            heat.hi.round().toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .displayMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: c,
                                                  height: 1.05,
                                                ),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Text(
                                              '°F',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(color: c),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: c,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          switch (level) {
                                            HeatLevel.normal =>
                                              s.t('heat_normal'),
                                            HeatLevel.caution =>
                                              s.t('heat_caution'),
                                            HeatLevel.extreme =>
                                              s.t('heat_extreme'),
                                            HeatLevel.danger =>
                                              s.t('heat_danger'),
                                          },
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    LiveBadge(live: heat.live),
                                    const SizedBox(height: 8),
                                    _kv(context, s.t('air_temp'),
                                        '${heat.tempF.round()}°F'),
                                    if (heat.humidity != null)
                                      _kv(context, s.t('humidity'),
                                          '${heat.humidity!.round()}%'),
                                    _kv(context, s.t('conditions'), heat.condition),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: c.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                switch (level) {
                                  HeatLevel.normal => s.t('advice_normal'),
                                  HeatLevel.caution => s.t('advice_caution'),
                                  HeatLevel.extreme => s.t('advice_extreme'),
                                  HeatLevel.danger => s.t('advice_danger'),
                                },
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SectionCard(
                    icon: Icons.notifications_active_outlined,
                    title: s.t('active_alerts'),
                    trailing: LiveBadge(live: alerts.isEmpty || !alerts.first.demo),
                    child: alerts.isEmpty
                        ? Text(s.t('no_active_alerts'))
                        : Column(
                            children: [
                              for (final a in alerts)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.06),
                                      border: Border.all(
                                          color: Colors.red.withValues(alpha: 0.4)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(a.event,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        Text(a.headline),
                                        if (a.instruction.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            a.instruction,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(color: Colors.black54),
                                          ),
                                        ],
                                        if (a.ends != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              '${s.t('updated')}: ${fmtTime(a.ends!)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  SectionCard(
                    icon: Icons.water_outlined,
                    title: s.t('reservoirs'),
                    trailing: TextButton.icon(
                      onPressed: () => setState(() => _lakes = _res.fetch()),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(s.t('refresh')),
                    ),
                    child: FutureBuilder<List<ReservoirReading>>(
                      future: _lakes,
                      builder: (context, snap) {
                        final lakes = snap.data;
                        if (lakes == null) {
                          return const Center(
                              child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ));
                        }
                        return Column(
                          children: [
                            for (final r in lakes)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(r.name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                        LiveBadge(live: r.live),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: PercentBar(
                                            percent: r.percentFull,
                                            color: const Color(0xFF0E7490),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          '${r.percentFull.round()}% ${s.t('full')}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${s.t('elevation')}: ${r.elevationFt.toStringAsFixed(1)} ft — ${s.t('conservation_pool')}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  SectionCard(
                    icon: Icons.traffic_outlined,
                    title: s.t('bridge_delays'),
                    trailing: LiveBadge(live: false),
                    child: Column(
                      children: [
                        for (final b in kBridges.take(3))
                          _bridgeRow(context, s, b),
                        const SizedBox(height: 4),
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
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(k, style: Theme.of(context).textTheme.labelSmall),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _bridgeRow(BuildContext context, S s, BridgeStatus b) {
    final color = switch (b.state) {
      BridgeState.open => Colors.green.shade700,
      BridgeState.delayed => Colors.orange.shade800,
      BridgeState.heavy => Colors.red.shade700,
      BridgeState.closed => Colors.black,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(s.lang == 'es' ? b.nameEs : b.name,
                style: const TextStyle(fontSize: 13.5)),
          ),
          Text('${b.waitMinutes} ${s.t('min')}',
              style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 10),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
