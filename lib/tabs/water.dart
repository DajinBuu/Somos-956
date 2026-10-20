import 'package:flutter/material.dart';

import '../l10n.dart';
import '../local_data.dart';
import '../models.dart';
import '../notifications.dart';
import '../services.dart';
import 'common.dart';

class WaterTab extends StatefulWidget {
  const WaterTab({super.key});

  @override
  State<WaterTab> createState() => _WaterTabState();
}

class _WaterTabState extends State<WaterTab> {
  final _service = ReservoirService();
  late Future<List<ReservoirReading>> _lakes;

  @override
  void initState() {
    super.initState();
    _lakes = _service.fetch();
  }

  WaterZone get _zone => kZones.firstWhere((z) => z.number == LocaleScope.of(context).zone);

  void _onZoneChanged(int number) {
    final settings = LocaleScope.of(context);
    final zone = kZones.firstWhere((z) => z.number == number);
    settings.setZone(number);
    if (settings.notifyStageChanges && zone.stage >= 2) {
      Notifier.showNow(
        'Watering stage update / Actualización de etapa de riego',
        settings.lang == 'es'
            ? 'Zona ${zone.number} — ${zone.nameEs}: ${_stageLabel('es', zone.stage)}. ${zone.daysEs}'
            : 'Zone ${zone.number} — ${zone.nameEn}: ${_stageLabel('en', zone.stage)}. ${zone.daysEn}',
        id: 3 + number,
      );
    }
  }

  String _stageLabel(String lang, int stage) {
    final key = switch (stage) {
      0 => 'stage_none',
      1 => 'stage1',
      2 => 'stage2',
      3 => 'stage3',
      _ => 'stage4',
    };
    return S(lang).t(key);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = LocaleScope.of(context);
    final zone = _zone;
    final es = s.lang == 'es';
    return RefreshIndicator(
      onRefresh: () async => setState(() => _lakes = _service.fetch()),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SectionCard(
            icon: Icons.map_outlined,
            title: s.t('your_zone'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: settings.zone,
                  decoration: InputDecoration(
                    labelText: s.t('your_zone'),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  items: [
                    for (final z in kZones)
                      DropdownMenuItem(
                        value: z.number,
                        child: Text(
                          '${s.t('zone')} ${z.number} — ${es ? z.nameEs : z.nameEn}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => _onZoneChanged(v ?? 1),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${s.t('restriction_stage')}:',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    StageBadge(stage: zone.stage),
                  ],
                ),
                const SizedBox(height: 10),
                _infoTile(context, Icons.calendar_month_outlined,
                    s.t('watering_days'), es ? zone.daysEs : zone.daysEn),
                _infoTile(context, Icons.schedule_outlined,
                    s.t('watering_hours'), es ? zone.hoursRuleEs : zone.hoursRuleEn),
                const SizedBox(height: 6),
                Text(s.t('watering_rules'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                for (final r in (es ? zone.rulesEs : zone.rulesEn))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Icon(Icons.check_circle, size: 14),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(r)),
                      ],
                    ),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    es
                        ? 'Notificarme cuando cambie la etapa de mi zona'
                        : 'Notify me when my zone’s stage changes',
                    style: const TextStyle(fontSize: 13.5),
                  ),
                  value: settings.notifyStageChanges,
                  onChanged: settings.setNotifyStageChanges,
                ),
              ],
            ),
          ),
          SectionCard(
            icon: Icons.water_outlined,
            title: s.t('reservoirs'),
            trailing: TextButton.icon(
              onPressed: () => setState(() => _lakes = _service.fetch()),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(s.t('refresh')),
            ),
            child: FutureBuilder<List<ReservoirReading>>(
              future: _lakes,
              builder: (context, snap) {
                final lakes = snap.data;
                if (lakes == null) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return Column(
                  children: [
                    for (final r in lakes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.water_damage,
                                    size: 18, color: Colors.blue.shade700),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(r.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                ),
                                LiveBadge(live: r.live),
                              ],
                            ),
                            const SizedBox(height: 8),
                            PercentBar(
                                percent: r.percentFull,
                                color: const Color(0xFF0E7490)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  '${r.percentFull.round()}%',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${s.t('full')} — ${s.t('conservation_pool')}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${s.t('elevation')}: ${r.elevationFt.toStringAsFixed(1)} ft '
                              '(pool ${r.conservationPoolFt})',
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
            icon: Icons.science_outlined,
            title: s.t('water_quality'),
            trailing: const LiveBadge(live: false),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.t('updated')}: ${kWaterQuality.published}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                _qRow(context, s.t('chlorine'),
                    '${kWaterQuality.chlorine} mg/L'),
                _qRow(context, s.t('ph'), kWaterQuality.ph.toString()),
                _qRow(
                    context, s.t('turbidity'), '${kWaterQuality.turbidity} NTU'),
                _qRow(
                  context,
                  s.t('coliform'),
                  kWaterQuality.coliformDetected
                      ? (es ? 'Detectados' : 'Detected')
                      : s.t('not_detected'),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    border: Border.all(
                        color: Colors.green.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '✅ ${s.t('no_burn_notice')}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.t('demo'),
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

  Widget _infoTile(BuildContext context, IconData icon, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(
                  text: '$k: ',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: v),
            ])),
          ),
        ],
      ),
    );
  }

  Widget _qRow(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(k)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
