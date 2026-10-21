import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../l10n.dart';
import '../local_data.dart';
import '../location.dart';
import '../models.dart';
import '../widgets/mascot.dart';
import 'common.dart';

class EducationTab extends StatefulWidget {
  const EducationTab({super.key});

  @override
  State<EducationTab> createState() => _EducationTabState();
}

class _EducationTabState extends State<EducationTab> {
  EduType? _filter;

  List<EduResource> get _visible => _filter == null
      ? kEduResources
      : kEduResources.where((r) => r.type == _filter).toList();

  List<EduResource> get _sorted {
    final list = [..._visible];
    if (locationService.hasFix) {
      list.sort((a, b) {
        final da = a.lat == 0 ? double.infinity : locationService.distanceTo(a.lat, a.lon);
        final db = b.lat == 0 ? double.infinity : locationService.distanceTo(b.lat, b.lon);
        return da.compareTo(db);
      });
    }
    return list;
  }

  Future<void> _enableLocation() async {
    await locationService.ensure();
    if (mounted) setState(() {});
  }

  _EduStyle _styleFor(EduType t) => switch (t) {
        EduType.tutoring => const _EduStyle('edu_k12', Icons.menu_book, Color(0xFFC2410C)),
        EduType.library => const _EduStyle('edu_library', Icons.local_library, Color(0xFF0E7490)),
        EduType.afterschool => const _EduStyle('edu_afterschool', Icons.sports_soccer, Color(0xFF2E7D32)),
        EduType.scholarship => const _EduStyle('edu_scholarship', Icons.savings, Color(0xFF6A1B9A)),
        EduType.college => const _EduStyle('edu_college', Icons.account_balance, Color(0xFF00695C)),
        EduType.esl => const _EduStyle('edu_esl', Icons.translate, Color(0xFF37474F)),
      };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final es = s.es;
    final settings = LocaleScope.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _introCard(s),
        SectionCard(
          icon: Icons.school_outlined,
          title: 'education_title',
          subtitle: 'education_intro',
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
                  for (final t in EduType.values)
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
                    if (r.lat != 0)
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
                    : const LatLng(26.20, -98.0),
                zoom: 8.9,
                height: 300,
              ),
              const SizedBox(height: 8),
              for (final r in _sorted)
                _eduCard(context, s, settings, r, es),
            ],
          ),
        ),
      ],
    );
  }

  Widget _eduCard(BuildContext context, S s, AppSettings settings, EduResource r,
      bool es) {
    final style = _styleFor(r.type);
    final saved = settings.savedResources.contains(r.id);
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: style.color.withValues(alpha: 0.15),
                  child: Icon(style.icon, color: style.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${r.provider}${r.city.isNotEmpty ? ' · ${r.city}' : ''}'
                          '${locationService.hasFix && r.lat != 0 ? ' · ${locationService.distanceTo(r.lat, r.lon).toStringAsFixed(1)} ${s.t('mi_away')}' : ''}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                if (r.lat != 0)
                  IconButton(
                    tooltip: s.t('directions'),
                    icon: const Icon(Icons.directions, color: Color(0xFF0E7490)),
                    onPressed: () => LocationService.directions(
                      lat: r.lat,
                      lon: r.lon,
                      label: r.name,
                      origin: locationService.position,
                    ),
                  ),
                IconButton(
                  icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border,
                      color: saved ? style.color : null),
                  tooltip: saved ? s.t('saved') : s.t('save'),
                  onPressed: () => settings.toggleSaved(r.id),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(s.t(style.labelKey),
                  style: TextStyle(
                      color: style.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            Text(es ? r.detailEs : r.detailEn),
            if (r.deadlineEn.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: InfoTile(
                    icon: Icons.event_available,
                    label: s.t('edu_deadline'),
                    value: es ? r.deadlineEs : r.deadlineEn),
              ),
            if (r.rewardEn.isNotEmpty)
              InfoTile(
                  icon: Icons.attach_money,
                  label: s.t('edu_amount'),
                  value: es ? r.rewardEs : r.rewardEn),
            if (r.phone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        size: 17,
                        color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r.phone)),
                    TextButton.icon(
                      onPressed: () => LocationService.call(r.phone),
                      icon: const Icon(Icons.call, size: 16),
                      label: Text(s.t('call'),
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _introCard(S s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00695C), Color(0xFF6A1B9A)],
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
                  child: Text(s.t('education_title'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(s.t('education_intro'),
                style: const TextStyle(color: Colors.white, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}

class _EduStyle {
  final String labelKey;
  final IconData icon;
  final Color color;
  const _EduStyle(this.labelKey, this.icon, this.color);
}
