import 'package:flutter/material.dart';

import '../l10n.dart';
import '../widgets/mascot.dart';
import 'common.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = LocaleScope.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _header(s),
        SectionCard(
          icon: Icons.translate,
          title: s.t('language'),
          child: RadioGroup<String>(
            groupValue: settings.lang,
            onChanged: (v) => settings.setLang(v ?? 'en'),
            child: Column(
              children: [
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: 'en',
                  title: const Text('English'),
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: 'es',
                  title: const Text('Español'),
                ),
              ],
            ),
          ),
        ),
        SectionCard(
          icon: Icons.notifications_active_outlined,
          title: s.t('reminders'),
          subtitle: s.t('reminders_hint'),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.t('reminders_enable')),
            subtitle: Text(s.t('reminders_sub')),
            value: settings.reminderOn,
            onChanged: (v) => settings.setReminder(v),
          ),
        ),
        SectionCard(
          icon: Icons.bookmarks_outlined,
          title: s.t('saved_resources'),
          child: settings.savedResources.isEmpty
              ? Text(s.t('saved_empty'),
                  style: Theme.of(context).textTheme.bodySmall)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${settings.savedResources.length} ${s.t('saved_count')}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final id in settings.savedResources)
                          Chip(
                            label: Text(id, style: const TextStyle(fontSize: 11)),
                            onDeleted: () => settings.toggleSaved(id),
                          ),
                      ],
                    ),
                  ],
                ),
        ),
        SectionCard(
          icon: Icons.info_outline,
          title: s.t('about'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.t('about_body')),
              const SizedBox(height: 12),
              InfoTile(
                  icon: Icons.tag,
                  label: s.t('version'),
                  value: 'Somos 956 · 1.0.0'),
              InfoTile(
                  icon: Icons.location_city,
                  label: s.t('region'),
                  value: 'Rio Grande Valley · 956'),
              InfoTile(
                  icon: Icons.gavel,
                  label: s.t('disclaimer_label'),
                  value: s.t('disclaimer')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(S s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: MascotBubble(
        message: s.t('about_body'),
        mood: MascotMood.wave,
        mascotSize: 76,
      ),
    );
  }
}
