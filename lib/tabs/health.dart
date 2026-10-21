import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../l10n.dart';
import '../local_data.dart';
import '../models.dart';
import '../notifications.dart';
import '../services.dart';
import '../widgets/mascot.dart';
import 'common.dart';

class HealthTab extends StatefulWidget {
  const HealthTab({super.key});

  @override
  State<HealthTab> createState() => _HealthTabState();
}

class _HealthTabState extends State<HealthTab> {
  final _decoder = TermDecoder();
  CareType? _filter;
  final List<CareFacility> _nearby = List.of(kCareFacilities);
  final List<FamilyMember> _members = [];
  final _termInput = TextEditingController();
  String? _termResult;
  bool _termSearched = false;

  @override
  void dispose() {
    _termInput.dispose();
    super.dispose();
  }

  List<CareFacility> get _visible =>
      _filter == null ? _nearby : _nearby.where((c) => c.type == _filter).toList();

  _CareStyle _styleFor(CareType t) {
    switch (t) {
      case CareType.hospital:
        return _CareStyle(
            'care_hospital', Icons.local_hospital, healthCareColor(0));
      case CareType.urgent:
        return _CareStyle('care_urgent', Icons.emergency, healthCareColor(1));
      case CareType.clinic:
        return _CareStyle('care_clinic', Icons.medical_services, healthCareColor(2));
      case CareType.pharmacy:
        return _CareStyle('care_pharmacy', Icons.local_pharmacy, healthCareColor(3));
    }
  }

  void _showFacility(CareFacility f) {
    final s = S.of(context);
    final style = _styleFor(f.type);
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
                Icon(style.icon, color: style.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(f.name,
                      style: Theme.of(ctx)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(s.t(style.labelKey),
                style: TextStyle(color: style.color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _row(ctx, Icons.place_outlined, '${f.address}, ${f.city}'),
            _row(ctx, Icons.schedule_outlined, f.open24h ? '24/7' : '—'),
            _row(ctx, Icons.phone_outlined, '${s.t('call')} ${f.phone}'),
            _row(ctx, Icons.translate, f.bilingual ? s.t('languages') : '—'),
            _row(ctx, Icons.payments_outlined,
                f.acceptsUninsured ? s.t('free_lowcost') : '—'),
            const SizedBox(height: 8),
            Text(s.pick(f.servicesEn, f.servicesEs)),
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

  Widget _row(BuildContext ctx, IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      );

  void _addMemberDialog() {
    final s = S.of(context);
    final name = TextEditingController();
    final age = TextEditingController();
    final notes = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.t('add_member')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: s.t('member_name')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: age,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: s.t('member_age')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notes,
              decoration: InputDecoration(labelText: s.t('member_notes')),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(s.t('close'))),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              setState(() {
                _members.add(FamilyMember(
                  name: name.text.trim(),
                  age: int.tryParse(age.text.trim()) ?? 0,
                  notes: notes.text.trim(),
                ));
              });
              Navigator.pop(ctx);
            },
            child: Text(s.t('save')),
          ),
        ],
      ),
    );
  }

  void _addVisitDialog(int index) {
    final s = S.of(context);
    final reason = TextEditingController();
    DateTime date = DateTime.now().add(const Duration(days: 7));
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(s.t('add_visit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reason,
                decoration: InputDecoration(labelText: s.t('visit_what')),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(fmtDate(date, s.es)),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setDlg(() => date = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text(s.t('close'))),
            FilledButton(
              onPressed: () async {
                if (reason.text.trim().isEmpty) return;
                final member = _members[index];
                final updated = FamilyMember(
                  name: member.name,
                  age: member.age,
                  notes: member.notes,
                  visits: [...member.visits, Visit(reason: reason.text.trim(), date: date)],
                );
                setState(() => _members[index] = updated);
                final settings = LocaleScope.of(context);
                if (settings.reminderOn) {
                  await Notifier.scheduleVisitReminder(
                    200 + index,
                    date,
                    s.es ? 'Cita médica próxima' : 'Upcoming medical visit',
                    s.es
                        ? '${member.name}: ${reason.text.trim()} el ${fmtDate(date, true)}'
                        : '${member.name}: ${reason.text.trim()} on ${fmtDate(date, false)}',
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(s.t('save')),
            ),
          ],
        ),
      ),
    );
  }

  void _decode() {
    final s = S.of(context);
    final q = _termInput.text;
    final hit = _decoder.lookup(q);
    setState(() {
      _termSearched = true;
      _termResult = hit == null ? null : s.pick(hit.plainEn, hit.plainEs);
    });
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
          icon: Icons.emergency_outlined,
          title: s.t('care_directory'),
          subtitle: s.t('emergency_note'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _chip(s.t('filter_all'), null),
                  for (final t in CareType.values)
                    _chip(s.t(_styleFor(t).labelKey), t),
                ],
              ),
              const SizedBox(height: 10),
              MapPane(
                markers: [
                  for (final f in _visible)
                    MapMarker(
                      point: LatLng(f.lat, f.lon),
                      color: _styleFor(f.type).color,
                      icon: _styleFor(f.type).icon,
                      label: f.name,
                      onTap: () => _showFacility(f),
                    ),
                ],
                center: const LatLng(26.15, -98.0),
                zoom: 9.0,
                height: 340,
              ),
              const SizedBox(height: 8),
              for (final f in _visible)
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: CircleAvatar(
                      backgroundColor: _styleFor(f.type)
                          .color
                          .withValues(alpha: 0.15),
                      child: Icon(_styleFor(f.type).icon,
                          color: _styleFor(f.type).color),
                    ),
                    title: Text(f.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${s.t(_styleFor(f.type).labelKey)} · ${f.city}'
                      '${f.open24h ? ' · 24/7' : ''}'
                      '${f.acceptsUninsured ? ' · ${s.t('free_lowcost')}' : ''}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showFacility(f),
                  ),
                ),
            ],
          ),
        ),
        SectionCard(
          icon: Icons.family_restroom,
          title: s.t('family_profiles'),
          subtitle: s.t('profiles_hint'),
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addMemberDialog,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(s.t('reminders_on'),
                    style: const TextStyle(fontSize: 13.5)),
                subtitle: Text(s.t('reminders_hint'),
                    style: const TextStyle(fontSize: 12)),
                value: settings.reminderOn,
                onChanged: settings.setReminder,
              ),
              if (_members.isEmpty)
                EmptyState(
                  message: s.t('no_members'),
                  mood: MascotMood.wave,
                  actionLabel: s.t('add_member'),
                  onAction: _addMemberDialog,
                )
              else
                for (var i = 0; i < _members.length; i++)
                  _memberTile(context, s, i),
            ],
          ),
        ),
        SectionCard(
          icon: Icons.translate,
          title: s.t('term_decoder'),
          subtitle: s.t('term_hint'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _termInput,
                      decoration: InputDecoration(
                        hintText: s.t('term_placeholder'),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onSubmitted: (_) => _decode(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _decode, child: Text(s.t('decode'))),
                ],
              ),
              if (_termSearched) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _termResult != null
                        ? Colors.green.withValues(alpha: 0.08)
                        : Colors.orange.withValues(alpha: 0.1),
                    border: Border.all(
                        color: (_termResult != null ? Colors.green : Colors.orange)
                            .withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_termResult ?? s.t('term_not_found')),
                ),
                if (_termResult != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(s.t('decode_ai_note'),
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      ],
                    ),
                  ),
              ],
              const Divider(height: 28),
              Text(s.t('form_helper'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(s.t('form_helper_hint'),
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              for (final f in kFormFields)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(s.pick(f.fieldEn, f.fieldEs),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10, left: 4),
                        child: Text(s.pick(f.explainEn, f.explainEs)),
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

  Widget _memberTile(BuildContext context, S s, int i) {
    final m = _members[i];
    final upcoming = [...m.visits]..sort((a, b) => a.date.compareTo(b.date));
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(m.name.characters.first.toUpperCase()),
        ),
        title: Text('${m.name}${m.age > 0 ? ' · ${m.age}' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(m.notes.isEmpty
            ? '${m.visits.length} ${s.t('upcoming_visits').toLowerCase()}'
            : m.notes),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (upcoming.isEmpty)
                  Text(s.t('no_visits'),
                      style: Theme.of(context).textTheme.bodySmall)
                else
                  for (final v in upcoming)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event, size: 18),
                      title: Text(v.reason, style: const TextStyle(fontSize: 14)),
                      trailing: Text(fmtDate(v.date, s.es),
                          style: const TextStyle(fontSize: 12)),
                    ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(s.t('add_visit')),
                    onPressed: () => _addVisitDialog(i),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, CareType? type) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      selected: _filter == type,
      onSelected: (_) => setState(() => _filter = type),
    );
  }

  Widget _introCard(S s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC2410C), Color(0xFF0E7490)],
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
                  child: Text(s.t('health_title'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(s.t('health_intro'),
                style: const TextStyle(color: Colors.white, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}

class _CareStyle {
  final String labelKey;
  final IconData icon;
  final Color color;
  const _CareStyle(this.labelKey, this.icon, this.color);
}
