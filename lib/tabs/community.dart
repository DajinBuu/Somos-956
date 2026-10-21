import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../l10n.dart';
import '../local_data.dart';
import '../location.dart';
import '../models.dart';
import '../widgets/mascot.dart';
import 'common.dart';

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  ResourceType? _filter;
  final _reportType = TextEditingController();
  final _reportDetails = TextEditingController();
  final _reportLocation = TextEditingController();
  String _reportTypeKey = 'report_dumping';

  int _household = 3;
  int _income = 2200;
  bool _children = true;
  bool _elderly = false;
  bool _uninsured = true;
  bool _showMatches = false;

  @override
  void dispose() {
    _reportType.dispose();
    _reportDetails.dispose();
    _reportLocation.dispose();
    super.dispose();
  }

  List<CommunityResource> get _visible => _filter == null
      ? kCommunityResources
      : kCommunityResources.where((r) => r.type == _filter).toList();

  List<CommunityResource> get _sorted {
    final list = [..._visible];
    if (locationService.hasFix) {
      list.sort((a, b) => locationService
          .distanceTo(a.lat, a.lon)
          .compareTo(locationService.distanceTo(b.lat, b.lon)));
    }
    return list;
  }

  Future<void> _enableLocation() async {
    await locationService.ensure();
    if (mounted) setState(() {});
  }

  _ResStyle _styleFor(ResourceType t) => switch (t) {
        ResourceType.food => const _ResStyle('res_food', Icons.restaurant, Color(0xFF2E7D32)),
        ResourceType.shelter => const _ResStyle('res_shelter', Icons.home, Color(0xFF0E7490)),
        ResourceType.clinic => const _ResStyle('res_clinic', Icons.medical_services, Color(0xFFC2410C)),
        ResourceType.hotline => const _ResStyle('res_hotline', Icons.support_agent, Color(0xFF6A1B9A)),
        ResourceType.legal => const _ResStyle('res_legal', Icons.gavel, Color(0xFF37474F)),
      };

  List<(EligibilityProgram, bool)> _matches() {
    final scale = 1 + (_household - 1) * 0.4;
    final out = <(EligibilityProgram, bool)>[];
    for (final p in kEligibilityPrograms) {
      final threshold = p.incomeThresholdMonthly * scale;
      final under = _income <= threshold;
      var relevant = true;
      if (p.childRelated && !_children && !p.elderlyRelated && !p.uninsuredRelated) {
        relevant = false;
      }
      if (p.elderlyRelated && !_elderly && !p.childRelated && !p.uninsuredRelated) {
        relevant = false;
      }
      if (p.uninsuredRelated && !_uninsured && !p.childRelated && !p.elderlyRelated) {
        relevant = false;
      }
      if (!relevant) continue;
      final likely = under && _income <= threshold * 0.85;
      out.add((p, likely || under));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = LocaleScope.of(context);
    final es = s.es;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _introCard(s),
        SectionCard(
          icon: Icons.list_alt,
          title: 'resources',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilterChip(
                    label: Text(s.t('filter_all'),
                        style: const TextStyle(fontSize: 12.5)),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                  for (final t in ResourceType.values)
                    FilterChip(
                      label: Text(s.t(_styleFor(t).labelKey),
                          style: const TextStyle(fontSize: 12.5)),
                      selected: _filter == t,
                      onSelected: (_) => setState(() => _filter = t),
                    ),
                  if (!locationService.hasFix)
                    ActionChip(
                      avatar: const Icon(Icons.my_location, size: 16),
                      label: Text(s.t('location_prompt'),
                          style: const TextStyle(fontSize: 12)),
                      onPressed: _enableLocation,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              MapPane(
                markers: [
                  for (final r in _sorted)
                    MapMarker(
                      point: LatLng(r.lat, r.lon),
                      color: _styleFor(r.type).color,
                      icon: _styleFor(r.type).icon,
                      label: r.name,
                    ),
                ],
                center: locationService.hasFix
                    ? LatLng(locationService.reference.$1,
                        locationService.reference.$2)
                    : const LatLng(26.18, -98.0),
                zoom: 8.9,
                height: 300,
              ),
              const SizedBox(height: 8),
              for (final r in _sorted)
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: CircleAvatar(
                      backgroundColor:
                          _styleFor(r.type).color.withValues(alpha: 0.15),
                      child: Icon(_styleFor(r.type).icon,
                          color: _styleFor(r.type).color),
                    ),
                    title: Text(r.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${s.t(_styleFor(r.type).labelKey)} · ${r.city}'
                        '${locationService.hasFix ? ' · ${locationService.distanceTo(r.lat, r.lon).toStringAsFixed(1)} ${s.t('mi_away')}' : ''}'
                        '\n${s.pick(r.hoursEn, r.hoursEs)}'),
                    isThreeLine: true,
                    trailing: (!r.phone.startsWith('(') && r.phone != 'Various' && r.phone != '(contact city)')
                        ? IconButton(
                            tooltip: s.t('directions'),
                            icon: const Icon(Icons.directions,
                                color: Color(0xFF0E7490)),
                            onPressed: () => LocationService.directions(
                              lat: r.lat,
                              lon: r.lon,
                              label: r.name,
                              origin: locationService.position,
                            ),
                          )
                        : null,
                    onTap: () => showModalBottomSheet<void>(
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
                            Text(r.name,
                                style: Theme.of(ctx)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            InfoTile(
                                icon: Icons.place_outlined,
                                label: s.t('address'),
                                value: '${r.address}, ${r.city}'),
                            InfoTile(
                                icon: Icons.schedule_outlined,
                                label: s.t('hours'),
                                value: s.pick(r.hoursEn, r.hoursEs)),
                            InfoTile(
                                icon: Icons.phone_outlined,
                                label: s.t('call'),
                                value: r.phone),
                            const SizedBox(height: 8),
                            Text(s.pick(r.detailEn, r.detailEs)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    icon: const Icon(Icons.directions, size: 18),
                                    label: Text(s.t('directions')),
                                    onPressed: () => LocationService.directions(
                                      lat: r.lat,
                                      lon: r.lon,
                                      label: r.name,
                                      origin: locationService.position,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.call, size: 18),
                                    label: Text(s.t('call')),
                                    onPressed: () => LocationService.call(r.phone),
                                  ),
                                ),
                              ],
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
                    ),
                  ),
                ),
            ],
          ),
        ),
        SectionCard(
          icon: Icons.rule,
          title: 'eligibility',
          subtitle: 'eligibility_hint',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stepperRow(s.t('household_size'), _household, 1, 10,
                  (v) => setState(() => _household = v)),
              const SizedBox(height: 6),
              Text('${s.t('monthly_income')}: \$$_income',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Slider(
                value: _income.toDouble(),
                min: 0,
                max: 6000,
                divisions: 60,
                label: '\$$_income',
                onChanged: (v) => setState(() => _income = v.round()),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(s.t('has_children')),
                value: _children,
                onChanged: (v) => setState(() => _children = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(s.t('has_elderly')),
                value: _elderly,
                onChanged: (v) => setState(() => _elderly = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(s.t('uninsured')),
                value: _uninsured,
                onChanged: (v) => setState(() => _uninsured = v),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.checklist),
                  label: Text(s.t('see_matches')),
                  onPressed: () => setState(() => _showMatches = true),
                ),
              ),
              if (_showMatches) ...[
                const SizedBox(height: 12),
                for (final (p, likely) in _matches())
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (likely ? Colors.green : Colors.orange)
                          .withValues(alpha: 0.07),
                      border: Border.all(
                          color: (likely ? Colors.green : Colors.orange)
                              .withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(es ? p.nameEs : p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: likely ? Colors.green : Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                likely
                                    ? s.t('likely_eligible')
                                    : s.t('maybe_eligible'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(es ? p.descriptionEs : p.descriptionEn,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                Text(s.t('demo'),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.black45)),
              ],
            ],
          ),
        ),
        SectionCard(
          icon: Icons.campaign_outlined,
          title: 'report',
          subtitle: 'report_hint',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _reportTypeKey,
                isExpanded: true,
                decoration: InputDecoration(labelText: s.t('report_type')),
                items: [
                  for (final k in const [
                    'report_dumping',
                    'report_roads',
                    'report_lighting',
                    'report_water',
                    'report_unsafe',
                  ])
                    DropdownMenuItem(value: k, child: Text(s.t(k))),
                ],
                onChanged: (v) => setState(() => _reportTypeKey = v ?? _reportTypeKey),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _reportDetails,
                maxLines: 3,
                decoration: InputDecoration(labelText: s.t('report_details')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _reportLocation,
                decoration: InputDecoration(labelText: s.t('report_location')),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.lock_outline),
                  label: Text(s.t('submit_report')),
                  onPressed: () {
                    if (_reportDetails.text.trim().isEmpty) return;
                    settings.addReport(
                      s.t(_reportTypeKey),
                      '${_reportDetails.text.trim()}'
                      '${_reportLocation.text.trim().isEmpty ? '' : ' @ ${_reportLocation.text.trim()}'}',
                    );
                    _reportDetails.clear();
                    _reportLocation.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.t('report_thanks'))),
                    );
                  },
                ),
              ),
              const Divider(height: 28),
              Text(s.t('my_reports'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              if (settings.reports.isEmpty)
                EmptyState(message: s.t('no_reports'), mood: MascotMood.thinking)
              else
                for (final r in settings.reports.reversed.take(10))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.report_gmailerrorred, size: 18),
                    title: Text(r['type'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(r['text'] ?? ''),
                  ),
            ],
          ),
        ),
        SectionCard(
          icon: Icons.flag_outlined,
          title: 'cultural_tips',
          subtitle: 'cultural_hint',
          child: Column(
            children: [
              for (final t in kCulturalTips)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(s.pick(t.titleEn, t.titleEs),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
                        child: Text(s.pick(t.bodyEn, t.bodyEs)),
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

  Widget _stepperRow(String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max ? () => onChanged(value + 1) : null,
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
            colors: [Color(0xFF2E7D32), Color(0xFF0E7490)],
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
                  child: Text(s.t('community_title'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(s.t('community_intro'),
                style: const TextStyle(color: Colors.white, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}

class _ResStyle {
  final String labelKey;
  final IconData icon;
  final Color color;
  const _ResStyle(this.labelKey, this.icon, this.color);
}
