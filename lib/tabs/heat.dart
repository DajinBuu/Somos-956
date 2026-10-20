import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../l10n.dart';
import '../local_data.dart';
import '../models.dart';
import '../notifications.dart';
import '../services.dart';
import 'common.dart';

class HeatTab extends StatefulWidget {
  const HeatTab({super.key});

  @override
  State<HeatTab> createState() => _HeatTabState();
}

class _HeatTabState extends State<HeatTab> {
  final _nws = NwsService();
  late Future<HeatReading> _heat;
  SiteType _filter = SiteType.coolingCenter;
  bool _mapMode = false;
  DateTime? _lastHeatNotif;
  DateTime? _nextReminder;
  bool _reminderPending = false;

  @override
  void initState() {
    super.initState();
    _heat = _nws.fetchHeat().then((h) {
      _maybeHeatAlert(h);
      return h;
    });
  }

  void _maybeHeatAlert(HeatReading h) {
    if (!mounted) return;
    final settings = LocaleScope.of(context);
    if (!settings.heatAlertsOn) return;
    final hi = h.hi;
    if (hi < 103) return;
    final now = DateTime.now();
    if (_lastHeatNotif != null &&
        now.difference(_lastHeatNotif!) < const Duration(hours: 2)) {
      return;
    }
    _lastHeatNotif = now;
    final es = settings.lang == 'es';
    Notifier.showNow(
      es ? '⚠️ Índice de calor crítico' : '⚠️ Critical heat index',
      es
          ? 'El índice de calor llega a ${hi.round()}°F. Evite el sol, hidrátese y revise a vecinos mayores.'
          : 'Heat index is ${hi.round()}°F. Avoid the sun, hydrate, and check on elderly neighbors.',
      id: 2,
    );
  }

  Future<void> _syncReminder() async {
    final settings = LocaleScope.of(context);
    if (settings.hydrationOn) {
      final when = await Notifier.scheduleHydration(
        settings.hydrationMinutes,
        'Time to hydrate 💧 / Tome agua 💧',
        'Drink 8 oz of water now. / Tome 8 onzas de agua ahora.',
      );
      if (mounted) setState(() => _nextReminder = when);
    } else {
      await Notifier.cancelHydration();
      if (mounted) setState(() => _nextReminder = null);
    }
  }

  List<Site> get _visible => kSites.where((s) => s.type == _filter).toList();

  void _showSiteSheet(Site site) {
    final s = S.of(context);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(site.name,
                style: Theme.of(ctx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _sheetRow(ctx, Icons.place_outlined, '${site.address}, ${site.city}'),
            _sheetRow(ctx, Icons.schedule_outlined, site.hours),
            _sheetRow(ctx, Icons.phone_outlined, '${s.t('call')} ${site.phone}'),
            _sheetRow(ctx, Icons.payments_outlined, s.t('free_entry')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.t('close')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetRow(BuildContext ctx, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(ctx).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = LocaleScope.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        FutureBuilder<HeatReading>(
          future: _heat,
          builder: (context, snap) {
            final h = snap.data;
            if (h == null) return const SizedBox.shrink();
            final level = heatLevelFor(h.hi);
            final c = heatColor(level);
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Card(
                color: c.withValues(alpha: 0.08),
                child: ListTile(
                  leading: Icon(Icons.wb_sunny, color: c, size: 36),
                  title: Text(
                    '${s.t('heat_index')}: ${h.hi.round()}°F · ${s.t('air_temp')}: ${h.tempF.round()}°F',
                    style: TextStyle(fontWeight: FontWeight.w700, color: c),
                  ),
                  subtitle: Text(
                    '${h.condition}${h.humidity != null ? ' · ${s.t('humidity')} ${h.humidity!.round()}%' : ''}',
                  ),
                  trailing: LiveBadge(live: h.live),
                ),
              ),
            );
          },
        ),
        SectionCard(
          icon: Icons.ac_unit_outlined,
          title: s.t('cooling_centers'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: s.t('list'),
                icon: Icon(Icons.list,
                    color: !_mapMode
                        ? Theme.of(context).colorScheme.primary
                        : null),
                onPressed: () => setState(() => _mapMode = false),
              ),
              IconButton(
                tooltip: s.t('map'),
                icon: Icon(Icons.map_outlined,
                    color:
                        _mapMode ? Theme.of(context).colorScheme.primary : null),
                onPressed: () => setState(() => _mapMode = true),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  _chip(s.t('cooling_centers'), SiteType.coolingCenter),
                  _chip(s.t('splash_pads'), SiteType.splashPad),
                  _chip(s.t('ac_buildings'), SiteType.acBuilding),
                ],
              ),
              const SizedBox(height: 10),
              if (_mapMode)
                MapPane(
                  markers: [
                    for (final site in _visible)
                      MapMarker(
                        point: LatLng(site.lat, site.lon),
                        color: switch (site.type) {
                          SiteType.coolingCenter =>
                            const Color(0xFF0E7490),
                          SiteType.splashPad => Colors.blue.shade600,
                          SiteType.acBuilding => const Color(0xFF6A1B9A),
                        },
                        icon: switch (site.type) {
                          SiteType.coolingCenter => Icons.ac_unit,
                          SiteType.splashPad => Icons.pool,
                          SiteType.acBuilding => Icons.apartment,
                        },
                        label: site.name,
                        onTap: () => _showSiteSheet(site),
                      ),
                  ],
                )
              else
                for (final site in _visible)
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: false,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          switch (site.type) {
                            SiteType.coolingCenter => Icons.ac_unit,
                            SiteType.splashPad => Icons.pool,
                            SiteType.acBuilding => Icons.apartment,
                          },
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(site.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${site.address}, ${site.city}\n${site.hours}'),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showSiteSheet(site),
                    ),
                  ),
            ],
          ),
        ),
        SectionCard(
          icon: Icons.water_drop_outlined,
          title: s.t('hydration_reminders'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.t('hydration_hint')),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.t('hydration_reminders'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                value: settings.hydrationOn,
                onChanged: (v) async {
                  settings.setHydrationOn(v);
                  await _syncReminder();
                  if (v && !_reminderPending) {
                    _reminderPending = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _reminderPending = false;
                      if (mounted) _syncReminder();
                    });
                  }
                },
              ),
              Row(
                children: [
                  Expanded(child: Text(s.t('remind_me_every'))),
                  for (final m in [30, 45, 60, 90])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ChoiceChip(
                        label: Text('$m ${s.t('minutes')}'),
                        selected: settings.hydrationMinutes == m,
                        onSelected: (_) async {
                          settings.setHydrationMinutes(m);
                          if (settings.hydrationOn) await _syncReminder();
                        },
                      ),
                    ),
                ],
              ),
              if (settings.hydrationOn && _nextReminder != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${s.t('next_reminder')}: ${fmtTime(_nextReminder!)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SectionCard(
          icon: Icons.construction_outlined,
          title: s.t('worker_tips'),
          child: Column(
            children: [
              for (var i = 0; i < kWorkerTips.length; i++)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    '${i + 1}. ${_tipTitle(s.lang == 'es' ? kWorkerTips[i].es : kWorkerTips[i].en)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(s.lang == 'es'
                            ? kWorkerTips[i].es
                            : kWorkerTips[i].en),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _tipTitle(String tip) {
    final idx = tip.indexOf(':');
    if (idx > 8 && idx < 60) return tip.substring(0, idx).trim();
    final q = tip.indexOf('?');
    if (q > 8 && q < 60) return tip.substring(0, q).trim();
    final period = tip.indexOf('.');
    if (period > 8 && period < 60) return tip.substring(0, period).trim();
    return tip.length > 55 ? '${tip.substring(0, 55).trim()}…' : tip;
  }

  Widget _chip(String label, SiteType type) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      selected: _filter == type,
      onSelected: (_) => setState(() => _filter = type),
    );
  }
}
