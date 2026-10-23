import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../l10n.dart';
import '../local_data.dart';
import '../location.dart';
import '../models.dart';
import '../services.dart';
import '../widgets/mascot.dart';
import 'common.dart';

class MosquitoTab extends StatefulWidget {
  const MosquitoTab({super.key});

  @override
  State<MosquitoTab> createState() => _MosquitoTabState();
}

class _MosquitoTabState extends State<MosquitoTab> {
  final _service = MosquitoService();
  List<MosquitoRisk> _risks = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final risks = await _service.risks();
    risks.sort((a, b) => b.score.compareTo(a.score));
    if (!mounted) return;
    setState(() {
      _risks = risks;
      _loading = false;
    });
  }

  Color _color(MosquitoLevel l) => levelColor(l.index);

  String _levelKey(MosquitoLevel l) {
    switch (l) {
      case MosquitoLevel.low:
        return 'mosquito_level_low';
      case MosquitoLevel.moderate:
        return 'mosquito_level_moderate';
      case MosquitoLevel.high:
        return 'mosquito_level_high';
      case MosquitoLevel.severe:
        return 'mosquito_level_severe';
    }
  }

  void _showZone(S s, MosquitoRisk r) {
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
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: _color(r.level), shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(s.pick(r.zone.name, r.zone.nameEs),
                      style: Theme.of(ctx)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                LiveBadge(live: r.live),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${s.t(_levelKey(r.level))} · ${r.score}/100',
              style: TextStyle(
                  color: _color(r.level), fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('${s.t('mosquito_zone')}: ${r.zone.county} County',
                style: Theme.of(ctx).textTheme.bodySmall),
            const Divider(height: 24),
            Text(s.t('mosquito_drivers'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _driverRow(ctx, Icons.thermostat, s.t('mosquito_temp'),
                '${r.tempF.round()}°F'),
            _driverRow(ctx, Icons.water_drop, s.t('mosquito_humidity'),
                '${r.humidity}%'),
            _driverRow(
                ctx,
                Icons.grain,
                s.t('mosquito_rain'),
                r.rain7dIn <= 0
                    ? s.t('mosquito_no_rain')
                    : '${r.rain7dIn.toStringAsFixed(2)} in'),
            const SizedBox(height: 10),
            Text(s.t('mosquito_rain_note'),
                style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openReportSheet(seedZone: r.zone);
                },
                child: Text(s.t('mosquito_report_hotspot')),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.t('close')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _driverRow(
          BuildContext ctx, IconData icon, String label, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(value),
          ],
        ),
      );

  Future<void> _openReportSheet({MosquitoZone? seedZone}) async {
    final s = S.of(context);
    final settings = LocaleScope.of(context);

    if (locationService.hasFix) {
      _reportAt(s, settings, locationService.reference);
      return;
    }
    if (seedZone != null) {
      _reportAt(s, settings, (seedZone.lat, seedZone.lon));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.t('mosquito_need_location'))),
    );
    await showLocationPicker(context);
    if (!mounted) return;
    if (locationService.hasFix) {
      _reportAt(s, settings, locationService.reference);
    }
  }

  void _reportAt(S s, AppSettings settings, (double, double) point) {
    final note = TextEditingController();
    MosquitoLevel sev = MosquitoLevel.moderate;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.pest_control, color: Color(0xFFC2410C)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.t('mosquito_report_hotspot'),
                        style: Theme.of(ctx)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${point.$1.toStringAsFixed(3)}, ${point.$2.toStringAsFixed(3)}',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(s.t('mosquito_report_severity'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final lvl in [
                    MosquitoLevel.low,
                    MosquitoLevel.moderate,
                    MosquitoLevel.high,
                  ])
                    ChoiceChip(
                      label: Text(_severityLabel(s, lvl)),
                      selected: sev == lvl,
                      selectedColor: _color(lvl).withValues(alpha: 0.2),
                      onSelected: (_) => setSheet(() => sev = lvl),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: s.t('mosquito_report_note'),
                  hintText: s.es
                      ? 'Ej. muchos mosquitos en el parque'
                      : 'e.g. lots of mosquitoes at the park',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(s.t('cancel')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(s.t('save')),
                      onPressed: () {
                        settings.addMosquitoReport(MosquitoReport(
                          id: 'mr-${DateTime.now().microsecondsSinceEpoch}',
                          note: note.text.trim(),
                          severity: sev,
                          lat: point.$1,
                          lon: point.$2,
                          when: DateTime.now(),
                        ));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.t('mosquito_saved'))),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _severityLabel(S s, MosquitoLevel l) {
    switch (l) {
      case MosquitoLevel.low:
        return s.t('mosquito_sev_annoying');
      case MosquitoLevel.moderate:
        return s.t('mosquito_sev_swarm');
      default:
        return s.t('mosquito_sev_severe');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = LocaleScope.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _introCard(s),
        SectionCard(
          icon: Icons.map_outlined,
          title: 'mosquito_risk_map',
          subtitle: 'mosquito_risk_map_hint',
          trailing: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  tooltip: s.t('refresh'),
                  icon: const Icon(Icons.refresh),
                  onPressed: _load,
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (final l in MosquitoLevel.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: _color(l), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text(s.t(_levelKey(l)),
                              style: const TextStyle(fontSize: 11.5)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              MapPane(
                markers: [
                  for (final r in _risks)
                    MapMarker(
                      point: LatLng(r.zone.lat, r.zone.lon),
                      color: _color(r.level),
                      icon: Icons.pest_control,
                      label:
                          '${s.pick(r.zone.name, r.zone.nameEs)} · ${r.score}',
                      onTap: () => _showZone(s, r),
                    ),
                  for (final rep in settings.mosquitoReports)
                    MapMarker(
                      point: LatLng(rep.lat, rep.lon),
                      color: Colors.blue.shade700,
                      icon: Icons.person_pin_circle,
                      label: s.t('mosquito_you'),
                      onTap: () {},
                    ),
                ],
                center: locationService.hasFix
                    ? LatLng(locationService.reference.$1,
                        locationService.reference.$2)
                    : const LatLng(kValleyCenterLat, kValleyCenterLon),
                zoom: 9.0,
                height: 340,
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                for (final r in _risks)
                  Card(
                    elevation: 0,
                    color:
                        Theme.of(context).colorScheme.surfaceContainerLow,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      leading: CircleAvatar(
                        backgroundColor:
                            _color(r.level).withValues(alpha: 0.15),
                        child:
                            Icon(Icons.pest_control, color: _color(r.level)),
                      ),
                      title: Text(s.pick(r.zone.name, r.zone.nameEs),
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${s.t(_levelKey(r.level))} · ${r.zone.county}'
                        '${locationService.hasFix ? ' · ${locationService.distanceTo(r.zone.lat, r.zone.lon).toStringAsFixed(1)} ${s.t('mi_away')}' : ''}',
                      ),
                      trailing: Text('${r.score}',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: _color(r.level))),
                      onTap: () => _showZone(s, r),
                    ),
                  ),
              const SizedBox(height: 4),
              Text(
                '${s.t('mosquito_disclaimer')} ${s.t('updated')}: ${fmtTime(_risks.isNotEmpty ? _risks.first.updated : DateTime.now())}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        SectionCard(
          icon: Icons.add_location_alt_outlined,
          title: 'mosquito_report_hotspot',
          subtitle: 'mosquito_report_hint',
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _openReportSheet(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilledButton.icon(
                onPressed: () => _openReportSheet(),
                icon: const Icon(Icons.pest_control, size: 18),
                label: Text(s.t('mosquito_report_now')),
              ),
              const Divider(height: 26),
              Text(s.t('mosquito_my_reports'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              if (settings.mosquitoReports.isEmpty)
                EmptyState(
                  message: s.t('mosquito_no_reports'),
                  mood: MascotMood.thinking,
                )
              else
                for (final r in settings.mosquitoReports)
                  Card(
                    elevation: 0,
                    color:
                        Theme.of(context).colorScheme.surfaceContainerLow,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.person_pin_circle,
                          color: Colors.blue),
                      title: Text(
                        r.note.isEmpty
                            ? _severityLabel(s, r.severity)
                            : r.note,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${_severityLabel(s, r.severity)} · ${s.t('mosquito_reported_ago')} ${fmtDate(r.when, s.es)}',
                      ),
                      trailing: IconButton(
                        tooltip: s.t('delete'),
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            settings.removeMosquitoReport(r.id),
                      ),
                      onTap: () => LocationService.mapTo(r.lat, r.lon),
                    ),
                  ),
            ],
          ),
        ),
        SectionCard(
          icon: Icons.tips_and_updates_outlined,
          title: 'mosquito_tips',
          subtitle: 'mosquito_tips_hint',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final t in kMosquitoTips)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_outline,
                      color: Color(0xFF2E7D32)),
                  title: Text(s.pick(t.titleEn, t.titleEs),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(s.pick(t.bodyEn, t.bodyEs),
                      style: const TextStyle(fontSize: 12.5)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _introCard(S s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF15803D), Color(0xFFC2410C)],
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
                  child: Text(s.t('mosquito_title'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(s.t('mosquito_intro'),
                style: const TextStyle(color: Colors.white, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}
